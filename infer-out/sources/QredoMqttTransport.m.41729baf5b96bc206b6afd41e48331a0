/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoMqttTransport.h"
#import "MQTTSession.h"
#import "QredoClientId.h"
#import "QredoLoggerPrivate.h"
#import "QredoTransportErrorUtils.h"
#import "QredoTransportSSLTrustUtils.h"
#import "QredoCertificate.h"

@interface QredoMqttTransport()<MQTTSessionDelegate>

@property (assign) BOOL connectedAndReady;
@property (assign) BOOL keepReconnecting;
@property (strong) MQTTSession *mqttSession;
@property (strong) NSThread *mqttThread;
@property (copy) NSString *host;
@property (assign) int port;
@property (assign) BOOL usingSsl;
@property (assign) int connectionAttempts;
@property (assign) NSTimeInterval reconnectionDelay;

@end

@implementation QredoMqttTransport

@dynamic transportClosed;

NSString *const RpcRequestsTopic = @"/rpc/requests";
NSString *const RpcResponsesTopicBase = @"/rpc/responses";
NSString *const RpcLastWillTestamentTopicBase = @"/rpc/disconnections";
NSString *const MqttUsername = @""; // We do not use username and passwords
NSString *const MqttPassword = @"";
static const int MqttHeartbeatPeriodSeconds = 30; // 30 second MQTT keepalive/heartbeat
static const int MqttQoS = 1;
static const int DefaultMqttPort = 1883;
static const int DefaultMqttSslPort = 8883;
static const NSTimeInterval MqttInitialReconnectionDelaySeconds = 1; // 1 second delay
static const NSTimeInterval MqttMaxReconnectionDelaySeconds = 60 * 5; // 5 mins maximum delay
static const NSTimeInterval MqttSendCheckConnectedDelay = 5.0; // 1 second delay when waiting to see if connected
static const NSTimeInterval MqttCancellationCheckPeriod = 0.5; // Frequency to check whether MQTT thread has been cancelled

#pragma mark - QredoTransport override methods

+ (BOOL)canHandleServiceURL:(NSURL *)serviceURL
{
    BOOL canHandle = NO;
    
    NSString *scheme = serviceURL.scheme;

    // Using case-insensitive comparison as apparently Apple has previously changed the case returned by NSURL.scheme method, breaking code
    if (([scheme caseInsensitiveCompare:@"tcp"] == NSOrderedSame) ||
        ([scheme caseInsensitiveCompare:@"ssl"] == NSOrderedSame))
    {
        canHandle = YES;
    }

    return canHandle;
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL pinnedCertificate:(QredoCertificate *)certificate
{
    if (!serviceURL)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Service URL argument is nil"]
                                     userInfo:nil];
    }
    
    self = [super initWithServiceURL:serviceURL pinnedCertificate:certificate];
    if (self)
    {
        if (![[self class] canHandleServiceURL:serviceURL])
        {
            // Unsupported URL scheme
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Class '%@' does not support provided URL scheme. Service URL: %@", [self class], serviceURL]
                                         userInfo:nil];
        }

        // Process the service URL to decide on hostname, port and whether SSL being used
        [self processServiceUrl:serviceURL];
        
        _keepReconnecting = YES; // Auto-reconnect until 'close' is called
        _connectedAndReady = NO;
        _reconnectionDelay = MqttInitialReconnectionDelaySeconds;

        _mqttThread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(setupMqttClientAndKeepRunning)
                                                object:nil];
        _mqttThread.name = [NSString stringWithFormat:@"MQTT %@ %@", serviceURL, [self.clientId getSafeString]];
        [_mqttThread start];
        
        self.transportClosed = NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reconnectWithExponentialDelay:) name:@"reconnect" object:nil];
    
    return self;
}

-(void)dealloc
{
    if (!_transportClosed) {
        [self close];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reconnect" object:nil];
}

-(void)setTransportClosed:(BOOL)transportClosed {
    _transportClosed = transportClosed;
}

- (BOOL)supportsMultiResponse
{
    // MQTT transport can support multi-response
    return YES;
}

- (void)setupMqttClientAndKeepRunning
{
    @autoreleasepool {
        // Configure the MQTT client

        _connectedAndReady = NO;

        NSString *willTopic = [self getLastWillTestamentChannelTopic];
        NSData *willMessage = [[NSData alloc] init]; // Empty will message
        _mqttSession = [[MQTTSession alloc] initWithClientId:[self.clientId getSafeString] userName:MqttUsername password:MqttPassword keepAlive:MqttHeartbeatPeriodSeconds cleanSession:YES willTopic:willTopic willMsg:willMessage willQoS:MqttQoS willRetainFlag:NO runLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        if (!_mqttSession)
        {
            QredoLogError(@"%@: Could not initialise MQTTSession, initialiser returned nil.", [self getHexClientID]);
            
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Could not initialise MQTTSession."
                                         userInfo:nil];
        }
        
        [_mqttSession setDelegate:self];
        
        // Attempt to connect to the server
        [self connectToServerUsingSession:_mqttSession];
    
    
        while (!self.mqttThread.isCancelled) {
            /*  Documented Intermittent error
             Error:
                MQTT ssl://early1.qredo.com:8883:... (8) EXC_BAD_ACCESS (code=EXC_I386_GPFLT)
                Occurs on QredoSKDTest: QredoRendezvousMQTTTests : testCreateRendezvousMulitple  - after many iterations (46 & 172 in testing)
             References:
                http://www.coderhelps.xyz/code/17032356-bad-exc-in-nsrunloop-currentrunloop-runmode-beforedate.html
                removing autorelease has no effect
             */
            
             [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:MqttCancellationCheckPeriod]];
        }

    }
}

- (void)send:(NSData *)payload userData:(id)userData
{
    if (![self areHandlersConfigured])
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"No handlers configured. Must configure delegate, or configure receiver blocks before sending data."
                                     userInfo:nil];
    }
    
    if (self.transportClosed)
    {
        [self notifyListenerOfErrorCode:QredoTransportErrorSendAfterTransportClosed userData:userData];
        return;
    }
    
    if (!self.connectedAndReady)
    {
        // This could happen on the first send, as the connection/subscription setup runs in the background and may not be ready yet.
        // If occurs, then wait a bit and retry.  If still not ready, give up.
        [NSThread sleepForTimeInterval:MqttSendCheckConnectedDelay];
        
        if (!self.connectedAndReady)
        {
            QredoLogError(@"%@: After waiting and retrying, still not connected/ready. Aborting send, returning error.", [self getHexClientID]);
            
            [self notifyListenerOfErrorCode:QredoTransportErrorSendWhilstNotReady userData:userData];
            
            return;
        }
    }

    /*
     All sends MUST be performed on the (serial queued) MQTT thread, as the Paho MQTT library
     will itself automatically send PingReq messages.  Should both our, and the PingReq messages
     be sent at the same time, then a Paho assert is hit, crashing the app. By ensuring both our
     sends and Paho's sends as performed on the same serial queued thread, we can avoid this.
     
     Additionally, we then avoid the need to do any further synchronisation to prevent this send
     method being called twice from different threads.
     */
    [self performSelector:@selector(sendPayloadToCorrectTopic:) onThread:self.mqttThread withObject:payload waitUntilDone:YES];
}

- (void)close
{
    self.transportClosed = YES;

    // Indicate to the processing thread that it should quit
    [self.mqttThread cancel];
    
    // This should disconnect and stop all further reconnection attempts
    self.keepReconnecting = NO;
    [self disconnectFromServerUsingSession:self.mqttSession];
}

#pragma mark - Internal methods

- (void)processServiceUrl:(NSURL *)serviceURL
{
    _host = serviceURL.host;
    
    if ([serviceURL.scheme caseInsensitiveCompare:@"ssl"] == NSOrderedSame)
    {
        _usingSsl = YES;
    }
    
    if (!serviceURL.port)
    {
        // Port was missed out, so use defaults
        if (_usingSsl)
        {
            _port = DefaultMqttSslPort;
        }
        else
        {
            _port = DefaultMqttPort;
        }
        
    }
    else
    {
        _port = [serviceURL.port intValue];
    }
}

- (void)sendPayloadToCorrectTopic:(NSData *)payload
{
    NSString *topic = [self getRequestChannelTopic];

    // Check that we're running on the MQTT thread otherwise bad concurrency issues can occur.
    // See comment in send:userData: (which ensures correct thread is used) for more information.
    if ([NSThread currentThread] != self.mqttThread) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Attempt to send payload to MQTT session on incorrect thread."
                                     userInfo:nil];
        
    }
    [self.mqttSession publishDataAtMostOnce:payload onTopic:topic retain:NO];
}

- (NSString *)getRequestChannelTopic
{
    NSString *requestChannelTopic = [NSString stringWithFormat:@"%@", RpcRequestsTopic];
    
    return requestChannelTopic;
}

- (NSString *)getReturnChannelTopic
{
    NSString *returnChannelTopic = [NSString stringWithFormat:@"%@/%@", RpcResponsesTopicBase, [self.clientId getSafeString]];

    return returnChannelTopic;
}

- (NSString *)getLastWillTestamentChannelTopic
{
    NSString *lastWillTestamentChannelTopic = [NSString stringWithFormat:@"%@/%@", RpcLastWillTestamentTopicBase, [self.clientId getSafeString]];
    
    return lastWillTestamentChannelTopic;
}

- (void)reconnectWithExponentialDelay:(id)sender
{
    [self reconnectWithExponentialDelayForSession:self.mqttSession];
}

- (void)reconnectWithExponentialDelayForSession:(MQTTSession *)mqttSession
{
    if (self.connectedAndReady)
    {
        [self disconnectFromServerUsingSession:mqttSession];
    }
    
    if (self.keepReconnecting)
    {
        self.connectionAttempts++;

        // Double the delay each time, up to maximum delay
        self.reconnectionDelay *= 2;
        if (self.reconnectionDelay >= MqttMaxReconnectionDelaySeconds)
        {
            self.reconnectionDelay = MqttMaxReconnectionDelaySeconds;
        }
        
        [NSThread sleepForTimeInterval:self.reconnectionDelay];
        
        [self connectToServerUsingSession:mqttSession];
    
   }
}

- (void)connectToServerUsingSession:(MQTTSession *)mqttSession
{
    if (self.usingSsl) {
        if (self.pinnedCertificate) {
            [mqttSession connectToHost:self.host
                                  port:self.port
 usingSSLWithStreamSocketSecurityLevel:kCFStreamSocketSecurityLevelTLSv1
                        trustValidator:trustValidatorWithTrustedCert(self.pinnedCertificate.certificate)];
        } else {
            [mqttSession connectToHost:self.host
                                  port:self.port
 usingSSLWithStreamSocketSecurityLevel:kCFStreamSocketSecurityLevelTLSv1
                        trustValidator:nil];
        }
    } else {
        [mqttSession connectToHost:self.host port:self.port];
    }
    
}

- (void)disconnectFromServerUsingSession:(MQTTSession *)mqttSession
{
    [mqttSession setDelegate:nil];
    [mqttSession close];
    self.connectedAndReady = NO;
}

#pragma mark - MQTTSession callback methods

- (void)session:(MQTTSession*)sender handleEvent:(MQTTSessionEvent)eventCode {
    
    // Note: All events other than MQTTSessionEventConnected result in an invalidated session,
    // therefore for these events we must always reconnect before using the session again
        
    switch (eventCode) {
        case MQTTSessionEventConnected:
            {
                self.connectionAttempts = 0;
                
                // Now subscribe to the Responses topic
                NSString *returnChannelTopic = [self getReturnChannelTopic];
                [self.mqttSession subscribeTopic:returnChannelTopic];

                // Only once we've set everything up, are we ready
                self.connectedAndReady = YES;
            }
            break;
            
        case MQTTSessionEventConnectionRefused:{
            QredoLogError(@"%@: Connection refused.  Will reconnect.", [self getHexClientID]);
            self.connectedAndReady = NO;
            [self notifyListenerOfErrorCode:QredoTransportErrorConnectionRefused userData:nil];
            [self reconnectWithExponentialDelayForSession:sender];
            break;
        }
        case MQTTSessionEventConnectionClosed:{
            QredoLogError(@"%@: Connection closed.  Will reconnect.", [self getHexClientID]);
            self.connectedAndReady = NO;
            [self notifyListenerOfErrorCode:QredoTransportErrorConnectionClosed userData:nil];
            [self reconnectWithExponentialDelayForSession:sender];
            break;
        }
        case MQTTSessionEventConnectionError:{
            QredoLogError(@"%@: Connection error.  Will reconnect.", [self getHexClientID]);
            self.connectedAndReady = NO;
            [self notifyListenerOfErrorCode:QredoTransportErrorConnectionFailed userData:nil];
            [self reconnectWithExponentialDelayForSession:sender];
            break;
        }
        case MQTTSessionEventProtocolError:{
            QredoLogError(@"%@: Protocol error.  Will reconnect.", [self getHexClientID]);
            self.connectedAndReady = NO;
            [self notifyListenerOfErrorCode:QredoTransportErrorCannotParseProtocol userData:nil];
            [self reconnectWithExponentialDelayForSession:sender];
            break;
        }
        default:{
            QredoLogError(@"%@: Unhandled event code: %@.  Will reconnect.", [self getHexClientID], @(eventCode));
            self.connectedAndReady = NO;
            [self notifyListenerOfErrorCode:QredoTransportErrorUnknown userData:nil];
            [self reconnectWithExponentialDelayForSession:sender];
            break;
        }
    }
}

- (void)session:(MQTTSession*)sender newMessage:(NSData*)data onTopic:(NSString*)topic {
    
    if ([topic isEqualToString:[self getReturnChannelTopic]])
    {
        [self notifyListenerOfResponseData:data userData:nil];
    }
    else
    {
        NSString *description = [NSString stringWithFormat:@"Received message on unhandled topic: '%@'", topic];
        NSError *error = [QredoTransportErrorUtils errorWithErrorCode:QredoTransportErrorUnhandledTopic description:description];

        QredoLogError(@"%@: %@", [self getHexClientID], description);
        [self notifyListenerOfError:error userData:nil];
    }
}


@end
