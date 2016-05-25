#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"

@interface ConversationTests :QredoXCTestCase



@property (atomic) XCTestExpectation *didReceiveResponseExpectation;
@property (atomic) XCTestExpectation *didReceiveMessageExpectation;
@property (atomic) XCTestExpectation *didRecieveOtherPartyHasLeft;

-(void)authoriseClient;
-(void)authoriseAnotherClient;
-(void)closeClientSessions;
-(void)testConversationCreation;
-(void)testRespondingToConversation;
-(void)testConversation;
//-(void)testMetadataOfEphemeralConversation;
//-(void)testMetadataOfPersistentConversation;

@end
