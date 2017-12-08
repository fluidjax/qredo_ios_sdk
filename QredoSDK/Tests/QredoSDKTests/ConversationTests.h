/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


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
