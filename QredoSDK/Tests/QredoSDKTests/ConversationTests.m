/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoTestUtils.h"
#import "QredoPrivate.h"
#import "ConversationTests.h"
#import "QredoLoggerPrivate.h"
#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoNetworkTime.h"
#import "QredoXCTestListeners.h"


//This test should has some commonalities with RendezvousListenerTests, however,
//the purpose of this test is to cover all edge cases in the conversations:
//- publish message
//- receiving message through callback
//- start/stop listening
//- resetHighwatermark
//- persisting highwatermark
//- releasing references after stopListening

static NSString *const kMessageType = @"com.qredo.text";
static NSString *const kMessageTestValue = @"(1)hello, world";
static NSString *const kMessageTestValue2 = @"(2)another hello, world";
static float delayInterval = 0.4;











@interface ConversationMessageListener :NSObject <QredoConversationObserver>

@property ConversationTests *test;
@property NSString *expectedMessageValue;
@property BOOL failed;
@property BOOL listening;
@property NSNumber *fulfilledtime;

@end





@implementation ConversationMessageListener


-(void)qredoConversationOtherPartyHasLeft:(QredoConversation *)conversation {
    @synchronized(_test) {
        QLog(@"qredoConversation:didReceiveNewMessage:");
        
        if (_listening){
            if (_test.didRecieveOtherPartyHasLeft){
                QLog(@"really fullfilling");
                [_test.didRecieveOtherPartyHasLeft fulfill];
                _listening = NO;
            }
        }
    }
}


-(void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message {
    //Can't use XCTAsset, because this class is not QredoXCTestCase
    
    
    
    @synchronized(_test) {
        QLog(@"qredoConversation:didReceiveNewMessage:");
        
        if (_listening){
            self.failed |= (message == nil);
            self.failed |= !([message.value isEqualToData:[self.expectedMessageValue dataUsingEncoding:NSUTF8StringEncoding]]);
            
            self.failed |= !([message.dataType isEqualToString:kMessageType]);
            
            QLog(@"fulfilling self: %@, self.didReceiveMessageExpectiation: %@",self,_test.didReceiveMessageExpectation);
            
            _fulfilledtime = @(_fulfilledtime.intValue + 1);
            QLog(@"CALLS TO FULFILL: %d",_fulfilledtime.intValue);
            
            if (_test.didReceiveMessageExpectation){
                //dispatch_barrier_sync(dispatch_get_main_queue(), ^{
                QLog(@"really fullfilling");
                [_test.didReceiveMessageExpectation fulfill];
                //});
                _listening = NO;
            }
        }
    }
}


@end

@interface ConversationTests () <QredoRendezvousObserver>{
    QredoClient *client;
    QredoClient *anotherClient;
    NSNumber *rvuFulfilledTimes;
    QredoConversation *creatorConversation;
}


@end

@implementation ConversationTests

-(void)setUp {
    [super setUp];
    [self authoriseClient];
    [self authoriseAnotherClient];
}


-(void)tearDown {
    [super tearDown];
    
    if (client)[client closeSession];
    
    if (anotherClient)[anotherClient closeSession];
}


-(void)testEnumerateConversaionsOnClient {
    [self buildStack2];
    XCTAssert([self countConversationsOnClient:testClient1] == 1);
    __block XCTestExpectation *fp = [self expectationWithDescription:@"fingerprint"];
    [conversation1 iHaveRemoteFingerPrint:^(NSError *error) {
        XCTAssertNil(error);
        [fp fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     fp = nil;
                                 }];
    
    XCTAssert([self countConversationsOnClient:testClient1] == 1);
}


-(void)testEnumerateConversaionsOnRendezvous {
    [self buildStack2];
    XCTAssert([self countConversationsOnRendezvous:rendezvous1] == 1);
    
    XCTAssert([conversation1 authTrafficLight] == QREDO_RED);
    __block XCTestExpectation *fp = [self expectationWithDescription:@"fingerprint"];
    
    [conversation1 iHaveRemoteFingerPrint:^(NSError *error) {
        XCTAssertNil(error);
        [fp fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     fp = nil;
                                 }];
    XCTAssert([self countConversationsOnRendezvous:rendezvous1] == 1);
    
    
    __block QredoConversationMetadata *updatedMetaData;
    __block XCTestExpectation *fp2 = [self expectationWithDescription:@"fingerprint"];
    [rendezvous1 enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        updatedMetaData = conversationMetadata;
    }
                               completionHandler:^(NSError *error) {
                                   [fp2 fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     fp2 = nil;
                                 }];
    
    
    
    __block XCTestExpectation *fp3 = [self expectationWithDescription:@"fingerprint"];
    [testClient1 fetchConversationWithRef:updatedMetaData.conversationRef
                        completionHandler:^(QredoConversation *conversation,NSError *error) {
                            XCTAssert([conversation authTrafficLight] == QREDO_AMBER);
                            [fp3 fulfill];
                        }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     fp3 = nil;
                                 }];
    
    
    NSLog(@"here");
}


-(void)authoriseClient {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:[self randomUsername]
                          userSecret:[self randomPassword]
                             options:[self clientOptions:YES]
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       client = clientArg;
                       [clientExpectation fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    XCTAssertNotNil(client);
    XCTAssertNotNil(client.systemVault);
    XCTAssertNotNil(client.systemVault.vaultId);
    
    //NSLog(@"Client1 system Vault %@",client.systemVault.vaultId);
    //NSLog(@"Client1 default Vault %@",client.defaultVault.vaultId);
}


-(void)authoriseAnotherClient {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:[self randomUsername]
                          userSecret:[self randomPassword]
                             options:[self clientOptions:YES]
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       anotherClient = clientArg;
                       [clientExpectation fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    XCTAssertNotNil(anotherClient);
    XCTAssertNotNil(anotherClient.systemVault);
    XCTAssertNotNil(anotherClient.systemVault.vaultId);
    
    //NSLog(@"Another Client default Vault %@",anotherClient.defaultVault.vaultId);
}


-(void)closeClientSessions {
    [client closeSession];
    [anotherClient closeSession];
}


-(void)testConversationCreation {
    __block QredoRendezvous *rendezvous = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    [client createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:600
                              unlimitedResponses:NO
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *_rendezvous,NSError *error) {
                                   QLog(@"Create rendezvous completion handler called.");
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(_rendezvous);
                                   
                                   rendezvous = _rendezvous;
                                   
                                   [createExpectation fulfill];
                               }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     createExpectation = nil;
                                 }];
}


-(void)testRespondingToConversation {
    __block QredoRendezvous *rendezvous = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block NSString *randomTag = nil;
    
    
    QLog(@"\nCreating rendezvous");
    
    
    
    [client createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:600
                              unlimitedResponses:NO
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *_rendezvous,NSError *error) {
                                   QLog(@"\nRendezvous creation completion handler entered");
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(_rendezvous);
                                   rendezvous = _rendezvous;
                                   randomTag = _rendezvous.tag;
                                   
                                   
                                   [createExpectation fulfill];
                               }];
    QLog(@"\nWaiting for creation expectations");
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     createExpectation = nil;
                                 }];
    
    QLog(@"\nStarting listening");
    [rendezvous addRendezvousObserver:self];
    [NSThread sleepForTimeInterval:delayInterval];
    
    XCTAssertNotNil(anotherClient);
    
    //Responding to the rendezvous
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    self.didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    __block QredoConversation *responderConversation = nil;
    QLog(@"\n2nd client responding to rendezvous");
    //Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    [anotherClient respondWithTag:randomTag
                completionHandler:^(QredoConversation *conversation,NSError *error) {
                    QLog(@"\nRendezvous respond completion handler entered");
                    XCTAssertNil(error);
                    XCTAssertNotNil(conversation);
                    
                    responderConversation = conversation;
                    QLog(@"Responder conversation ID: %@",conversation.metadata.conversationId);
                    
                    [didRespondExpectation fulfill];
                }];
    
    QLog(@"\nWaiting for responding expectations");
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     didRespondExpectation = nil;
                                 }];
    
    QLog(@"\nStopping listening");
    [client closeSession];
}


-(QredoRendezvous *)isolateCreateRendezvous {
    __block QredoRendezvous *rendezvous = nil;
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block NSString *randomTag = nil;
    
    QredoLogDebug(@"Creating Rendezvous (with client 1)");
    
    [client createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:3600
                              unlimitedResponses:YES
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *_rendezvous,NSError *error) {
                                   QredoLogDebug(@"Create rendezvous completion handler called.");
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(_rendezvous);
                                   randomTag = rendezvous.tag;
                                   rendezvous = _rendezvous;
                                   
                                   [createExpectation fulfill];
                               }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     createExpectation = nil;
                                 }];
    QredoLogDebug(@"Starting listening for rendezvous");
    return rendezvous;
}


-(QredoConversation *)isolateRespondToRendezvous:(NSString *)randomTag rendezvous:(QredoRendezvous *)rendezvous {
    //Responding to the rendezvous
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    
    self.didReceiveResponseExpectation = didRespondExpectation;//[self expectationWithDescription:@"received response in the creator's delegate"];
    
    QredoLogDebug(@"Responding to Rendezvous");
    __block QredoConversation *responderConversation = nil;
    //Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    
    [anotherClient respondWithTag:randomTag
                completionHandler:^(QredoConversation *conversation,NSError *error) {
                    XCTAssertNil(error);
                    XCTAssertNotNil(conversation);
                    responderConversation = conversation;
                    QredoLogDebug(@"Responder conversation ID: %@",conversation.metadata.conversationId);
                    [didRespondExpectation fulfill];
                }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     didRespondExpectation = nil;
                                     self.didReceiveResponseExpectation = nil;
                                     
                                     if (error){
                                         QredoLogError(@"Failed and retrying %@",error);
                                     }
                                 }];
    return responderConversation;
}


NSString *firstMessageText;
NSString *secondMessageText;
-(QredoConversationHighWatermark *)isolatePublishMessage1:(ConversationMessageListener *)listener responderConversation:(QredoConversation *)responderConversation {
    __block XCTestExpectation *didPublishMessageExpectation = [self expectationWithDescription:@"published 1 message before listener started"];
    
    self.didReceiveMessageExpectation = didPublishMessageExpectation;//[self expectationWithDescription:@"received 1 message published before listening"];
    
    QredoConversationMessage *firstMessage = [[QredoConversationMessage alloc] initWithValue:[firstMessageText dataUsingEncoding:NSUTF8StringEncoding]
                                                                                    dataType:kMessageType
                                                                               summaryValues:nil];
    listener.listening = YES;
    __block QredoConversationHighWatermark *hwm = nil;
    
    
    [NSThread sleepForTimeInterval:5];
    
    [responderConversation publishMessage:firstMessage
                        completionHandler:^(QredoConversationHighWatermark *messageHighWatermark,NSError *error) {
                            QredoLogDebug(@"Publish message (before setting up listener) completion handler called.");
                            XCTAssertNil(error);
                            XCTAssertNotNil(messageHighWatermark);
                            [didPublishMessageExpectation fulfill];
                            hwm = messageHighWatermark;
                        }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     didPublishMessageExpectation = nil;
                                     
                                     @synchronized(listener) {
                                         listener.listening = NO;
                                     }
                                     
                                     self.didReceiveMessageExpectation = nil;
                                     QredoLogDebug(@"PASSED: firstMessageListener: %@",listener);
                                 }];
    return hwm;
}


-(QredoConversationHighWatermark *)isolatePublishMessage2:(ConversationMessageListener *)listener responderConversation:(QredoConversation *)responderConversation {
    QredoConversationMessage *secondMessage = [[QredoConversationMessage alloc] initWithValue:[secondMessageText dataUsingEncoding:NSUTF8StringEncoding] dataType:kMessageType summaryValues:nil];
    
    //__block XCTestExpectation *didPublishMessageExpectation2 = [self expectationWithDescription:@"published a message after listener started"];
    listener.listening = YES;
    __block QredoConversationHighWatermark *hwm = nil;
    [NSThread sleepForTimeInterval:delayInterval];
    
    [responderConversation publishMessage:secondMessage
                        completionHandler:^(QredoConversationHighWatermark *messageHighWatermark,NSError *error) {
                            QredoLogDebug(@"Publish message (after listening started) completion handler called.");
                            XCTAssertNil(error);
                            XCTAssertNotNil(messageHighWatermark);
                            QredoLogDebug(@"Message 2 published. %@",messageHighWatermark);
                            //[didPublishMessageExpectation2 fulfill];
                            [self.didReceiveMessageExpectation fulfill];
                            hwm = messageHighWatermark;
                        }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     if (error){
                                         NSLog(@"error");
                                     }
                                     
                                     //didPublishMessageExpectation2 = nil;
                                     
                                     @synchronized(listener) {
                                         listener.listening = NO;
                                     }
                                     self.didReceiveMessageExpectation = nil;
                                     QredoLogDebug(@"PASSED: second: %@, ",listener);
                                 }];
    return hwm;
}



//This is part of Control messages and has been disabled
/*
-(void)testOtherPartyHasLeft {
    [self buildStack1];
    
    __block XCTestExpectation *deletdConv = [self expectationWithDescription:@"Delet 1st conversation"];
    
    
    
    [testClient1 deleteConversationWithRef:conversation1.metadata.conversationRef
                         completionHandler:^(NSError *error) {
                             XCTAssertNil(error);
                             [deletdConv fulfill];
                         }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     deletdConv = nil;
                                 }];
    
    
    ConversationMessageListener *deleteListener = [[ConversationMessageListener alloc] init];
    self.didRecieveOtherPartyHasLeft = [self expectationWithDescription:@"wait to be notified of other party has left"];
    deleteListener.expectedMessageValue = @"Message";
    deleteListener.test = self;
    deleteListener.listening = YES;
    [conversation2 addConversationObserver:deleteListener];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];
}
*/


-(void)testConversationWatermark {
    //static NSString *randomTag;
    float delayInterval = 5.0;
    
    
    
    
    
    firstMessageText =  [NSString stringWithFormat:@"Text: %@. Timestamp: %@",kMessageTestValue,[QredoNetworkTime dateTime]];
    secondMessageText = [NSString stringWithFormat:@"Text: %@. Timestamp: %@",kMessageTestValue2,[QredoNetworkTime dateTime]];
    rvuFulfilledTimes = 0;
    self.didReceiveResponseExpectation = nil;
    
    //NSLog(@"TAG %@",randomTag);
    
    //register listener
    ConversationMessageListener *listener = [[ConversationMessageListener alloc] init];
    listener.expectedMessageValue = firstMessageText;
    listener.test = self;
    
    
    //Create Rendezvous
    [NSThread sleepForTimeInterval:delayInterval];
    
    //static QredoRendezvous *rendezvous;
    QredoRendezvous *rendezvous = [self isolateCreateRendezvous];
    [rendezvous addRendezvousObserver:self];
    
    NSString *randomTag = rendezvous.tag;
    
    //this is a fix so the observer registers before the rendezvous is responded to.
    [NSThread sleepForTimeInterval:delayInterval];
    
    
    //Respond to Rendezvous
    QredoConversation *responderConversation = [self isolateRespondToRendezvous:randomTag rendezvous:rendezvous];
    
    [creatorConversation addConversationObserver:listener];
    [NSThread sleepForTimeInterval:delayInterval];
    
    //Response to Rendezvous
    QredoConversationHighWatermark *hwm1 = [self isolatePublishMessage1:listener responderConversation:responderConversation];
    
    
    self.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message published after listening"];
    
    listener.expectedMessageValue = secondMessageText;
    
    QredoConversationHighWatermark *hwm2 = [self isolatePublishMessage2:listener responderConversation:responderConversation];
    
    
    
    //////SETUP COMPLETE -
    //how many messages from beginning
    int messageCount = [self countMessagesOnConversation:responderConversation since:QredoConversationHighWatermarkOrigin];
    XCTAssert(messageCount == 2,@"Should have 2 Has %i",messageCount);
    
    //how many messages since 1st message
    messageCount = [self countMessagesOnConversation:responderConversation since:hwm1];
    XCTAssert(messageCount == 1,@"Should have 1 Has %i",messageCount);
    
    //how many messages since 2nd message
    messageCount = [self countMessagesOnConversation:responderConversation since:hwm2];
    XCTAssert(messageCount == 0,@"Should have 0 Has %i",messageCount);
    
    [creatorConversation removeConversationObserver:listener];
    [rendezvous removeRendezvousObserver:self];
    [client closeSession];
}


-(int)countMessagesOnConversation:(QredoConversation *)conversation since:(QredoConversationHighWatermark *)hwm {
    __block int messageCount = 0;
    __block XCTestExpectation *scanMsgExpectation = [self expectationWithDescription:@"scanMsgExpectation"];
    
    [conversation enumerateSentMessagesUsingBlock:^(QredoConversationMessage *message,BOOL *stop) {
        messageCount++;
    }
                                            since:hwm
                                completionHandler:^(NSError *error) {
                                    [scanMsgExpectation fulfill];
                                }];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     if (error) QredoLogError(@"Critical error waiting for messageCount1 expectation");
                                 }];
    return messageCount;
}


-(void)testConversation {
    //static NSString *randomTag;
    NSString *randomTag = nil;
    
    if (!randomTag)randomTag = [[QredoQUID QUID] QUIDString];
    
    firstMessageText =  [NSString stringWithFormat:@"Text: %@. Timestamp: %@",kMessageTestValue,[QredoNetworkTime dateTime]];
    secondMessageText = [NSString stringWithFormat:@"Text: %@. Timestamp: %@",kMessageTestValue2,[QredoNetworkTime dateTime]];
    rvuFulfilledTimes = 0;
    self.didReceiveResponseExpectation = nil;
    
    //NSLog(@"TAG %@",randomTag);
    
    //register listener
    ConversationMessageListener *listener = [[ConversationMessageListener alloc] init];
    listener.expectedMessageValue = firstMessageText;
    listener.test = self;
    
    
    //Create Rendezvous
    [NSThread sleepForTimeInterval:delayInterval];
    
    //static QredoRendezvous *rendezvous;
    QredoRendezvous *rendezvous = nil;
    
    if (!rendezvous){
        rendezvous = [self isolateCreateRendezvous];
        [rendezvous addRendezvousObserver:self];
        randomTag = rendezvous.tag;
    }
    
    //this is a fix so the observer registers before the rendezvous is responded to.
    [NSThread sleepForTimeInterval:delayInterval];
    
    
    //Respond to Rendezvous
    QredoConversation *responderConversation = [self isolateRespondToRendezvous:randomTag rendezvous:rendezvous];
    
    [creatorConversation addConversationObserver:listener];
    [NSThread sleepForTimeInterval:delayInterval];
    
    //Response to Rendezvous
    [self isolatePublishMessage1:listener responderConversation:responderConversation];
    
    
    self.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message published after listening"];
    
    listener.expectedMessageValue = secondMessageText;
    
    [self isolatePublishMessage2:listener responderConversation:responderConversation];
    
    [rendezvous removeRendezvousObserver:self];
    [creatorConversation removeConversationObserver:listener];
    listener = nil;
}


//Rendezvous Delegate
-(void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation {
    @synchronized(self) {
        QLog(@"fulfilling rendezvous: %@",self.didReceiveResponseExpectation);
        
        if (self.didReceiveResponseExpectation){
            creatorConversation = conversation;
            [self.didReceiveResponseExpectation fulfill];
            QLog(@"really fullfilling rvu");
        }
        
        rvuFulfilledTimes = @(rvuFulfilledTimes.intValue + 1);
        QLog(@"CALLS TO FULFILL RVU: %d",rvuFulfilledTimes.intValue);
    }
}


-(void)testConversationListenerReturnsSummaryValues {
    //this is to test if after an update using
    //conversation updateConversationWithSummaryValues
    //the conversation returned using
    //-(void)qredoRendezvous:(QredoRendezvous*)rendezvous  didReceiveReponse:(QredoConversation *)conversation
    //contains those summary values (as previously it has been creating a new conversation object in the value in error)
    
    [self createClients];
    [self createRendezvous];
    //[self respondToRendezvous];
    
    //Listening for responses and respond from another client
    TestRendezvousListener *listener = [[TestRendezvousListener alloc] init];
    XCTAssertNotNil(rendezvous1);
    
    [rendezvous1 addRendezvousObserver:listener];
    [NSThread sleepForTimeInterval:0.1];
    
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    [NSThread sleepForTimeInterval:0.1];
    
    
    [testClient2 respondWithTag:rendezvous1Tag
              completionHandler:^(QredoConversation *conversation,NSError *error) {
                  XCTAssertNil(error);
                  conversation2 = conversation;
              }];
    
    
    //wait for the 1st client to receive the rendezvous
    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *error) {
                                     listener.expectation = nil;
                                 }];
    
    conversation1 = listener.incomingConversation;
    
    
    
    //[rendezvous1 removeRendezvousObserver:listener];
    //XCTAssertNotNil(conversation1);
    //XCTAssertNotNil(conversation2);
    //
    //
    //
    //
    //
    //
    //__block XCTestExpectation *rendezvousConversationIncoming = [self expectationWithDescription:@"waiting for incoming conversation"];
    //TestRendezvousListener *trl = [[TestRendezvousListener alloc] init];
    //trl.expectation = rendezvousConversationIncoming;
    //[rendezvous1 addRendezvousObserver:trl];
    //
    //
    //QredoConversation *conversation = conversation1;
    //NSDictionary *summaryValues = conversation.metadata.summaryValues;
    //XCTAssert(summaryValues==nil,@"Summary values should be nil");
    //
    //
    ////update 1
    //NSDictionary *testDictionary1 =  @{ @"testKey" : @"testValue" };
    //__block XCTestExpectation *didRespondExpectation1 = [self expectationWithDescription:@"update conversation"];
    //
    //[conversation updateConversationWithSummaryValues:testDictionary1 completionHandler:^(NSError *error) {
    //NSLog(@"Conversation1 %@", conversation.metadata.conversationRef);
    //NSLog(@"Conversation1 %@", conversation.metadata.summaryValues);
    //XCTAssertNil(summaryValues,@"Summary values should be nil");
    //[didRespondExpectation1 fulfill];
    //}];
    //[self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
    //didRespondExpectation1 = nil;
    //}];
    //
    //NSString *expected = [conversation.metadata.summaryValues objectForKey:@"testKey"];
    //
    //XCTAssertTrue([expected isEqualToString:@"testValue"],@"Incorrect summary value");
    //QredoConversationRef *ref1 = conversation.metadata.conversationRef;
    //
    /////test listener
    
    
    
    //
    //[self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
    //rendezvousConversationIncoming = nil;
    //}];
}


-(void)testUpdatedConversationSummaryValues {
    [self buildStack1];
    QredoConversation *conversation = conversation1;
    
    NSDictionary *summaryValues = conversation.metadata.summaryValues;
    
    
    XCTAssert(summaryValues == nil,@"Summary values should be nil");
    
    
    //update 1
    NSDictionary *testDictionary1 =  @{ @"testKey":@"testValue" };
    __block XCTestExpectation *didRespondExpectation1 = [self expectationWithDescription:@"update conversation"];
    [conversation updateConversationWithSummaryValues:testDictionary1
                                    completionHandler:^(NSError *error) {
                                        XCTAssertNil(summaryValues,@"Summary values should be nil");
                                        [didRespondExpectation1 fulfill];
                                    }];
    [self waitForExpectationsWithTimeout:10.0
                                 handler:^(NSError *error) {
                                     didRespondExpectation1 = nil;
                                 }];
    QredoConversationRef *ref1 = conversation.metadata.conversationRef;
    
    
    //update 2
    NSDictionary *testDictionary2 =  conversation.metadata.summaryValues;
    __block XCTestExpectation *didRespondExpectation2 = [self expectationWithDescription:@"update conversation"];
    [conversation updateConversationWithSummaryValues:testDictionary2
                                    completionHandler:^(NSError *error) {
                                        XCTAssertNil(summaryValues,@"Summary values should be nil");
                                        [didRespondExpectation2 fulfill];
                                    }];
    [self waitForExpectationsWithTimeout:10.0
                                 handler:^(NSError *error) {
                                     didRespondExpectation2 = nil;
                                 }];
    QredoConversationRef *ref2 = conversation.metadata.conversationRef;
    
    
    //update 3
    NSDictionary *testDictionary3 =  conversation.metadata.summaryValues;
    __block XCTestExpectation *didRespondExpectation3 = [self expectationWithDescription:@"update conversation"];
    [conversation updateConversationWithSummaryValues:testDictionary3
                                    completionHandler:^(NSError *error) {
                                        
                                        XCTAssertNil(summaryValues,@"Summary values should be nil");
                                        [didRespondExpectation3 fulfill];
                                    }];
    [self waitForExpectationsWithTimeout:10.0
                                 handler:^(NSError *error) {
                                     didRespondExpectation3 = nil;
                                 }];
    QredoConversationRef *ref3 = conversation.metadata.conversationRef;
    
    
    
    
    
    //now retrieve that conversation again from the vault
    __block XCTestExpectation *didCheckConversation = [self expectationWithDescription:@"retrieve conversation"];
    
    [testClient1 fetchConversationWithRef:ref3
                        completionHandler:^(QredoConversation *conversation,NSError *error) {
                            NSDictionary *summaryValues = conversation.metadata.summaryValues;
                            XCTAssertNotNil(summaryValues,@"Updated summary values should not be nil");
                            XCTAssert([[summaryValues objectForKey:@"testKey"] isEqualToString:@"testValue"],@"Value doesnt exist in updated conversation");
                            XCTAssert(![[summaryValues objectForKey:@"junkValue"] isEqualToString:@"junkValue"],@"Value shouldn't exist");
                            [didCheckConversation fulfill];
                        }];
    
    [self waitForExpectationsWithTimeout:30.0
                                 handler:^(NSError *error) {
                                     didCheckConversation = nil;
                                 }];
    
    
    __block int count = 0;
    
    //count number of conversation items
    __block XCTestExpectation *itemCountExpectation = [self expectationWithDescription:@"item count"];
    
    [testClient1 enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        count++;
    }
                               completionHandler:^(NSError *error) {
                                   [itemCountExpectation fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:10.0
                                 handler:^(NSError *error) {
                                     itemCountExpectation = nil;
                                 }];
    
    
    XCTAssert(count == 1,@"More than one conversation item retrieved");
}


@end
