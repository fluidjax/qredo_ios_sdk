/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoTransport.h"
#import "QredoLoggerPrivate.h"
#import "QredoHttpTransport.h"
#import "QredoWebSocketTransport.h"
#import "QredoTransportErrorUtils.h"
#import "QredoCertificate.h"

NSString *const QredoTransportErrorDomain = @"QredoTransportError";

@interface QredoTransport ()

@property (strong) NSURL *serviceURL;
@property (strong) QredoClientId *clientId;

@property (copy) ReceivedResponseBlock receivedResponseBlock;
@property (copy) ReceivedErrorBlock receivedErrorBlock;
@property dispatch_queue_t notificationQueue;

@end

@implementation QredoTransport

+ (instancetype)transportForServiceURL:(NSURL *)serviceURL{
    if (!serviceURL)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Service URL argument is nil"
                                     userInfo:nil];
    }
    
    QredoTransport *transport;
    
    if([QredoHttpTransport canHandleServiceURL:serviceURL])
    {
        // Create the HTTP transport
        transport = [[QredoHttpTransport alloc] initWithServiceURL:serviceURL];
    }
    else if ([QredoWebSocketTransport canHandleServiceURL:serviceURL])
    {
        transport = [[QredoWebSocketTransport alloc] initWithServiceURL:serviceURL];
    }
    else
    {
        // Unsupported URL scheme
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Unsupported scheme for Service URL: %@", serviceURL]
                                     userInfo:nil];
    }
    
    return transport;
}

+ (BOOL)canHandleServiceURL:(NSURL *)serviceURL{
    // Check all subclasses we know about to see whether they're supported
    BOOL canHandle = [QredoHttpTransport canHandleServiceURL:serviceURL];
    return canHandle;
}

- (instancetype) init
{
    // We do not want to be initialised via the NSObect init method as we require arguments (no public setter properties)
    NSAssert(NO, @"Use -initWithServiceURL:");
    return nil;
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL{
    if (!serviceURL)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Service URL argument is nil"]
                                     userInfo:nil];
    }
    
    self = [super init];
    if (self)
    {
        // Concurrent queue - needed as can have multiple responses being processed at same time
        _notificationQueue = dispatch_queue_create("com.qredo.transport.notifications", DISPATCH_QUEUE_CONCURRENT);

        _serviceURL = serviceURL;
        _clientId = [QredoClientId randomClientId];
    }
    
    return self;
}

- (BOOL)supportsMultiResponse
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)send:(NSData*)payload userData:(id)userData
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)close
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)configureReceivedResponseBlock:(ReceivedResponseBlock)block
{
    // TODO: DH - any need to prevent blocks being changed execution?
    self.receivedResponseBlock = block;
}

- (void)configureReceivedErrorBlock:(ReceivedErrorBlock)block
{
    // TODO: DH - any need to prevent blocks being changed execution?
    self.receivedErrorBlock = block;
}

- (BOOL)areHandlersConfigured
{
    if (self.responseDelegate) {
        return YES;
    } else if (self.receivedResponseBlock) {
        return YES;
    }
    
    return NO;
}

- (void)notifyListenerOfResponseData:(NSData *)data userData:(id)userData
{

    if (self.transportClosed) {
        // Trying to notify listener of response after transport is closed
        
        // TODO: DH - what should be done if data received after transport has been closed.  Convert to an error?
#warning Error removed - does it server a purpose?
        //[self notifyListenerOfErrorCode:QredoTransportErrorReceivedDataAfterTransportClosed userData:userData];
        return;
    }
    
    // Copy the data being returned (failing to do this caused data corruption with NSInputStream or dataWithBytes within listener)
    NSData *dataToReturn = [NSData dataWithBytes:data.bytes length:data.length];
    
    // Ensure all notifications are returned back on a concurrent queue
    dispatch_async(self.notificationQueue, ^{
        // If we have a block, use it
        if (self.receivedResponseBlock)
        {
            self.receivedResponseBlock(dataToReturn, userData);
        }
        // Otherwise check the delegate
        else if (self.responseDelegate)
        {
            [self.responseDelegate didReceiveResponseData:dataToReturn userData:userData];
        }
        else
        {
            // Otherwise log an error. Throwing exception from a separate thread is not useful.
            QredoLogError(@"Cannot notify receipt of response data as no block or delegate has been configured.");
        }
    });
    
}


-(int)port{
    return 0;
}


- (void)notifyListenerOfError:(NSError *)error userData:(id)userData
{
    // Note: this method may be called after transport is closed, to notify send/receive attempted after transport is closed.
    
    // Ensure all notifications are returned back on a concurrent queue
    dispatch_async(self.notificationQueue, ^{
        // If we have a block, use it
        if (self.receivedErrorBlock)
        {
            self.receivedErrorBlock(error, userData);
        }
        // Otherwise check the delegate
        else if (self.responseDelegate)
        {
            [self.responseDelegate didReceiveError:error userData:userData];
        }
        else
        {
            // Otherwise log an error. Throwing exception from a separate thread is not useful.
            QredoLogError(@"Cannot notify error as no block or delegate has been configured.");
        }
    });
}

- (void)notifyListenerOfErrorCode:(QredoTransportError)code userData:(id)userData
{
    NSError *error = [QredoTransportErrorUtils errorWithErrorCode:code];
    [self notifyListenerOfError:error userData:userData];
}

- (NSString *)getHexClientID
{
    return [QredoLogger hexRepresentationOfNSData:[self.clientId getData]];
}

@end
