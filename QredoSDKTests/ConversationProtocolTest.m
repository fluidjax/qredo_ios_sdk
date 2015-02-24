/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "QredoConversationProtocol.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>



@class ProtocolUnderTest;

//===============================================================================================================
#pragma mark - Events -
//===============================================================================================================

@protocol ConversationProtocolTestEvents <NSObject>

- (void)goToMainTimeoutState;
- (void)goToDidNotTimeoutState;

@end



//===============================================================================================================
#pragma mark - Stetes interfaces -
//===============================================================================================================


@interface ProtocolUnderTestState : QredoConversationProtocolCancelableState<ConversationProtocolTestEvents>
@property (nonatomic, readonly) ProtocolUnderTest *protocolUnderTest;
@property (nonatomic, copy) void(^didEnterBlock)();
@end


//---------------------------------------------------------------------------------------------------------------

@interface ProtocolUnderTest_MainTimeoutState : ProtocolUnderTestState
@end

typedef ProtocolUnderTest_MainTimeoutState MainTimeoutState;


//---------------------------------------------------------------------------------------------------------------

@interface ProtocolUnderTest_DidTimeoutState : ProtocolUnderTestState
@end

typedef ProtocolUnderTest_DidTimeoutState DidTimeoutState;


//---------------------------------------------------------------------------------------------------------------

@interface ProtocolUnderTest_DidNotTimeoutState : ProtocolUnderTestState
@end

typedef ProtocolUnderTest_DidNotTimeoutState DidNotTimeoutState;



//===============================================================================================================
#pragma mark - Protocol interfaces -
//===============================================================================================================
@interface ProtocolUnderTest : QredoConversationProtocol

@property (nonatomic) MainTimeoutState *mainTimeoutState;
@property (nonatomic) DidTimeoutState *didTimeoutState;
@property (nonatomic) DidNotTimeoutState *didNotTimeoutState;

@end

@interface ProtocolUnderTest(Events)<ConversationProtocolTestEvents>
@end



//===============================================================================================================
#pragma mark - State implementations -
//===============================================================================================================


@implementation ProtocolUnderTestState

- (void)goToMainTimeoutState {}
- (void)goToDidNotTimeoutState {}

- (ProtocolUnderTest *)protocolUnderTest
{
    return (ProtocolUnderTest *)self.conversationProtocol;
}

- (void)didEnter
{
    [super didEnter];
    if (self.didEnterBlock) {
        self.didEnterBlock();
    }
}

@end


//---------------------------------------------------------------------------------------------------------------


@implementation ProtocolUnderTest_MainTimeoutState

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTimeout:5];
    }
    return self;
}

- (void)didTimeout
{
    [self.protocolUnderTest switchToState:self.protocolUnderTest.didTimeoutState withConfigBlock:^{}];
}

@end


//---------------------------------------------------------------------------------------------------------------

@implementation ProtocolUnderTest_DidTimeoutState
@end


//---------------------------------------------------------------------------------------------------------------

@implementation ProtocolUnderTest_DidNotTimeoutState
@end



//===============================================================================================================
#pragma mark - Protocol implementations-
//===============================================================================================================


@implementation ProtocolUnderTest

- (instancetype)initWithConversation:(QredoConversation *)conversation
{
    self = [super initWithConversation:conversation];
    if (self) {
        self.mainTimeoutState = [MainTimeoutState new];
        self.didTimeoutState = [DidTimeoutState new];
        self.didNotTimeoutState = [DidNotTimeoutState new];
    }
    return self;
}

@end


#pragma GCC diagnostic push
#pragma clang diagnostic push

#pragma GCC diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wprotocol"

@implementation ProtocolUnderTest(Events)
@end

#pragma clang diagnostic pop
#pragma GCC diagnostic pop




//===============================================================================================================
#pragma mark - Test class -
//===============================================================================================================


@interface ConversationProtocolTest : XCTestCase
@property (nonatomic) ProtocolUnderTest *protocol;
@end

@implementation ConversationProtocolTest

- (void)setUp {
    [super setUp];
    self.protocol = [[ProtocolUnderTest alloc] initWithConversation:nil];
}

- (void)tearDown {
    self.protocol = nil;
    [super tearDown];
}


#pragma mark Tests

- (void)testTimeout
{
    __block XCTestExpectation *didTimeoutStateEnteredExpectation = [self expectationWithDescription:@"Did timeout state entered."];
    [self.protocol.didTimeoutState setDidEnterBlock:^{
        [didTimeoutStateEnteredExpectation fulfill];
    }];
    
    [self.protocol.mainTimeoutState setTimeout:2];
    [self.protocol switchToState:self.protocol.mainTimeoutState withConfigBlock:^{}];
    
    [self waitForExpectationsWithTimeout:4 handler:^(NSError *error) {
        didTimeoutStateEnteredExpectation = nil;
    }];
    
}

@end


