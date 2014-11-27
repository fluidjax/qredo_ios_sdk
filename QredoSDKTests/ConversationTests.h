#import <XCTest/XCTest.h>

@interface ConversationTests : XCTestCase

@property NSURL *serviceURL;

- (void)testConversation;
- (void)testMetadataOfEphemeralConversation;
- (void)testMetadataOfPersistentConversation;

@end
