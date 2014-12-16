#import <XCTest/XCTest.h>

@interface ConversationTests : XCTestCase

@property BOOL useMQTT;

- (void)authoriseClient;
- (void)testConversationCreation;
- (void)testRespondingToConversation;
- (void)testConversation;
- (void)testMetadataOfEphemeralConversation;
- (void)testMetadataOfPersistentConversation;

@end
