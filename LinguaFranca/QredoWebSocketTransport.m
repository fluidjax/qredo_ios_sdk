/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoWebSocketTransport.h"
#import "JFRWebSocket.h"
#import "QredoTransportSSLTrustUtils.h"
#import "QredoCertificate.h"
#import "QredoTransportErrorUtils.h"
#import "QredoLoggerPrivate.h"

static const NSUInteger WebSocketSendCheckConnectedCount = 10;
static const NSTimeInterval WebSocketSendCheckConnectedDelay = 3.0; // 1 second delay when waiting to see if connected

@interface QredoWebSocketTransport ()<JFRWebSocketDelegate>
{
    BOOL _webSocketOpen;
    BOOL _isResartingWebSocket;
}
@property (nonatomic) JFRWebSocket *webSocket;
@property (nonatomic) BOOL shouldRestartWebSocket;
@property (nonatomic) NSTimeInterval reconectionDelay;
@end

@implementation QredoWebSocketTransport

@dynamic transportClosed;

+ (BOOL)canHandleServiceURL:(NSURL *)serviceURL
{
    BOOL canHandle = NO;
    
    NSString *scheme = serviceURL.scheme;
    
    // Using case-insensitive comparison as apparently Apple has previously changed the case returned by NSURL.scheme method, breaking code
    if ([scheme caseInsensitiveCompare:@"wss"] == NSOrderedSame) {
        canHandle = YES;
    } else if ([scheme caseInsensitiveCompare:@"ws"] == NSOrderedSame) {
        canHandle = YES;
    }
    
    return canHandle;
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL pinnedCertificate:(QredoCertificate *)certificate
{
    self = [super initWithServiceURL:serviceURL pinnedCertificate:certificate];
    if (self) {
        [self startWebSocket];
    }
    return self;
}

-(void)close
{
    self.transportClosed = YES;
    self.shouldRestartWebSocket = NO;
    [self closeWebSocket];
}


#pragma mark

- (void)startWebSocket
{
    self.shouldRestartWebSocket = YES;
    
    self.webSocket = [[JFRWebSocket alloc] initWithURL:self.serviceURL protocols:@[@"qredo"]];
    _webSocket.queue = dispatch_queue_create("WebSocketDelegateDispatchQueue", DISPATCH_QUEUE_SERIAL);
    _webSocket.delegate=self;
    [_webSocket connect];
    
}

- (void)closeWebSocket
{
    if (_webSocketOpen && _webSocket) {
        
        
        
//        static NSMutableArray *socketPark;
//        
//        if (!socketPark)socketPark=[[NSMutableArray alloc] init];
//        [socketPark addObject:_webSocket];
//        NSLog(@"Sockpark size is %i",(int)[socketPark count]);
        
        [_webSocket disconnect];
        
        
        
        _webSocket.delegate = nil;
    }
}

- (void)restartWebSocketWithExponentialDelay
{
    if (_isResartingWebSocket) {
        return;
    }
    
    if (!self.shouldRestartWebSocket) {
        return;
    }
    
    _isResartingWebSocket = YES;
    
    [self closeWebSocket];
    
    
   QredoLogWarning(@"Reconnecting Web Socket");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(self.reconectionDelay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^
    {
        _isResartingWebSocket = NO;
        [self startWebSocket];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"resubscribe" object:self];
    });
    
    _reconectionDelay *= 2.0;
}


#pragma mark

- (BOOL)supportsMultiResponse
{
    return YES;
}

- (void)send:(NSData *)payload userData:(id)userData
{
    if (!_webSocket) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"No websocket or handlers configured. Must configure web socket, and delegate before sending data."
                                     userInfo:nil];
        return;
    }
    
    if (self.transportClosed)
    {
        [self notifyListenerOfErrorCode:QredoTransportErrorSendAfterTransportClosed userData:userData];
        return;
    }
    
    if (!_webSocketOpen)
    {
        // This could happen on the first send, as the connection/subscription setup runs in the background and may not be ready yet.
        // If occurs, then wait a bit and retry.  If still not ready, give up.
        
        
        for (int sleepI = 0; sleepI < WebSocketSendCheckConnectedCount && !_webSocketOpen; sleepI++) {
            [NSThread sleepForTimeInterval:WebSocketSendCheckConnectedDelay];
        }
        
        if (!_webSocketOpen)
        {
            [self notifyListenerOfErrorCode:QredoTransportErrorSendWhilstNotReady userData:userData];
            return;
        }
    }

    [_webSocket writeData:payload];
}

- (void)setTransportClosed:(BOOL)transportClosed
{
    if (_transportClosed == transportClosed) return;
   _transportClosed = transportClosed;
}



#pragma mark JFRWebSocketDelegate

-(void)websocket:(JFRWebSocket*)socket didReceiveData:(NSData*)data{
     [self notifyListenerOfResponseData:data userData:nil];
}

-(void)websocketDidConnect:(JFRWebSocket*)socket{
    self.reconectionDelay = 1.0;
    _webSocketOpen = YES;

}


-(void)websocketDidDisconnect:(JFRWebSocket*)socket error:(NSError*)error{
    _webSocketOpen = NO;
    QredoLogWarning(@"Websocket did disconnect");
    if (error){
        [self notifyListenerOfErrorCode:QredoTransportErrorConnectionFailed userData:nil];
        [self restartWebSocketWithExponentialDelay];
    }
}




@end
