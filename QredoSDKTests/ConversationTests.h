#import <XCTest/XCTest.h>

@interface ConversationTests : XCTestCase

@property NSURL *serviceURL;

- (void)authoriseClient;
- (void)testConversationCreation;
- (void)testRespondingToConversation;
- (void)testConversation;
- (void)testMetadataOfEphemeralConversation;
- (void)testMetadataOfPersistentConversation;

@end
