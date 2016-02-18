#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"

@interface ConversationTests :QredoXCTestCase


@property (nonatomic) QredoClientOptionsTransportType transportType;
@property (atomic) XCTestExpectation *didReceiveResponseExpectation;
@property (atomic) XCTestExpectation *didReceiveMessageExpectation;

-(void)authoriseClient;
-(void)testConversationCreation;
-(void)testRespondingToConversation;
-(void)testConversation;
//-(void)testMetadataOfEphemeralConversation;
//-(void)testMetadataOfPersistentConversation;

@end
