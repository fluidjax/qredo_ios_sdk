/* HEADER GOES HERE */
#import "QredoHttpTransport.h"
#import "QredoWireFormat.h"
#import "QredoLoggerPrivate.h"
#import "QredoTransportSSLTrustUtils.h"
#import "QredoCertificate.h"

@interface QredoHttpTransport ()<NSURLSessionDelegate>

@property NSURLSession *urlSession;
//TODO: DH - look at whether these properties/constants can move into parent QredoTransport
@property dispatch_queue_t sendQueue;

@end

@implementation QredoHttpTransport

@dynamic transportClosed;

static const NSUInteger maxNumberOfConnections = 10;

#pragma mark - QredoTransport override methods

+(BOOL)canHandleServiceURL:(NSURL *)serviceURL {
    BOOL canHandle = NO;
    
    NSString *scheme = serviceURL.scheme;
    
    //Using case-insensitive comparison as apparently Apple has previously changed the case returned by NSURL.scheme method, breaking code
    if ([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame
        || [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame){
        canHandle = YES;
    }
    
    return canHandle;
}


-(instancetype)initWithServiceURL:(NSURL *)serviceURL {
    if (!serviceURL){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Service URL argument is nil"]
                                     userInfo:nil];
    }
    
    self = [super initWithServiceURL:serviceURL];
    
    if (self){
        if (![[self class] canHandleServiceURL:serviceURL]){
            //Unsupported URL scheme
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Class '%@' does not support provided URL scheme. Service URL: %@",[self class],serviceURL]
                                         userInfo:nil];
        }
        
        //When receiving data, we must not block (as some operations require another request before completing).
        //When sending NSURLSessionUploadTask spawns a new thread each time, and to limit the number of threads/connections
        //NSURLSessionConfiguraiton.HTTPMaximumConnectionsPerHost is used.
        //Response notifications are done on a concurrent queue to avoid blocking the transport.
        _sendQueue = dispatch_queue_create("com.qredo.httpTransport.send",DISPATCH_QUEUE_SERIAL);
        
        //Ephemeral session prevents caching of data, recommended for best privacy
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        configuration.timeoutIntervalForRequest = 10;
        configuration.HTTPMaximumConnectionsPerHost = maxNumberOfConnections;
        _urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        
        self.transportClosed = NO;
    }
    
    return self;
}


-(void)dealloc {
    if (!_transportClosed){
        [self close];
    }
}


-(void)setTransportClosed:(BOOL)transportClosed {
    _transportClosed = transportClosed;
}


-(BOOL)supportsMultiResponse {
    //HTTP transport does not support multi-response
    return NO;
}


-(void)send:(NSData *)payload userData:(id)userData {
    if (![self areHandlersConfigured]){
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"No handlers configured. Must configure delegate, or configure receiver blocks before sending data."
                                     userInfo:nil];
    }
    
    if (self.transportClosed){
        //Do nothing - we dont need to know about closed tranports
//        dispatch_sync(self.sendQueue,^{
//            [self notifyListenerOfErrorCode:QredoTransportErrorSendAfterTransportClosed userData:userData];
//            return;
//        });
    } else {
        dispatch_sync(self.sendQueue,^{
            [self sendPayloadInternal:payload userData:userData];
        });
    }
    
    //dispatch_sync(self.sendQueue, ^{
    //
    //if (self.transportClosed){
    //[self notifyListenerOfErrorCode:QredoTransportErrorSendAfterTransportClosed userData:userData];
    //return;
    //}
    //[self sendPayloadInternal:payload userData:userData];
    //});
}


-(void)close {
    //Nothing to do for HTTP as no long-running connections/threads used.
    self.transportClosed = YES;
}


-(void)sendPayloadInternal:(NSData *)payload userData:(id)userData {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.serviceURL];
    
    [urlRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [urlRequest setHTTPMethod:@"POST"];
    
    NSURLSessionUploadTask *uploadTask =
    [self.urlSession uploadTaskWithRequest:urlRequest
                              fromData:payload
                     completionHandler:^void (NSData *inputData,NSURLResponse *response,NSError *error) {
                         if (error){
                             //QredoLogError(@"%@: Error occurred during HTTP to URL '%@'. Error details: '%@'", [self.clientId getSafeString], self.serviceURL, error);
                             
                             QredoLogError(@"Error occurred during HTTP to URL '%@'. Error details: '%@'",self.serviceURL,error.localizedDescription);
                             
                             [self notifyListenerOfError:error
                                                userData:userData];
                         } else {
                             //fix for unexplainable crash on 64-bit architectures
                             NSData *data = [NSData dataWithBytesNoCopy:(void *)inputData.bytes
                                                                 length:inputData.length
                                                           freeWhenDone:NO];
                             
                             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                             
                             if (httpResponse.statusCode != 200){
                                 //TODO: DH - Confirm whether non-200 code should be raised via error listener, rather then response listener
                                 QredoLogError(@"NOTE: Non-200 status code returned (%ld). Call may not have been successful.",(long)httpResponse.statusCode);
                             }
                             
                             [self notifyListenerOfResponseData:data
                                                       userData:userData];
                         }
                     }];
    
    [uploadTask resume];
}


#pragma mark - NSURLSessionDelegate

-(void)      URLSession:(NSURLSession *)session
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
      completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                  NSURLCredential *credential))completionHandler {
    NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
    
    if ([protectionSpace authenticationMethod] == NSURLAuthenticationMethodServerTrust){
        SecTrustRef trust = [protectionSpace serverTrust];
        NSURLCredential *credential = nil;
        
        credential = [[NSURLCredential alloc] initWithTrust:trust];
        
        if (credential){
            if (completionHandler)completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
            
            return;
        }
    }
    
    if (completionHandler)completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
}


@end
