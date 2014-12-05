#import <XCTest/XCTest.h>

@interface ConversationTests : XCTestCase

@property BOOL useMQTT;

- (void)testConversation;
- (void)testMetadataOfEphemeralConversation;
- (void)testMetadataOfPersistentConversation;

@end
