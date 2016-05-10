//
//  QredoXCTestCase.m
//  QredoSDK
//
//  Created by Christopher Morris on 22/01/2016.
//  This is the superclass of all Qredo Tests
//

#import "QredoXCTestCase.h"



@interface TestRendezvousListener :NSObject <QredoRendezvousObserver>

@property XCTestExpectation *expectation;
@property QredoConversation *incomingConversation;
@end

@implementation TestRendezvousListener
XCTestExpectation *timeoutExpectation;

-(void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation {
    if (self.expectation) {
        self.incomingConversation = conversation;
        [self.expectation fulfill];
    }
}

@end




@interface TestConversationMessageListener : NSObject <QredoConversationObserver>

@property QredoXCTestCase *test;
@property NSString *expectedMessageValue;
@property BOOL failed;
@property BOOL listening;
@property XCTestExpectation *expectation;
@property NSNumber *fulfilledtime;

@end

@implementation TestConversationMessageListener


- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message{
    // Can't use XCTAsset, because this class is not QredoXCTestCase
    
    @synchronized(_test) {
        if (_listening) {
            self.failed |= (message == nil);
            self.failed |= !([message.value isEqualToData:[self.expectedMessageValue dataUsingEncoding:NSUTF8StringEncoding]]);
            
            _fulfilledtime = @(_fulfilledtime.intValue + 1);
            _listening = NO;
            [_expectation fulfill];
        }
    }
}

@end











static const int testTimeOut = 30;


@implementation QredoXCTestCase


- (void)setUp {
    [super setUp];
    [QredoLogger colour:NO];
    [QredoLogger setLogLevel:QREDO_DEBUG_LEVEL];
    
    k_TEST_APPID         = @"test";
    k_TEST_APPSECRET     = @"cafebabe";
    k_TEST_USERID        = @"testUserId";
    
   //NSLog(@"*** QREDO_SERVER_URL  %@",QREDO_SERVER_URL);
   // NSLog(@"*** QREDO_DEBUG_LEVEL %i",QREDO_DEBUG_LEVEL);
   
}

- (void)tearDown {
    
    
    //client
    [testClient1 closeSession];
    [testClient2 closeSession];;
    
    testClient1Password=nil;
    testClient2Password=nil;
    
    
    //rendezvous
    rendezvous1 = nil;
    rendezvous1Tag = nil;
    
    
    //conversation
    conversation1=nil;
    conversation2=nil;
    conversationHWM=nil;
    
    [super tearDown];
}


-(void)setLogLevel{
/*  Available debug levels
        [QredoLogger setLogLevel:QredoLogLevelNone];
        [QredoLogger setLogLevel:QredoLogLevelError];
        [QredoLogger setLogLevel:QredoLogLevelWarning];
        [QredoLogger setLogLevel:QredoLogLevelInfo];
        [QredoLogger setLogLevel:QredoLogLevelDebug];
        [QredoLogger setLogLevel:QredoLogLevelVerbose];
        [QredoLogger setLogLevel:QredoLogLevelInfo];
 */
    [QredoLogger setLogLevel:QredoLogLevelError];
 
    
    

    
}


-(void)loggingOff{
    [QredoLogger setLogLevel:QredoLogLevelNone];
}


-(void)loggingOn{
    [self setLogLevel];
}


-(void)resetKeychain {
    [self deleteAllKeysForSecClass:kSecClassGenericPassword];
    [self deleteAllKeysForSecClass:kSecClassInternetPassword];
    [self deleteAllKeysForSecClass:kSecClassCertificate];
    [self deleteAllKeysForSecClass:kSecClassKey];
    [self deleteAllKeysForSecClass:kSecClassIdentity];
}


-(void)deleteAllKeysForSecClass:(CFTypeRef)secClass {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:(__bridge id)secClass forKey:(__bridge id)kSecClass];
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef) dict);
    NSAssert(result == noErr || result == errSecItemNotFound, @"Error deleting keychain data (%ld)", (long)result);
}


- (NSData*)randomDataWithLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: length];
    for (unsigned int i = 0; i < length; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    } return mutableData;
}



-(NSString*)randomPassword{
    return [self randomStringWithLength:32];
}

-(NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}




///////////////////////////////////////////////////////////////////////
// Wrapper Methods


-(void)createClients{
    [self initClient1];
    [self initClient2];
}


-(void)initClient1{
    testClient1Password = [self randomPassword];
    testClient1 = [self createClient:testClient1Password];
}

-(void)initClient2{
    testClient2Password = [self randomPassword];
    testClient2 = [self createClient:testClient2Password];
    
}




///////////////////////////////////////////////////////////////////////
// Core Methods


-(QredoClient*)createClient:(NSString*)userSecret{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:k_TEST_USERID
                          userSecret:userSecret
                             options:[[QredoClientOptions alloc] initDefaultPinnnedCertificate]
                   completionHandler:^(QredoClient *clientArg, NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       client = clientArg;
                       [clientExpectation fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:testTimeOut handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    XCTAssertNotNil(client);
    XCTAssertNotNil(client.systemVault);
    XCTAssertNotNil(client.systemVault.vaultId);
    return client;
    
}



-(void)createRendezvous{
    __block QredoRendezvous *newRendezvous = nil;
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:600
                              unlimitedResponses:YES
                               completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(rendezvous);
                                   newRendezvous = rendezvous;
                                   [createExpectation fulfill];
                               }];
    [self waitForExpectationsWithTimeout:testTimeOut handler:^(NSError *error) {
        createExpectation = nil;
    }];
    XCTAssertNotNil(newRendezvous);
    rendezvous1Tag = newRendezvous.tag;
    XCTAssertNotNil(rendezvous1Tag);
    rendezvous1 = newRendezvous;
}



-(QredoConversation*)simpleRespondToRendezvous:(NSString*)tag{
    //simply respond to the rendezvous on client 1 with client 2
    
    __block QredoConversation *newConversation = nil;
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create conversation"];
    [testClient2 respondWithTag:tag
                completionHandler:^(QredoConversation *conversation, NSError *error) {
                    XCTAssertNil(error);
                    XCTAssertNotNil(conversation);
                    newConversation = conversation;
                    [createExpectation fulfill];
                }];
    
    [self waitForExpectationsWithTimeout:testTimeOut handler:^(NSError *error) {
        createExpectation = nil;
    }];

    XCTAssertNotNil(newConversation);
    return newConversation;
}

-(void)respondToRendezvous{
    //  Repspond to rendezvous on Client2 and wait for the listener on Client1 to get notified of the new Conversation
    //  testClient1 - gets conversation1
    //  testClient2 - gets conversation2
    
    

    // Listening for responses and respond from another client
    TestRendezvousListener *listener = [[TestRendezvousListener alloc] init];
    XCTAssertNotNil(rendezvous1);
    
    [rendezvous1 addRendezvousObserver:listener];
    [NSThread sleepForTimeInterval:0.1];
    
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    [NSThread sleepForTimeInterval:0.1];

    
    [testClient2 respondWithTag:rendezvous1Tag
          completionHandler:^(QredoConversation *conversation, NSError *error) {
              XCTAssertNil(error);
              conversation2 = conversation;
          }];

    [self waitForExpectationsWithTimeout:testTimeOut handler:^(NSError *error) {
        listener.expectation = nil;
    }];
    
    conversation1 = listener.incomingConversation;
    XCTAssertNotNil(conversation1);
    XCTAssertNotNil(conversation2);
}


-(void)sendConversationMessageFrom1to2{
    [self sendMessageFrom:conversation1 to:conversation2];
}
-(void)sendConversationMessageFrom2to1{
    [self sendMessageFrom:conversation2 to:conversation1];
}


-(void)sendMessageFrom:(QredoConversation*)fromConversation to:(QredoConversation*)toConversation{
    //send a message from ClientA to ClientB
    NSString *message = @"test message";
    
    TestConversationMessageListener *listener = [[TestConversationMessageListener alloc] init];
    listener.expectation = [self expectationWithDescription:@"wait for incoming message"];
    listener.expectedMessageValue = message;
    listener.test = self;
    listener.listening = YES;
    
    [toConversation addConversationObserver:listener];
    
    __block QredoConversationHighWatermark *hwm = nil;
    QredoConversationMessage *qredoMessage = [[QredoConversationMessage alloc] initWithValue:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                                               summaryValues:nil];

    [fromConversation publishMessage:qredoMessage
                        completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                            XCTAssertNil(error);
                            XCTAssertNotNil(messageHighWatermark);
                            conversationHWM = messageHighWatermark;
                        }];
    
    [self waitForExpectationsWithTimeout:testTimeOut handler:^(NSError *error) {
    }];
    
}



-(void)buildStack1{
    [self createClients];
    [self createRendezvous];
    [self respondToRendezvous];
}



-(void)buildStack2{
    [self createClients];
    [self createRendezvous];
    [self respondToRendezvous];
    [self sendConversationMessageFrom1to2];
    [self sendConversationMessageFrom2to1];
}


@end
