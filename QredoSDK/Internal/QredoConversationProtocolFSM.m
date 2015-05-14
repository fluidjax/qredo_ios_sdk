/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocolFSM.h"
#import "QredoConversation.h"
#import "QredoErrorCodes.h"
#import "QredoLogging.h"

@class QredoConversationProtocolCancelState;
@class QredoConversationProtocolErrorState;

@protocol QredoFSMProtocolEvents <NSObject>

- (void)didPublishMessageWithState:(QredoConversationProtocolPublishingState *)state;
- (void)didFailWithError:(NSError *)error;
- (void)didReceiveExpectedMessageWithState:(QredoConversationProtocolExpectingState *)state;
- (void)didFinishProcessingWithState:(QredoConversationProtocolProcessingState *)state;

- (void)cancel;

@end

@interface QredoConversationProtocolFSM () <QredoFSMProtocolEvents>
{
    NSMutableArray *_states;
    NSUInteger _currentStateIndex;
    BOOL _finished;
}

@property (weak) id<QredoConversationProtocolFSMDelegate> delegate;
@property dispatch_queue_t processingQueue;
@property dispatch_queue_t interruptQueue;

@property QredoConversationProtocolCancelState *cancelState;
@property QredoConversationProtocolErrorState *errorState;

- (void)switchToNextState;
- (void)failWithError:(NSError *)error;

- (void)didFinish;
- (void)didFinishSendingErrorMessageWithError:(NSError *)error;

@end



@interface QredoConversationProtocolFSMState ()<QredoFSMProtocolEvents>
- (QredoConversationProtocolFSM *)fsmProtocol;
@end

@interface QredoConversationProtocolPublishingState ()
@property (nonatomic, strong) QredoConversationMessage *(^block)();
@end

@interface QredoConversationProtocolCancelState : QredoConversationProtocolPublishingState
@end

@interface QredoConversationProtocolErrorState : QredoConversationProtocolPublishingState

@property NSError *error;

@end


@interface QredoConversationProtocolExpectingState ()
@property (nonatomic, strong) BOOL(^block)(QredoConversationMessage *);
@end

@interface QredoConversationProtocolProcessingState ()
{
    BOOL finishedProcessing;
}
@property (nonatomic, strong) void(^block)(QredoConversationProtocolProcessingState *state);
@property (nonatomic, strong) void(^onInterruptedBlock)();
@end


@implementation QredoConversationProtocolPublishingState
- (instancetype)initWithBlock:(QredoConversationMessage *(^)())block
{
    self = [super init];
    if (!self) return nil;
    self.block = block;
    return self;
}

- (void)didEnter
{
    QredoConversationMessage *message = self.block();
    [self.conversationProtocol.conversation publishMessage:message completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
        if (error) {
            [self.fsmProtocol didFailWithError:error];
            return ;
        }

        [self.fsmProtocol didPublishMessageWithState:self];
    }];
}

- (void)didPublishMessageWithState:(QredoConversationProtocolPublishingState *)state
{
    if (state == self) {
        [self.fsmProtocol switchToNextState];
    }
}

@end

@implementation QredoConversationProtocolCancelState
- (instancetype)init
{
    self = [super initWithBlock:^QredoConversationMessage * __nonnull{
        return [[QredoConversationMessage alloc] initWithValue:nil
                                                      dataType:self.cancelMessageType
                                                 summaryValues:nil];
    }];
    return self;
}

- (void)didFailWithError:(NSError *)error
{
    // Called when failed to send message. Do nothing
}

- (void)didPublishMessageWithState:(QredoConversationProtocolPublishingState *)state
{
    if (state == self) {
        [self.fsmProtocol didFinish];
    }
}
@end



@implementation QredoConversationProtocolErrorState
- (void)prepareForReuse {
    [super prepareForReuse];
    self.error = nil;
}
- (instancetype)init
{
    self = [super initWithBlock:^QredoConversationMessage * __nonnull{
        NSData* messageValue = [self.error.description dataUsingEncoding:NSUTF8StringEncoding];

        return [[QredoConversationMessage alloc] initWithValue:messageValue
                                                      dataType:self.cancelMessageType
                                                 summaryValues:nil];
    }];
    return self;
}

- (void)didFailWithError:(NSError *)error
{
    // Called when failed to send message. Do nothing
}


- (void)didPublishMessageWithState:(QredoConversationProtocolPublishingState *)state
{
    if (state == self) {
        [self.fsmProtocol didFinishSendingErrorMessageWithError:self.error];
    }
}
@end


@implementation QredoConversationProtocolExpectingState
- (instancetype)initWithBlock:(BOOL(^)(QredoConversationMessage *))block
{
    self = [super init];
    if (!self) return nil;
    self.block = block;
    return self;
}

- (void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message
{
    [super didReceiveNonCancelConversationMessage:message];

    BOOL messageHandled = self.block(message);
    if (!messageHandled) {
        [self.fsmProtocol failWithError:[NSError errorWithDomain:QredoErrorDomain
                                                            code:QredoErrorCodeConversationProtocolUnexpectedMessageType
                                                        userInfo:nil]];
        return;
    }

    [self.fsmProtocol switchToNextState];
}
@end

@implementation QredoConversationProtocolProcessingState
- (instancetype)initWithBlock:(void(^)(QredoConversationProtocolProcessingState *state))block
{
    self = [super init];
    if (!self) return nil;
    self.block = block;
    return self;
}

- (void)didEnter
{
    dispatch_async(self.fsmProtocol.processingQueue, ^{
        self.block(self);

        __block BOOL wasInterrupted;
        dispatch_sync(self.fsmProtocol.interruptQueue, ^{
            wasInterrupted = finishedProcessing;
            finishedProcessing = YES;
        });
        if (!wasInterrupted) {
            [self.fsmProtocol switchToNextState];
        }
    });
}

- (void)onInterrupted:(void(^)())onInterruptedBlock
{
    dispatch_sync(self.fsmProtocol.interruptQueue, ^{
        self.onInterruptedBlock = onInterruptedBlock;
    });
}

- (void)interrupt
{
    void(^localInterruptedBlock)()  = self.onInterruptedBlock;
        

    if (localInterruptedBlock) {
        localInterruptedBlock();
    }
}

- (void)willExit
{
    if (finishedProcessing) return;

    dispatch_sync(self.fsmProtocol.interruptQueue, ^{
        if (!finishedProcessing) {
            finishedProcessing = YES;
            [self interrupt];
        }
    });
}

- (void)failWithError:(NSError *)error
{
    dispatch_async(self.fsmProtocol.interruptQueue, ^{
        if (!finishedProcessing) {
            finishedProcessing = YES;

            [self.fsmProtocol failWithError:error];
        }
    });
}

@end

#pragma GCC diagnostic push
#pragma clang diagnostic push

#pragma GCC diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wprotocol"

@implementation QredoConversationProtocolFSMState

- (QredoConversationProtocolFSM *)fsmProtocol
{
    return (QredoConversationProtocolFSM *)self.conversationProtocol;
}

- (void)didPublishMessageWithState:(QredoConversationProtocolPublishingState *)state
{
    // fail with error: inconsistent state
}

- (void)didReceiveExpectedMessageWithState:(QredoConversationProtocolExpectingState *)state
{
    // fail with error: inconsistent state
}

- (void)didFinishProcessingWithState:(QredoConversationProtocolProcessingState *)state
{
}

- (void)cancel
{
}

- (void)conversationCanceledWithMessage:(QredoConversationMessage *)message
{
    [self.fsmProtocol failWithError:[NSError errorWithDomain:QredoErrorDomain
                                                        code:QredoErrorCodeConversationProtocolCancelledByOtherSide
                                                    userInfo:@{@"message" : message.value}]];
}


@end

@implementation QredoConversationProtocolFSMBlockDelegate

- (void)qredoConversationProtocol:(QredoConversationProtocolFSM * __nonnull)protocol didFailWithError:(NSError * __nonnull)error
{
    if (self.onError) {
        self.onError(error);
    }
}

- (void)qredoConversationProtocolDidFinishSuccessfuly:(QredoConversationProtocolFSM * __nonnull)protocol
{
    if (self.onSuccess) {
        self.onSuccess();
    }
}

@end

@implementation QredoConversationProtocolFSM


- (instancetype)initWithConversation:(QredoConversation *)conversation
{
    self = [super initWithConversation:conversation];
    if (!self) return nil;

    _states = [NSMutableArray new];

    self.cancelState = [[QredoConversationProtocolCancelState alloc] init];
    self.errorState = [[QredoConversationProtocolErrorState alloc] init];

    self.processingQueue = dispatch_queue_create("com.qredo.conversation.protocol.processing", NULL);
    self.interruptQueue = dispatch_queue_create("com.qredo.conversation.protocol.interrupt", NULL);

    return self;
}

- (void)addStates:(nonnull NSArray *)states
{
    if (self.currentState) {
        [NSException raise:NSInternalInconsistencyException format:@"The protocol has already been started"];
        return;
    }

    [_states addObjectsFromArray:states];
}

- (void)startWithDelegate:(id<QredoConversationProtocolFSMDelegate>)delegate
{
    if (!_states.count) {
        [NSException raise:NSInternalInconsistencyException format:@"The protocol doesn't have defined states"];
        return;
    }
    if (self.currentState) {
        [NSException raise:NSInternalInconsistencyException format:@"The protocol has already been started"];
        return;
    }

    self.delegate = delegate;
    _currentStateIndex = 0;
    [self.conversation startListening];
    [self switchToState:_states[_currentStateIndex] withConfigBlock:^{ }];
}

- (void)failWithError:(NSError *)error
{
    LogError(@"failWithError");

    [self switchToState:self.errorState withConfigBlock:^{
        self.errorState.error = error;
    }];
}

- (void)switchToNextState
{
    if (_finished) {
        [NSException raise:NSInternalInconsistencyException format:@"The protocol has already finished"];
    }

    ++_currentStateIndex;

    if (_currentStateIndex < _states.count) {
        [self switchToState:_states[_currentStateIndex] withConfigBlock:^{ }];
    } else {
        [self didFinish];
    }
}

- (void)finish {
    NSAssert(!_finished, @"should not finish twice");
    _finished = YES;

    [self.conversation stopListening];
}

- (void)didFinish {
    [self finish];

    if (self.delegate) {
        [self.delegate qredoConversationProtocolDidFinishSuccessfuly:self];
    }
}

- (void)didFinishSendingErrorMessageWithError:(NSError *)error
{
    [self finish];

    if (self.delegate) {
        [self.delegate qredoConversationProtocol:self didFailWithError:error];
    }
}

- (void)cancel
{
    if (self.currentState == self.cancelState) {
        LogInfo(@"Can't cancel the protocol because it is already being cancelled");
        return;
    }
    [self switchToState:self.cancelState withConfigBlock:^{}];
}

@end

#pragma clang diagnostic pop
#pragma GCC diagnostic pop

#pragma mark - States implementation
