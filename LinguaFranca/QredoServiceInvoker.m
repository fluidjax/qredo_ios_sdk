#import "QredoWireFormat.h"
#import "QredoServiceInvoker.h"
#import "NSData+QredoRandomData.h"
#import <CommonCrypto/CommonCrypto.h>
#import "QredoTransport.h"
#import "QredoLogger.h"
#import "QredoCertificate.h"
#import "NSData+ParseHex.h"
#import "QredoHelpers.h"

NSString *const QredoLFErrorDomain = @"QredoLFError";


@interface QredoServiceInvokerCallbacks : NSObject
@property NSData *correlationID;
@property (copy) NSString *serviceName;
@property (copy) NSString *operationName;
@property (copy) void (^responseReader)(QredoWireFormatReader *);
@property (copy) void(^errorHandler)(NSError *);
@property BOOL multiResponse;
@end

@implementation QredoServiceInvokerCallbacks

@end

@interface QredoServiceInvoker ()<QredoTransportDelegate>
{
    // Note: Do not access callbacks dictionary directly, but via concurrent helper functions provided
    NSMutableDictionary *callbacks;
}

@property BOOL terminated;
@property dispatch_queue_t callbacksDictionaryQueue;
@property QredoAppCredentials *appCredentials;

@end

@implementation QredoServiceInvoker


+ (instancetype)serviceInvokerWithServiceURL:(NSURL *)serviceURL
                           pinnedCertificate:(QredoCertificate *)certificate
                              appCredentials:(QredoAppCredentials *)appCredentials{
    return [[self alloc] initWithServiceURL:serviceURL pinnedCertificate:certificate appCredentials:appCredentials];
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL pinnedCertificate:(QredoCertificate *)certificate appCredentials:(QredoAppCredentials *)appCredentials{
    
    self = [super init];
    
    if (self != nil)
    {
        _terminated = NO;

        callbacks = [NSMutableDictionary dictionary];
        
        // Concurrent queue - will have synch reads, and async writes (with a barrier to block any concurrent reads)
        _callbacksDictionaryQueue = dispatch_queue_create("com.qredo.serviceInvoker.callbacks", DISPATCH_QUEUE_CONCURRENT);

        _transport = [QredoTransport transportForServiceURL:serviceURL pinnedCertificate:certificate];
        _appCredentials = appCredentials;
        
        
        // TODO: DH - if we ever start returning the same transport instance for a specific URL and there are simultaneous QredoServicInvoker instances talking to the same service URL, there may be problems where we overwrite another instance's delegate.
        _transport.responseDelegate = self;
    }
    
    return self;
}

-(void)dealloc
{
    // Ensure the we, and the transport close cleanly if terminate wasn't called
    [self terminate];
}

- (void)terminate
{
    if (!_terminated) {
        _terminated = YES;
        
        // Closes down the transport threads. Requires re-initialisation.  Transport will trigger error handlers if attempted to be used after termination
        [self.transport close];
    }
}

- (void)invokeService:(NSString *)serviceName
            operation:(NSString *)operationName
        requestWriter:(void (^)(QredoWireFormatWriter *writer))requestWriter
       responseReader:(void (^)(QredoWireFormatReader *reader))responseReader
         errorHandler:(void (^)(NSError *error))errorHandler
{
    [self invokeService:serviceName operation:operationName requestWriter:requestWriter responseReader:responseReader errorHandler:errorHandler multiResponse:NO];
}

- (void)invokeService:(NSString *)serviceName
            operation:(NSString *)operationName
        requestWriter:(void (^)(QredoWireFormatWriter *writer))requestWriter
       responseReader:(void (^)(QredoWireFormatReader *reader))responseReader
         errorHandler:(void (^)(NSError *error))errorHandler
        multiResponse:(BOOL)multiResponse
{
    if (multiResponse) {
        if (![self.transport supportsMultiResponse]) {
            NSString *reason = [NSString stringWithFormat:@"Transport does not support multi-response, yet multi-response was requested. Service URL: %@",
                                self.transport.serviceURL];
            QredoLogError(@"%@", reason);
            
            if (errorHandler) {
                errorHandler([NSError errorWithDomain:QredoTransportErrorDomain
                                                 code:QredoTransportErrorMultiResponseNotSupported
                                             userInfo:@{NSLocalizedDescriptionKey: reason}]);
            } else {
                QredoLogError(@"Could not notify caller that error occurred invoking operation '%@' on service '%@', no errorHandler configured.", operationName, serviceName);
            }
        }
    }

    NSOutputStream *outputStream = [NSOutputStream outputStreamToMemory];
    [outputStream open];

    NSData *body;
    NSData *correlationID;
    @try {

        QredoWireFormatWriter *wireFormatWriter = [QredoWireFormatWriter wireFormatWriterWithOutputStream:outputStream];

        QredoVersion *protocolVersion = [QredoVersion versionWithMajor:QREDO_MAJOR_PROTOCOL_VERSION
                                                                 minor:QREDO_MINOR_PROTOCOL_VERSION
                                                                 patch:QREDO_PATCH_PROTOCOL_VERSION];
        
        QredoVersion *releaseVersion  = [QredoVersion versionWithMajor:QREDO_MAJOR_RELEASE_VERSION
                                                                 minor:QREDO_MINOR_RELEASE_VERSION
                                                                 patch:QREDO_PATCH_RELEASE_VERSION];
        QredoMessageHeader *messageHeader =
                [QredoMessageHeader messageHeaderWithProtocolVersion:protocolVersion
                                                      releaseVersion:releaseVersion];
        [wireFormatWriter writeMessageHeader:messageHeader];
            NSData *returnChannelID = [self.transport.clientId getData];
            // TODO: DH - replace magic number for correlation ID size
            correlationID   = [QredoServiceInvoker secureRandomWithSize:16];
            QredoInterchangeHeader *interchangeHeader =
                    [QredoInterchangeHeader interchangeHeaderWithReturnChannelID:returnChannelID
                                                                   correlationID:correlationID
                                                                     serviceName:serviceName
                                                                   operationName:operationName];
            [wireFormatWriter writeInterchangeHeader:interchangeHeader];
                     [wireFormatWriter writeInvocationHeader:self.appCredentials];
                    requestWriter(wireFormatWriter);
                [wireFormatWriter writeEnd];
            [wireFormatWriter writeEnd];
        [wireFormatWriter writeEnd];

        body = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];

    }
    @finally {
        [outputStream close];
    }

    QredoServiceInvokerCallbacks *callbacksValue = [[QredoServiceInvokerCallbacks alloc] init];
    callbacksValue.correlationID = correlationID;
    callbacksValue.serviceName = serviceName;
    callbacksValue.operationName = operationName;
    callbacksValue.responseReader = responseReader;
    callbacksValue.errorHandler = errorHandler;
    callbacksValue.multiResponse = multiResponse;
    
    [self setCallbacksValue:callbacksValue forCorrelationID:correlationID];
    
    // Send the data to the service
    [_transport send:body userData:correlationID];
}

+ (NSData *)secureRandomWithSize:(NSUInteger)size
{
    size_t   randomSize  = size;
    uint8_t *randomBytes = alloca(randomSize);
    int result = SecRandomCopyBytes(kSecRandomDefault, randomSize, randomBytes);
    if (result != 0) {
        @throw [NSException exceptionWithName:@"QredoSecureRandomGenerationException"
                                       reason:[NSString stringWithFormat:@"Failed to generate a secure random byte array of size %lu (result: %d)..", (unsigned long)size, result]
                                     userInfo:nil];
    }
    return [NSData dataWithBytes:randomBytes length:randomSize];
}

- (BOOL)isTerminated
{
    return self.transport.transportClosed;
}

- (BOOL)supportsMultiResponse
{
    return self.transport.supportsMultiResponse;
}

#pragma mark - Internal methods

- (void)notifyCallbackOfError:(NSError *)error forCallbacksValue:(QredoServiceInvokerCallbacks *)callbacksValue
{
    if (!callbacksValue) {
        QredoLogError(@"No callbacksValue provided, cannot notify callback of error.");
    }
    else {
        callbacksValue.errorHandler(error);
        
        // With multi-response, if the server reports a failure, that is the end of the multi-response subscription.
        // Reconnect/subscribe will be needed for further responses. Therefore deleting the callback is always valid,
        // whether multi-response or not.
        [self removeCallbacksValueForCorrelationID:callbacksValue.correlationID];
    }
}

#pragma mark - Concurrency helpers for NSMutableDictionary

- (void)removeCallbacksValueForCorrelationID:(NSData *)correlationID
{
    // Removes the key/value in NSMutableDictionary with an async barrier - to stop read calls from proceeding until we've completed
    dispatch_barrier_async(self.callbacksDictionaryQueue, ^{
        [callbacks removeObjectForKey:correlationID];
    });
}

- (void)setCallbacksValue:(QredoServiceInvokerCallbacks *)callbacksValue forCorrelationID:(NSData *)correlationID
{
    // Sets the key/value in NSMutableDictionary with an async barrier - to stop read calls from proceeding until we've completed
    dispatch_barrier_async(self.callbacksDictionaryQueue, ^{
        [callbacks setObject:callbacksValue forKey:correlationID];
    });
}

- (QredoServiceInvokerCallbacks *)callbacksValueForCorrelationID:(NSData *)correlationID
{
    __block QredoServiceInvokerCallbacks *callbacksValue = nil;
    // Gets the key/value from NSMutableDictionary synchronously
    dispatch_sync(self.callbacksDictionaryQueue, ^{
        callbacksValue = [callbacks objectForKey:correlationID];
    });
    
    return callbacksValue;
}

- (NSArray *)removeAndReturnAllMultiresponseServiceInvokerCallbacks
{
    
    NSMutableArray *multiresponseCallbacks = [NSMutableArray array];
    dispatch_sync(self.callbacksDictionaryQueue, ^{
        
        NSArray *correlationIDs = [callbacks allKeys];
        for (NSData* correlationID in correlationIDs) {
            QredoServiceInvokerCallbacks *callbacksValue = [callbacks objectForKey:correlationID];
            
            if (callbacksValue.multiResponse) {
                [multiresponseCallbacks addObject:callbacksValue];
                [callbacks removeObjectForKey:correlationID];
            }
            
        }
        
    });
    
    return multiresponseCallbacks;
}

#pragma mark - QredoTransportDelegate methods

- (void)didReceiveResponseData:(NSData *)data userData:(id)userData;
{
    NSInputStream *inputStream = [NSInputStream inputStreamWithData:data];
    [inputStream open];

    QredoServiceInvokerCallbacks *callbacksValue = nil;
    NSData* correlationID = nil;
    @try {
        QredoWireFormatReader *wireFormatReader = [QredoWireFormatReader wireFormatReaderWithInputStream:inputStream];
        [wireFormatReader readMessageHeader];
            QredoInterchangeHeader* interchangeHeader = [wireFormatReader readInterchangeHeader];
        
                // Possible that the correlation ID in the call is nil (if unavailable when delegate called), but that header contains the correct value from server
                correlationID = interchangeHeader.correlationID;
                if (userData && ![correlationID isEqualToData:userData]) {
                    QredoLogError(@"Mismatch between non-nil userData (%@) and correlationID in header (%@).  Incorrect callback/responseReader may be used.", [QredoLogger hexRepresentationOfNSData:userData], [QredoLogger hexRepresentationOfNSData:correlationID]);
                }
        
                callbacksValue = [self callbacksValueForCorrelationID:correlationID];
                if (!callbacksValue) {
                    QredoLogError(@"No callback found for correlation ID %@ when processing new response (userData = %@). Will not be able to notify caller.", [QredoLogger hexRepresentationOfNSData:correlationID], [QredoLogger hexRepresentationOfNSData:userData]);
                }
        
                QredoResultHeader *responseResultHeader = [wireFormatReader readResultStart];
                    if ([responseResultHeader isFailure])
                    {
                        NSString *serverErrorDescription = nil;
                        NSNumber *serverErrorCode = nil;
                        @try {
                            [wireFormatReader readSequenceStart];
                            [wireFormatReader readStart];
                            serverErrorCode = [wireFormatReader readInt32];
                            serverErrorDescription = [wireFormatReader readString];
                        }
                        @catch (NSException *exception) {

                        }

                        NSString *reason = [NSString stringWithFormat:@"Remote operation '%@' on service '%@' failed with status '%@'.",
                                            interchangeHeader.operationName,
                                            interchangeHeader.serviceName,
                                            [responseResultHeader status]];

                        if (serverErrorDescription) {
                            reason = [NSString stringWithFormat:@"%@; Server error code: %@ (%@)",
                                      reason, serverErrorCode, serverErrorDescription];
                        }
                        QredoLogError(@"%@", reason);
                        
                        NSError *error = [NSError errorWithDomain:QredoLFErrorDomain
                                                             code:QredoLFErrorRemoteOperationFailure
                                                         userInfo:@{NSLocalizedDescriptionKey: reason}];
                        
                        [self notifyCallbackOfError:error forCallbacksValue:callbacksValue];

                        return;
                    }

                    // Call the block which the caller of invokeService provided
                    if (callbacksValue) {
                        callbacksValue.responseReader(wireFormatReader);
                    } else {
                        // we can only LOG the error here. No throwing exception, because it will just crash app
                        QredoLogError(@"Received response data but no callback found for correlation ID %@, cannot process response.", [QredoLogger hexRepresentationOfNSData:correlationID]);
                    }

                [wireFormatReader readEnd];
            [wireFormatReader readEnd];
        [wireFormatReader readEnd];
    }
    @finally {
        [inputStream close];
    }
    
    if (!correlationID) {
        // Could not or did not get correlationID from the LF header, so fallback to correlation ID passed in
        correlationID = userData;
        
        callbacksValue = [self callbacksValueForCorrelationID:correlationID];
    }

    if (callbacksValue) {
        if (!callbacksValue.multiResponse) {
            [self removeCallbacksValueForCorrelationID:correlationID];
        }
    }
    
    // TODO: DH - Related to question of whether invoke/response is always a pair, should we reset the responseReader after receiving a response? Can/should it be re-used in all/any circumstances?
    
}

- (void)didReceiveError:(NSError *)error userData:(id)userData;
{
    NSData* correlationID = userData;

    QredoServiceInvokerCallbacks *callbacksValue = [self callbacksValueForCorrelationID:correlationID];

    NSString *operationName = nil;
    NSString *serviceName = nil;
    
    if (callbacksValue) {
        operationName = callbacksValue.operationName;
        serviceName = callbacksValue.serviceName;
    }
    
    NSString *reason = [NSString stringWithFormat:@"Remote operation '%@' on service '%@' triggered an error. Error details: '%@'.",
                        operationName,
                        serviceName,
                        error];
    QredoLogError(@"%@", reason);

    NSError *wrappedError = [NSError errorWithDomain:QredoLFErrorDomain
                                                code:QredoLFErrorRemoteOperationFailure
                                            userInfo:@{NSLocalizedDescriptionKey: reason,
                                                       NSUnderlyingErrorKey: error}];

    [self notifyCallbackOfError:wrappedError forCallbacksValue:callbacksValue];

    QredoTransportError errorCode = error.code;
    if (errorCode == QredoTransportErrorConnectionClosed ||
        errorCode == QredoTransportErrorConnectionRefused ||
        errorCode == QredoTransportErrorConnectionFailed)
    {
        NSArray *mutliresponseCallbaks = [self removeAndReturnAllMultiresponseServiceInvokerCallbacks];
        for (QredoServiceInvokerCallbacks *multiResponseCallbacksValue in mutliresponseCallbaks) {
            [self notifyCallbackOfError:wrappedError forCallbacksValue:multiResponseCallbacksValue];
        }
    }

}

@end


