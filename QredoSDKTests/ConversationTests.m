/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoTestUtils.h"

#import "QredoPrivate.h"
#import "QredoVaultPrivate.h"
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

@interface ConversationMessageListener : NSObject <QredoConversationDelegate>
@property XCTestExpectation *didReceiveMessageExpectation;
@property NSString *expectedMessageValue;
@property BOOL failed;

@end

@implementation ConversationMessageListener

- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message
{
    NSLog(@"Received message: %@", [[NSString alloc] initWithData:message.value encoding:NSUTF8StringEncoding]);
    // Can't use XCTAsset, because this class is not XCTestCase

    self.failed |= (message == nil);
    self.failed |= !([message.value isEqualToData:[self.expectedMessageValue dataUsingEncoding:NSUTF8StringEncoding]]);

    self.failed |= !([message.dataType isEqualToString:kMessageType]);
    [self.didReceiveMessageExpectation fulfill];
}

@end

@interface ConversationTests() <QredoRendezvousDelegate>
{
    QredoClient *client;
    XCTestExpectation *didReceiveResponseExpectation;

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

- (QredoClientOptions *)clientOptionsWithResetData:(BOOL)resetData
{
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.transportType = self.transportType;
    clientOptions.resetData = resetData;
    
    return clientOptions;
}

- (void)authoriseClient
{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient authorizeWithConversationTypes:@[self.conversationType]
                                 vaultDataTypes:nil
                                        options:[self clientOptionsWithResetData:YES]
                              completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  XCTAssertNil(error);
                                  XCTAssertNotNil(clientArg);
                                  client = clientArg;
                                  NSLog(@"Authorize completion handler called.");
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
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:self.conversationType durationSeconds:@600 maxResponseCount:@1];
    
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
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:self.conversationType durationSeconds:@600 maxResponseCount:@1];
    
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

    rendezvous.delegate = self;
    
    NSLog(@"\nStarting listening");
    [rendezvous startListening];
    
    // another client with a new vault
    NSLog(@"\nCreating 2nd client");
    __block QredoClient *anotherClient = nil;
    __block XCTestExpectation *anotherClientExpectation = [self expectationWithDescription:@"create a new client"];
    [QredoClient authorizeWithConversationTypes:@[self.conversationType]
                                 vaultDataTypes:nil
                                        options:[self clientOptionsWithResetData:YES]
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
    didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
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
    [rendezvous stopListening];

    [anotherClient closeSession];
}

- (void)testConversation
{
    NSString *randomTag = [[QredoQUID QUID] QUIDString];

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"test.chat~" durationSeconds:@600 maxResponseCount:@1];

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

    // Creating a new client with a new vault
    __block QredoClient *anotherClient = nil;
    __block XCTestExpectation *anotherClientExpectation = [self expectationWithDescription:@"create a new client"];

    NSLog(@"Creating client 2");
    [QredoClient authorizeWithConversationTypes:@[self.conversationType]
                                 vaultDataTypes:nil
                                        options:[self clientOptionsWithResetData:YES]
                              completionHandler:^(QredoClient *newClient, NSError *error) {
                                  NSLog(@"Authorize client completion handler called");
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
    didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];

    rendezvous.delegate = self;

    NSLog(@"Starting listening for rendezvous");
    [rendezvous startListening];

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
    }];

    NSLog(@"Stopping listening for rendezvous");
    [rendezvous stopListening];
    
    // Sending message
    XCTAssertNotNil(responderConversation);

    NSLog(@"Creator conversation ID: %@", creatorConversation.metadata.conversationId);

    __block XCTestExpectation *didPublishMessageExpectation = [self expectationWithDescription:@"published a message before listener started"];

    NSString *firstMessageText = [NSString stringWithFormat:@"Text: %@. Timestamp: %@", kMessageTestValue, [NSDate date]];
    
    QredoConversationMessage *newMessage = [[QredoConversationMessage alloc] initWithValue:[firstMessageText dataUsingEncoding:NSUTF8StringEncoding]
                                                                                  dataType:kMessageType
                                                                             summaryValues:nil];

    NSLog(@"Publishing message (before setting up listener). Message: %@", firstMessageText);
    [responderConversation publishMessage:newMessage
                        completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                            NSLog(@"Publish message (before setting up listener) completion handler called.");
                            XCTAssertNil(error);
                            XCTAssertNotNil(messageHighWatermark);

                            [didPublishMessageExpectation fulfill];
                        }];

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didPublishMessageExpectation = nil;
    }];

    NSLog(@"Setting up listener");
    ConversationMessageListener *listener = [[ConversationMessageListener alloc] init];
    listener.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message published before listening"];
    listener.expectedMessageValue = firstMessageText;
    creatorConversation.delegate = listener;

    NSLog(@"Starting listening for conversation items");
    [creatorConversation startListening];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        listener.didReceiveMessageExpectation = nil;
    }];
    XCTAssertFalse(listener.failed);

    NSLog(@"Setting up listener expectations again");
    NSString *secondMessageText = [NSString stringWithFormat:@"Text: %@. Timestamp: %@", kMessageTestValue2, [NSDate date]];

    listener.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message published after listening"];
    listener.expectedMessageValue = secondMessageText;

    newMessage = [[QredoConversationMessage alloc] initWithValue:[secondMessageText dataUsingEncoding:NSUTF8StringEncoding] dataType:kMessageType summaryValues:nil];
    didPublishMessageExpectation = [self expectationWithDescription:@"published a message after listener started"];
    
    NSLog(@"Publishing second message (after listening started). Message: %@", secondMessageText);
    [responderConversation publishMessage:newMessage
                        completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                            NSLog(@"Publish message (after listening started) completion handler called.");
                            XCTAssertNil(error);
                            XCTAssertNotNil(messageHighWatermark);
                            
                            [didPublishMessageExpectation fulfill];
                        }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didPublishMessageExpectation = nil;
    }];
    
    NSLog(@"Stopping listening for conversation items");
    [creatorConversation stopListening];

    XCTAssert([responderConversation.metadata.conversationId isEqual:creatorConversation.metadata.conversationId],
              @"Conversation ID from responder and creator should be the same");

    // Enumerating conversations
    __block XCTestExpectation *didFindConversation = [self expectationWithDescription:@"find conversation in system vault"];
    __block QredoConversationMetadata *metadataFromEnumeration = nil;
    [client enumerateConversationsWithBlock:^(QredoConversationMetadata *metadata, BOOL *stop) {
        NSLog(@"Enumerating conversations: conversation ID = %@", metadata.conversationId);
        if ([metadata.conversationId isEqual:responderConversation.metadata.conversationId]) {
            metadataFromEnumeration = metadata;
            *stop = YES;

        }
    } completionHandler:^(NSError *error) {
        NSLog(@"Enumerate conversations completion handler called.");
        XCTAssertNil(error);
        [didFindConversation fulfill];
    }];

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didFindConversation = nil;
    }];

    XCTAssertNotNil(metadataFromEnumeration);
    XCTAssert([metadataFromEnumeration.rendezvousTag isEqual:randomTag]);

    // Fetching conversation
    __block XCTestExpectation *didFetchConversation = [self expectationWithDescription:@"fetch conversation from system vault"];

    __block QredoConversation *conversatoinFromVault = nil;
    [client fetchConversationWithRef:metadataFromEnumeration.conversationRef completionHandler:^(QredoConversation *conversation, NSError *error) {
        NSLog(@"Fetch conversation completion handler called.");
        XCTAssertNil(error);
        XCTAssertNotNil(conversation);
        conversatoinFromVault = conversation;

        [didFetchConversation fulfill];
    }];

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didFetchConversation = nil;
    }];

    XCTAssertNotNil(conversatoinFromVault);
    XCTAssert([conversatoinFromVault.metadata.rendezvousTag isEqualToString:randomTag], @"Rendezvous tag should be the same");
    XCTAssert([conversatoinFromVault.metadata.type isEqualToString:configuration.conversationType], @"Conversation type should be the same");

    // Making sure that we can use the fetched conversation
    __block XCTestExpectation *didPublishAnotherMessage = [self expectationWithDescription:@"did publish another message"];

    ConversationMessageListener *anotherListener = [[ConversationMessageListener alloc] init];
    anotherListener.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message"];
    anotherListener.expectedMessageValue = kMessageTestValue2;
    responderConversation.delegate = anotherListener;
    [responderConversation startListening];
    
    QredoConversationMessage *anotherMessage = [[QredoConversationMessage alloc] initWithValue:[kMessageTestValue2 dataUsingEncoding:NSUTF8StringEncoding] dataType:kMessageType summaryValues:nil];
    [conversatoinFromVault publishMessage:anotherMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
        XCTAssertNotNil(messageHighWatermark);
        XCTAssertNil(error);

        NSLog(@"Message published. %@", messageHighWatermark);
        [didPublishAnotherMessage fulfill];
    }];

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didPublishAnotherMessage = nil;
        anotherListener.didReceiveMessageExpectation = nil;
    }];
    XCTAssertFalse(listener.failed);

    [responderConversation stopListening];

    [anotherClient closeSession];
}

// Rendezvous Delegate
- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    NSLog(@"Delegate received response (Conversation = %@) for rendezvous (%@)", conversation, rendezvous);
    creatorConversation = conversation;
    [didReceiveResponseExpectation fulfill];
}

- (void)testMetadataOfEphemeralConversation
{
    
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"test.chat~" durationSeconds:@600 maxResponseCount:@1];
    
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
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];


    // Creating a new client with a new vault
    __block QredoClient *anotherClient = nil;
    __block XCTestExpectation *anotherClientExpectation = [self expectationWithDescription:@"create a new client"];

    [QredoClient authorizeWithConversationTypes:@[self.conversationType]
                                 vaultDataTypes:nil
                                        options:[self clientOptionsWithResetData:YES]
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
    didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    rendezvous.delegate = self;
    
    [rendezvous startListening];
    

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
        NSLog(@"Responder conversation ID: %@", conversation.metadata.conversationId);
        
        [didRespondExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        didRespondExpectation = nil;
    }];
    
    [rendezvous stopListening];
    
    [anotherClient closeSession];
}

- (void)testMetadataOfPersistentConversation
{    
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"test.chat"
                                                                                                 durationSeconds:@600
                                                                                                maxResponseCount:@1];
    
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
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];


    // Creating a new client with a new vault
    __block QredoClient *anotherClient = nil;
    __block XCTestExpectation *anotherClientExpectation = [self expectationWithDescription:@"create a new client"];

    [QredoClient authorizeWithConversationTypes:@[self.conversationType]
                                 vaultDataTypes:nil
                                        options:[self clientOptionsWithResetData:YES]
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
    didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    rendezvous.delegate = self;
    
    [rendezvous startListening];
    
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
        NSLog(@"Responder conversation ID: %@", conversation.metadata.conversationId);
        
        [didRespondExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        didRespondExpectation = nil;
    }];
    
    [rendezvous stopListening];
    
    [anotherClient closeSession];
}

@end
