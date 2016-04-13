/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoTestUtils.h"
#import "QredoPrivate.h"
#import "ConversationTests.h"
#import "QredoLoggerPrivate.h"
#import "Qredo.h"
#import "QredoPrivate.h"

// This test should has some commonalities with RendezvousListenerTests, however,
// the purpose of this test is to cover all edge cases in the conversations:
// - publish message
// - receiving message through callback
// - start/stop listening
// - resetHighwatermark
// - persisting highwatermark
// - releasing references after stopListening

static NSString *const kMessageType = @"com.qredo.text";
static NSString *const kMessageTestValue = @"(1)hello, world";
static NSString *const kMessageTestValue2 = @"(2)another hello, world";

@interface ConversationMessageListener : NSObject <QredoConversationObserver>

@property ConversationTests *test;
@property NSString *expectedMessageValue;
@property BOOL failed;
@property BOOL listening;
@property NSNumber *fulfilledtime;

@end

@implementation ConversationMessageListener

- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message{
    // Can't use XCTAsset, because this class is not QredoXCTestCase
    
    @synchronized(_test) {
        QLog(@"qredoConversation:didReceiveNewMessage:");
        
        if (_listening) {
            self.failed |= (message == nil);
            self.failed |= !([message.value isEqualToData:[self.expectedMessageValue dataUsingEncoding:NSUTF8StringEncoding]]);
            
            self.failed |= !([message.dataType isEqualToString:kMessageType]);
            
            QLog(@"fulfilling self: %@, self.didReceiveMessageExpectiation: %@", self, _test.didReceiveMessageExpectation);
            
            _fulfilledtime = @(_fulfilledtime.intValue + 1);
            QLog(@"CALLS TO FULFILL: %d", _fulfilledtime.intValue);
            
            if (_test.didReceiveMessageExpectation) {
                //        dispatch_barrier_sync(dispatch_get_main_queue(), ^{
                QLog(@"really fullfilling");
                [_test.didReceiveMessageExpectation fulfill];
                //        });
                _listening = NO;
            }
        }
    }
}

@end

@interface ConversationTests() <QredoRendezvousObserver>{
    QredoClient *client;
    QredoClient *anotherClient;
    NSNumber *rvuFulfilledTimes;
    QredoConversation *creatorConversation;

}


@end

@implementation ConversationTests

- (void)setUp {
    [super setUp];
    [self authoriseClient];
    [self authoriseAnotherClient];
}

-(void)tearDown {
    [super tearDown];
    if (client) {
        [client closeSession];
        [anotherClient closeSession];
    }
}

- (QredoClientOptions *)clientOptions:(BOOL)resetData{
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.transportType = self.transportType;
    return clientOptions;
}

- (void)authoriseClient{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:[QredoTestUtils randomPassword]
                             options:[self clientOptions:YES]
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  XCTAssertNil(error);
                                  XCTAssertNotNil(clientArg);
                                  client = clientArg;
                                  [clientExpectation fulfill];
                              }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    XCTAssertNotNil(client);
    XCTAssertNotNil(client.systemVault);
    XCTAssertNotNil(client.systemVault.vaultId);
    
    //NSLog(@"Client1 system Vault %@",client.systemVault.vaultId);
    //NSLog(@"Client1 default Vault %@",client.defaultVault.vaultId);

    
    
    
}

- (void)authoriseAnotherClient{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:[QredoTestUtils randomPassword]
                             options:[self clientOptions:YES]
                   completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           anotherClient = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    XCTAssertNotNil(anotherClient);
    XCTAssertNotNil(anotherClient.systemVault);
    XCTAssertNotNil(anotherClient.systemVault.vaultId);
    
    //NSLog(@"Another Client default Vault %@",anotherClient.defaultVault.vaultId);

    
}




- (void)testConversationCreation {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    __block QredoRendezvous *rendezvous = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    [client createAnonymousRendezvousWithTag:randomTag
                                    duration:600
                          unlimitedResponses:NO
                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                               QLog(@"Create rendezvous completion handler called.");
                               XCTAssertNil(error);
                               XCTAssertNotNil(_rendezvous);
                               
                               rendezvous = _rendezvous;
                               
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        createExpectation = nil;
    }];
}





- (void)testRespondingToConversation {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    
    __block QredoRendezvous *rendezvous = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    QLog(@"\nCreating rendezvous");
    
    
    
    [client createAnonymousRendezvousWithTag:randomTag
                                    duration:600
                          unlimitedResponses:NO
                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                               QLog(@"\nRendezvous creation completion handler entered");
                               XCTAssertNil(error);
                               XCTAssertNotNil(_rendezvous);
                               
                               rendezvous = _rendezvous;
                               
                               [createExpectation fulfill];
                           }];
    QLog(@"\nWaiting for creation expectations");
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        createExpectation = nil;
    }];

    QLog(@"\nStarting listening");
    [rendezvous addRendezvousObserver:self];
    [NSThread sleepForTimeInterval:0.2];
    
    XCTAssertNotNil(anotherClient);
    
    // Responding to the rendezvous
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    self.didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    __block QredoConversation *responderConversation = nil;
    QLog(@"\n2nd client responding to rendezvous");
    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    [anotherClient respondWithTag:randomTag
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        QLog(@"\nRendezvous respond completion handler entered");
        XCTAssertNil(error);
        XCTAssertNotNil(conversation);
        
        responderConversation = conversation;
        QLog(@"Responder conversation ID: %@", conversation.metadata.conversationId);
        
        [didRespondExpectation fulfill];
    }];
    
    QLog(@"\nWaiting for responding expectations");
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didRespondExpectation = nil;
    }];

    QLog(@"\nStopping listening");
    [rendezvous removeRendezvousObserver:self];

}






- (QredoRendezvous *)isolateCreateRendezvous:(NSString *)randomTag {
    
    __block QredoRendezvous *rendezvous = nil;
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    QredoLogDebug(@"Creating Rendezvous (with client 1)");
    
    [client createAnonymousRendezvousWithTag:randomTag
                                    duration:3600
                          unlimitedResponses:YES
                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                               QredoLogDebug(@"Create rendezvous completion handler called.");
                               XCTAssertNil(error);
                               XCTAssertNotNil(_rendezvous);
                               
                               rendezvous = _rendezvous;
                               
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        createExpectation = nil;
    }];
    QredoLogDebug(@"Starting listening for rendezvous");
    return rendezvous;
}

- (QredoConversation *)isolateRespondToRendezvous:(NSString *)randomTag rendezvous:(QredoRendezvous *)rendezvous{
    // Responding to the rendezvous
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    self.didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    QredoLogDebug(@"Responding to Rendezvous");
    __block QredoConversation *responderConversation = nil;
    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    
    [anotherClient respondWithTag:randomTag
                completionHandler:^(QredoConversation *conversation, NSError *error) {
                    XCTAssertNil(error);
                    XCTAssertNotNil(conversation);
                    responderConversation = conversation;
                    QredoLogDebug(@"Responder conversation ID: %@", conversation.metadata.conversationId);
                    [didRespondExpectation fulfill];
                }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didRespondExpectation = nil;
        self.didReceiveResponseExpectation = nil;
        if (error){
            QredoLogError(@"Failed and retrying %@", error);
        }
       
    }];
    return responderConversation;
}

NSString *firstMessageText;
NSString *secondMessageText;
- (void)isolatePublishMessage1:(ConversationMessageListener *)listener responderConversation:(QredoConversation *)responderConversation {
    __block XCTestExpectation *didPublishMessageExpectation = [self expectationWithDescription:@"published 1 message before listener started"];
    self.didReceiveMessageExpectation = [self expectationWithDescription:@"received 1 message published before listening"];
    
    QredoConversationMessage *firstMessage = [[QredoConversationMessage alloc] initWithValue:[firstMessageText dataUsingEncoding:NSUTF8StringEncoding]
                                                                                    dataType:kMessageType
                                                                               summaryValues:nil];
    listener.listening = YES;
    
    
    [responderConversation publishMessage:firstMessage
                        completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                            QredoLogDebug(@"Publish message (before setting up listener) completion handler called.");
                            XCTAssertNil(error);
                            XCTAssertNotNil(messageHighWatermark);
                            
                            [didPublishMessageExpectation fulfill];
                        }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didPublishMessageExpectation = nil;
        
        @synchronized(listener) {
            listener.listening = NO;
        }
        
        self.didReceiveMessageExpectation = nil;
        QredoLogDebug(@"PASSED: firstMessageListener: %@", listener);
    }];
}

- (void)isolatePublishMessage2:(ConversationMessageListener *)listener responderConversation:(QredoConversation *)responderConversation {
    QredoConversationMessage *secondMessage = [[QredoConversationMessage alloc] initWithValue:[secondMessageText dataUsingEncoding:NSUTF8StringEncoding] dataType:kMessageType summaryValues:nil];
    __block XCTestExpectation *didPublishMessageExpectation2 = [self expectationWithDescription:@"published a message after listener started"];
    
    listener.listening = YES;
    
    
    [responderConversation publishMessage:secondMessage
                        completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                            QredoLogDebug(@"Publish message (after listening started) completion handler called.");
                            XCTAssertNil(error);
                            XCTAssertNotNil(messageHighWatermark);
                            QredoLogDebug(@"Message 2 published. %@", messageHighWatermark);
                            [didPublishMessageExpectation2 fulfill];
                        }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        if (error){
            NSLog(@"error");
        }
        didPublishMessageExpectation2 = nil;
        
        @synchronized(listener) {
            listener.listening = NO;
        }
        self.didReceiveMessageExpectation = nil;
        QredoLogDebug(@"PASSED: second: %@, ", listener);
    }];
}




- (void)testConversation{
    [QredoLogger setLogLevel:0];
    
    //static NSString *randomTag;
    NSString *randomTag = nil;
    
    if (!randomTag)randomTag= [[QredoQUID QUID] QUIDString];
    
    firstMessageText =  [NSString stringWithFormat:@"Text: %@. Timestamp: %@", kMessageTestValue, [NSDate date]];
    secondMessageText = [NSString stringWithFormat:@"Text: %@. Timestamp: %@", kMessageTestValue2, [NSDate date]];
    rvuFulfilledTimes = 0;
    self.didReceiveResponseExpectation = nil;
    
   // NSLog(@"TAG %@",randomTag);
    
    //register listener
    ConversationMessageListener *listener = [[ConversationMessageListener alloc] init];
    listener.expectedMessageValue = firstMessageText;
    listener.test = self;
    
    
    //Create Rendezvous
    [NSThread sleepForTimeInterval:0.2];
    
    //static QredoRendezvous *rendezvous;
    QredoRendezvous *rendezvous=nil;
    if (!rendezvous){
        rendezvous= [self isolateCreateRendezvous:randomTag];
        [rendezvous addRendezvousObserver:self];
    }
    
    
    //this is a fix so the observer registers before the rendezvous is responded to.
    [NSThread sleepForTimeInterval:0.2];
    

    //Respond to Rendezvous
    QredoConversation *responderConversation = [self isolateRespondToRendezvous:randomTag rendezvous:rendezvous];
    
    [creatorConversation addConversationObserver:listener];
    [NSThread sleepForTimeInterval:0.2];
    
    //Response to Rendezvous
    [self isolatePublishMessage1:listener responderConversation:responderConversation];
    
    
    self.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message published after listening"];
    
    listener.expectedMessageValue = secondMessageText;
    
    [self isolatePublishMessage2:listener responderConversation:responderConversation];
    //    [creatorConversation removeConversationObserver:listener];
    listener = nil;
    
 }

// Rendezvous Delegate
- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didReceiveReponse:(QredoConversation *)conversation {
    @synchronized(self) {
        QLog(@"fulfilling rendezvous: %@", self.didReceiveResponseExpectation);
        
        if (self.didReceiveResponseExpectation) {
            creatorConversation = conversation;
            [self.didReceiveResponseExpectation fulfill];
            QLog(@"really fullfilling rvu");
        }
        
        rvuFulfilledTimes = @(rvuFulfilledTimes.intValue + 1);
        QLog(@"CALLS TO FULFILL RVU: %d", rvuFulfilledTimes.intValue);
    }
}

//- (void)testMetadataOfEphemeralConversation {
//    
//    NSString *randomTag = [[QredoQUID QUID] QUIDString];
//    
//    
//    __block QredoRendezvous *rendezvous = nil;
//    
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//    
//    
//    
//    [client createAnonymousRendezvousWithTag:randomTag
//                                    duration:600
//                          unlimitedResponses:NO
//                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
//                               XCTAssertNil(error);
//                               XCTAssertNotNil(_rendezvous);
//                               
//                               rendezvous = _rendezvous;
//                               
//                               [createExpectation fulfill];
//                           }];
//    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//
//
//    // Creating a new client with a new vault
//    XCTAssertFalse([anotherClient.systemVault.vaultId isEqual:client.systemVault.vaultId]);
//
//    
//    // Responding to the rendezvous
//    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
//    self.didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
//    
//    [rendezvous addRendezvousObserver:self];
//    [NSThread sleepForTimeInterval:0.2];
//
//    __block QredoConversation *responderConversation = nil;
//    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
//    [anotherClient respondWithTag:randomTag
//                completionHandler:^(QredoConversation *conversation, NSError *error) {
//        XCTAssertNil(error);
//        XCTAssertNotNil(conversation);
//        XCTAssert(conversation.metadata.isEphemeral);
//        XCTAssertFalse(conversation.metadata.isPersistent);
//        
//        responderConversation = conversation;
//        
//        [didRespondExpectation fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
//        didRespondExpectation = nil;
//    }];
//    
//    [rendezvous removeRendezvousObserver:self];
//    
//}
//
//- (void)testMetadataOfPersistentConversation {    
//    NSString *randomTag = [[QredoQUID QUID] QUIDString];
//    
//    __block QredoRendezvous *rendezvous = nil;
//    
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//    
//    [client createAnonymousRendezvousWithTag:randomTag
//                                    duration:600
//                          unlimitedResponses:NO
//                             completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
//                               XCTAssertNil(error);
//                               XCTAssertNotNil(_rendezvous);
//                               
//                               rendezvous = _rendezvous;
//                               
//                               [createExpectation fulfill];
//                           }];
//    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//
//
//   
//
//    // Responding to the rendezvous
//    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
//    self.didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
//    
//    [rendezvous addRendezvousObserver:self];
//    [NSThread sleepForTimeInterval:0.2];
//    
//    __block QredoConversation *responderConversation = nil;
//    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
//    [anotherClient respondWithTag:randomTag
//                completionHandler:^(QredoConversation *conversation, NSError *error) {
//        XCTAssertNil(error);
//        XCTAssertNotNil(conversation);
//        XCTAssertFalse(conversation.metadata.isEphemeral);
//        XCTAssert(conversation.metadata.isPersistent);
//        
//        responderConversation = conversation;
//        
//        [didRespondExpectation fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
//        didRespondExpectation = nil;
//    }];
//    
//    [rendezvous removeRendezvousObserver:self];
//    
//
//}
//

@end
