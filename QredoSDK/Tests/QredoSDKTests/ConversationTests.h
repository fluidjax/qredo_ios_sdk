/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"

@interface ConversationTests :QredoXCTestCase

@property (atomic) XCTestExpectation *didReceiveResponseExpectation;
@property (atomic) XCTestExpectation *didReceiveMessageExpectation;
@property (atomic) XCTestExpectation *didRecieveOtherPartyHasLeft;
@property (atomic) XCTestExpectation *didReceiveRendezvousExpectation;

-(void)testConversationCreation;
-(void)testRespondingToConversation;
@end
