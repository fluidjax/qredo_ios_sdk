/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "Qredo.h"

@interface ConversationWebSocketRespondTests : XCTestCase

@property (nonatomic) QredoClientOptionsTransportType transportType;
@property (nonatomic) NSString* randomTag;

- (void)authoriseClient;
- (void)conversation;

@end