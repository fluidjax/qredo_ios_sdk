#import <XCTest/XCTest.h>
#import "Qredo.h"

@interface ConversationTests : XCTestCase


@property (nonatomic) QredoClientOptionsTransportType transportType;
@property (atomic) XCTestExpectation *didReceiveResponseExpectation;
@property (atomic) XCTestExpectation *didReceiveMessageExpectation;

- (void)authoriseClient;
- (void)testConversationCreation;
- (void)testRespondingToConversation;
- (void)testConversation;
- (void)testMetadataOfEphemeralConversation;
- (void)testMetadataOfPersistentConversation;

@end
