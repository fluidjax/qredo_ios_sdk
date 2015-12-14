/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoTestUtils.h"

#import "QredoPrivate.h"
#import "ConversationTests.h"

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

- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message
{
    // Can't use XCTAsset, because this class is not XCTestCase
    
    @synchronized(_test) {
        NSLog(@"qredoConversation:didReceiveNewMessage:");
        
        if (_listening) {
            self.failed |= (message == nil);
            self.failed |= !([message.value isEqualToData:[self.expectedMessageValue dataUsingEncoding:NSUTF8StringEncoding]]);
            
            self.failed |= !([message.dataType isEqualToString:kMessageType]);
            
            NSLog(@"fulfilling self: %@, self.didReceiveMessageExpectiation: %@", self, _test.didReceiveMessageExpectation);
            
            _fulfilledtime = @(_fulfilledtime.intValue + 1);
            NSLog(@"CALLS TO FULFILL: %d", _fulfilledtime.intValue);
            
            if (_test.didReceiveMessageExpectation) {
                //        dispatch_barrier_sync(dispatch_get_main_queue(), ^{
                NSLog(@"really fullfilling");
                [_test.didReceiveMessageExpectation fulfill];
                //        });
                _listening = NO;
            }
        }
    }
}

@end

@interface ConversationTests() <QredoRendezvousObserver>
{
    QredoClient *client;
    NSNumber *rvuFulfilledTimes;
    QredoConversation *creatorConversation;

}

@property NSString *conversationType;
@end

@implementation ConversationTests

- (void)setUp {
    [super setUp];
    self.conversationType = @"test.chat~";
    [self authoriseClient];
}

-(void)tearDown {
    [super tearDown];
    if (client) {
        [client closeSession];
    }
}

- (QredoClientOptions *)clientOptions:(BOOL)resetData
{
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.transportType = self.transportType;
    return clientOptions;
}

- (void)authoriseClient
{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppSecret:k_APPSECRET
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
}

- (void)testConversationCreation {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:self.conversationType durationSeconds:@600 isUnlimitedResponseCount:NO];
    
    __block QredoRendezvous *rendezvous = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                               NSLog(@"Create rendezvous completion handler called.");
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

- (void)testRespondingToConversation
{
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:self.conversationType durationSeconds:@600 isUnlimitedResponseCount:NO];
    
    __block QredoRendezvous *rendezvous = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    NSLog(@"\nCreating rendezvous");
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                               NSLog(@"\nRendezvous creation completion handler entered");
                               XCTAssertNil(error);
                               XCTAssertNotNil(_rendezvous);
                               
                               rendezvous = _rendezvous;
                               
                               [createExpectation fulfill];
                           }];
    NSLog(@"\nWaiting for creation expectations");
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        createExpectation = nil;
    }];

    NSLog(@"\nStarting listening");
    [rendezvous addRendezvousObserver:self];
    
    // another client with a new vault
    NSLog(@"\nCreating 2nd client");
    __block QredoClient *anotherClient = nil;
    __block XCTestExpectation *anotherClientExpectation = [self expectationWithDescription:@"create a new client"];
    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:[QredoTestUtils randomPassword]
                                 options:[self clientOptions:YES]
                       completionHandler:^(QredoClient *newClient, NSError *error) {
                                  XCTAssertNotNil(newClient);
                                  XCTAssertNil(error);
                                  anotherClient = newClient;
                                  [anotherClientExpectation fulfill];
                              }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        anotherClientExpectation = nil;
    }];
    
    XCTAssertNotNil(anotherClient);
    
    // Responding to the rendezvous
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    self.didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    __block QredoConversation *responderConversation = nil;
    NSLog(@"\n2nd client responding to rendezvous");
    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    [anotherClient respondWithTag:randomTag
                  trustedRootPems:nil
                          crlPems:nil
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        NSLog(@"\nRendezvous respond completion handler entered");
        XCTAssertNil(error);
        XCTAssertNotNil(conversation);
        
        responderConversation = conversation;
        NSLog(@"Responder conversation ID: %@", conversation.metadata.conversationId);
        
        [didRespondExpectation fulfill];
    }];
    
    NSLog(@"\nWaiting for responding expectations");
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didRespondExpectation = nil;
    }];

    NSLog(@"\nStopping listening");
    [rendezvous removeRendezvousObserver:self];

    [anotherClient closeSession];
}

- (void)testConversation
{
    rvuFulfilledTimes = 0;
    self.didReceiveResponseExpectation = nil;
    
    client = nil;
    [self authoriseClient];
    
    NSString *randomTag = [[QredoQUID QUID] QUIDString];

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"test.chat~" durationSeconds:@600 isUnlimitedResponseCount:NO];

    __block QredoRendezvous *rendezvous = nil;

    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];

    NSLog(@"Creating Rendezvous (with client 1)");
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                               NSLog(@"Create rendezvous completion handler called.");
                               XCTAssertNil(error);
                               XCTAssertNotNil(_rendezvous);
                               
                               rendezvous = _rendezvous;
                               
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        createExpectation = nil;
    }];
    
    NSLog(@"Starting listening for rendezvous");
    
    [rendezvous addRendezvousObserver:self];
    
//    usleep(100000);

    // Creating a new client with a new vault
    __block QredoClient *anotherClient = nil;
    __block XCTestExpectation *anotherClientExpectation = [self expectationWithDescription:@"create a new client"];

    NSLog(@"Creating client 2");
    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:[QredoTestUtils randomPassword]
                                 options:[self clientOptions:YES]
                       completionHandler:^(QredoClient *newClient, NSError *error) {
                                  XCTAssertNotNil(newClient);
                                  XCTAssertNil(error);
                                  anotherClient = newClient;
                                  [anotherClientExpectation fulfill];
                              }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        anotherClientExpectation = nil;
    }];


    XCTAssertFalse([anotherClient.systemVault.vaultId isEqual:client.systemVault.vaultId]);
    
//    usleep(1500000); // original fix
//    usleep(1000000);

    // Responding to the rendezvous
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    self.didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
//    rendezvous
    
    NSLog(@"Responding to Rendezvous");
    __block QredoConversation *responderConversation = nil;
    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    [anotherClient respondWithTag:randomTag
                  trustedRootPems:nil
                          crlPems:nil
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(conversation);

        responderConversation = conversation;
        NSLog(@"Responder conversation ID: %@", conversation.metadata.conversationId);

        [didRespondExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didRespondExpectation = nil;
        self.didReceiveResponseExpectation = nil;
    }];

    NSLog(@"Stopping listening for rendezvous");
    [rendezvous removeRendezvousObserver:self];
    
    // Sending message
    XCTAssertNotNil(responderConversation);

    NSLog(@"Creator conversation ID: %@", creatorConversation.metadata.conversationId);

    NSString *firstMessageText = [NSString stringWithFormat:@"Text: %@. Timestamp: %@", kMessageTestValue, [NSDate date]];
    
    NSLog(@"Setting up listener");
    ConversationMessageListener *listener = [[ConversationMessageListener alloc] init];
    listener.expectedMessageValue = firstMessageText;
    listener.test = self;

    NSLog(@"Starting listening for conversation items");
    [creatorConversation addConversationObserver:listener];
    
//    usleep(1500000); // original fix
    
    __block XCTestExpectation *didPublishMessageExpectation = [self expectationWithDescription:@"published 1 message before listener started"];
    self.didReceiveMessageExpectation = [self expectationWithDescription:@"received 1 message published before listening"];
    
    QredoConversationMessage *firstMessage = [[QredoConversationMessage alloc] initWithValue:[firstMessageText dataUsingEncoding:NSUTF8StringEncoding]
                                                                                  dataType:kMessageType
                                                                             summaryValues:nil];

    listener.listening = YES;
    NSLog(@"Publishing message (before setting up listener). Message: %@", firstMessageText);
    [responderConversation publishMessage:firstMessage
                        completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                            NSLog(@"Publish message (before setting up listener) completion handler called.");
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
        NSLog(@"PASSED: firstMessageListener: %@", listener);
    }];
    

    
    XCTAssertFalse(listener.failed);
    
    @synchronized(self) {
        self.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message published after listening"];    
    }

    NSLog(@"Setting up listener expectations again");
    NSString *secondMessageText = [NSString stringWithFormat:@"Text: %@. Timestamp: %@", kMessageTestValue2, [NSDate date]];
    listener.expectedMessageValue = secondMessageText;
    
    QredoConversationMessage *secondMessage = [[QredoConversationMessage alloc] initWithValue:[secondMessageText dataUsingEncoding:NSUTF8StringEncoding] dataType:kMessageType summaryValues:nil];
    didPublishMessageExpectation = [self expectationWithDescription:@"published a message after listener started"];
    
    listener.listening = YES;
    NSLog(@"Publishing second message (after listening started). Message: %@", secondMessageText);
    
//    usleep(1000000);
    
    [responderConversation publishMessage:secondMessage
                        completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                            NSLog(@"Publish message (after listening started) completion handler called.");
                            XCTAssertNil(error);
                            XCTAssertNotNil(messageHighWatermark);
                            NSLog(@"Message 2 published. %@", messageHighWatermark);
                            [didPublishMessageExpectation fulfill];
                        }];
    
    [self waitForExpectationsWithTimeout:400 handler:^(NSError *error) {
        didPublishMessageExpectation = nil;
        
        @synchronized(listener) {
            listener.listening = NO;
        }
            self.didReceiveMessageExpectation = nil;
            NSLog(@"PASSED: second: %@, ", listener);
    }];
        
    NSLog(@"Stopping listening for conversation items");
    [creatorConversation removeConversationObserver:listener];
    listener = nil;
    
    [anotherClient closeSession];
    anotherClient = nil;

    [client closeSession];
    client = nil;
    
//    XCTAssert([responderConversation.metadata.conversationId isEqual:creatorConversation.metadata.conversationId],
//              @"Conversation ID from responder and creator should be the same");
//
//    // Enumerating conversations
//    __block XCTestExpectation *didFindConversation = [self expectationWithDescription:@"find conversation in system vault"];
//    __block QredoConversationMetadata *metadataFromEnumeration = nil;
//    [client enumerateConversationsWithBlock:^(QredoConversationMetadata *metadata, BOOL *stop) {
//        if ([metadata.conversationId isEqual:responderConversation.metadata.conversationId]) {
//            metadataFromEnumeration = metadata;
//            *stop = YES;
//
//        }
//    } completionHandler:^(NSError *error) {
//        XCTAssertNil(error);
//        [didFindConversation fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        didFindConversation = nil;
//    }];
//
//    XCTAssertNotNil(metadataFromEnumeration);
//    XCTAssert([metadataFromEnumeration.rendezvousTag isEqual:randomTag]);
//
//    // Fetching conversation
//    __block XCTestExpectation *didFetchConversation = [self expectationWithDescription:@"fetch conversation from system vault"];
//
//    __block QredoConversation *conversatoinFromVault = nil;
//    [client fetchConversationWithRef:metadataFromEnumeration.conversationRef completionHandler:^(QredoConversation *conversation, NSError *error) {
//        XCTAssertNil(error);
//        XCTAssertNotNil(conversation);
//        conversatoinFromVault = conversation;
//
//        [didFetchConversation fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        didFetchConversation = nil;
//    }];
//
//    XCTAssertNotNil(conversatoinFromVault);
//    XCTAssert([conversatoinFromVault.metadata.rendezvousTag isEqualToString:randomTag], @"Rendezvous tag should be the same");
//    XCTAssert([conversatoinFromVault.metadata.type isEqualToString:configuration.conversationType], @"Conversation type should be the same");
//
//    // Making sure that we can use the fetched conversation
//    __block XCTestExpectation *didPublishAnotherMessage = [self expectationWithDescription:@"did publish another message"];
//
//    ConversationMessageListener *anotherListener = [[ConversationMessageListener alloc] init];
//    anotherListener.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message"];
//    anotherListener.expectedMessageValue = kMessageTestValue2;
//    [responderConversation addConversationObserver:anotherListener];
//    
//    QredoConversationMessage *anotherMessage = [[QredoConversationMessage alloc] initWithValue:[kMessageTestValue2 dataUsingEncoding:NSUTF8StringEncoding] dataType:kMessageType summaryValues:nil];
//    [conversatoinFromVault publishMessage:anotherMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
//        XCTAssertNotNil(messageHighWatermark);
//        XCTAssertNil(error);
//
//        [didPublishAnotherMessage fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        didPublishAnotherMessage = nil;
//        anotherListener.didReceiveMessageExpectation = nil;
//    }];
////    XCTAssertFalse(listener.failed);
//
//    [responderConversation removeConversationObserver:anotherListener];

    XCTAssertFalse(listener.failed);
//    [anotherClient closeSession];
}

// Rendezvous Delegate
- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    @synchronized(self) {
        NSLog(@"fulfilling rendezvous: %@", self.didReceiveResponseExpectation);
        
        if (self.didReceiveResponseExpectation) {
            creatorConversation = conversation;
            [self.didReceiveResponseExpectation fulfill];
            NSLog(@"really fullfilling rvu");
        }
        
        rvuFulfilledTimes = @(rvuFulfilledTimes.intValue + 1);
        NSLog(@"CALLS TO FULFILL RVU: %d", rvuFulfilledTimes.intValue);
    }
}

- (void)testMetadataOfEphemeralConversation
{
    
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"test.chat~" durationSeconds:@600 isUnlimitedResponseCount:NO];
    
    __block QredoRendezvous *rendezvous = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(_rendezvous);
                               
                               rendezvous = _rendezvous;
                               
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];


    // Creating a new client with a new vault
    __block QredoClient *anotherClient = nil;
    __block XCTestExpectation *anotherClientExpectation = [self expectationWithDescription:@"create a new client"];

    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:[QredoTestUtils randomPassword]
                       completionHandler:^(QredoClient *newClient, NSError *error) {
                                  XCTAssertNotNil(newClient);
                                  XCTAssertNil(error);
                                  anotherClient = newClient;
                                  [anotherClientExpectation fulfill];
                              }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        anotherClientExpectation = nil;
    }];
    XCTAssertFalse([anotherClient.systemVault.vaultId isEqual:client.systemVault.vaultId]);

    
    // Responding to the rendezvous
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    self.didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    [rendezvous addRendezvousObserver:self];
    

    __block QredoConversation *responderConversation = nil;
    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    [anotherClient respondWithTag:randomTag
                  trustedRootPems:nil
                          crlPems:nil
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(conversation);
        XCTAssert(conversation.metadata.isEphemeral);
        XCTAssertFalse(conversation.metadata.isPersistent);
        
        responderConversation = conversation;
        
        [didRespondExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        didRespondExpectation = nil;
    }];
    
    [rendezvous removeRendezvousObserver:self];
    
    [anotherClient closeSession];
}

- (void)testMetadataOfPersistentConversation
{    
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"test.chat"
                                                                                                 durationSeconds:@600
                                                                                        isUnlimitedResponseCount:NO];

    __block QredoRendezvous *rendezvous = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(_rendezvous);
                               
                               rendezvous = _rendezvous;
                               
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];


    // Creating a new client with a new vault
    __block QredoClient *anotherClient = nil;
    __block XCTestExpectation *anotherClientExpectation = [self expectationWithDescription:@"create a new client"];

    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:[QredoTestUtils randomPassword]
                                 options:[self clientOptions:YES]
                       completionHandler:^(QredoClient *newClient, NSError *error) {
                                  XCTAssertNotNil(newClient);
                                  XCTAssertNil(error);
                                  anotherClient = newClient;
                                  [anotherClientExpectation fulfill];
                              }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        anotherClientExpectation = nil;
    }];
    XCTAssertFalse([anotherClient.systemVault.vaultId isEqual:client.systemVault.vaultId]);

    // Responding to the rendezvous
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    self.didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    [rendezvous addRendezvousObserver:self];
    
    __block QredoConversation *responderConversation = nil;
    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    [anotherClient respondWithTag:randomTag
                  trustedRootPems:nil
                          crlPems:nil
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(conversation);
        XCTAssertFalse(conversation.metadata.isEphemeral);
        XCTAssert(conversation.metadata.isPersistent);
        
        responderConversation = conversation;
        
        [didRespondExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        didRespondExpectation = nil;
    }];
    
    [rendezvous removeRendezvousObserver:self];
    
    [anotherClient closeSession];
}


@end
