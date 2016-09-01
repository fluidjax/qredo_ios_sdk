/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "Qredo.h"

@interface ConversationWebSocketCreateTests : XCTestCase

@property (nonatomic) QredoClientOptionsTransportType transportType;
@property (nonatomic) NSString* randomTag;

- (void)authoriseClient;
- (void)conversation;
- (void)testConversationMultiple;

@end