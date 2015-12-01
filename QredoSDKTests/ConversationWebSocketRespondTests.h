//
//  ConversationWebSocketTest.h
//  QredoSDK
//
//  Created by Adam Horacek on 2015-11-11.
//
//

#import <XCTest/XCTest.h>
#import "Qredo.h"

@interface ConversationWebSocketRespondTests : XCTestCase

@property (nonatomic) QredoClientOptionsTransportType transportType;
@property (nonatomic) NSString* randomTag;

- (void)authoriseClient;
- (void)conversation;

@end