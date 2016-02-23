/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocolFSM.h"
#import "QredoConversationMessagePrivate.h"
#import "QredoConversation.h"
#import "QredoErrorCodes.h"
#import "QredoLoggerPrivate.h"

@class QredoConversationProtocolCancelState;
@class QredoConversationProtocolErrorState;
@class QredoConversationProtocolFinishState;

@protocol QredoFSMProtocolEvents <NSObject>

- (void)didPublishMessageWithState:(QredoConversationProtocolPublishingState *)state;
- (void)didFailPublishingMessageWithState:(QredoConversationProtocolPublishingState *)state error:(NSError *)error;
- (void)didReceiveExpectedMessageWithState:(QredoConversationProtocolExpectingState *)state;

- (void)didFinishProcessingWithState:(QredoConversationProtocolProcessingState *)state;
- (void)didFailProcessingWithState:(QredoConversationProtocolProcessingState *)state error:(NSError *)error;

- (void)didFinishSendingErrorMessageWithError:(NSError *)error;
- (void)didFinishSendingCancelMessage;

- (void)cancel;

@end

@interface QredoConversationProtocolFSM ()
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
@property QredoConversationProtocolFinishState *finishState;

- (void)switchToNextState;
- (void)failWithError:(NSError *)error;

@end


@interface QredoConversationProtocolFSM (Events) <QredoFSMProtocolEvents>

@end



@interface QredoConversationProtocolFSMState ()<QredoFSMProtocolEvents>
- (QredoConversationProtocolFSM *)fsmProtocol;
@end

@interface QredoConversationProtocolPublishingState ()
@property (nonatomic, strong) QredoConversationMessage *(^block)();
@end

@interface QredoConversationProtocolCancelState : QredoConversationProtocolFSMState
@end

@interface QredoConversationProtocolErrorState : QredoConversationProtocolPublishingState

@property NSError *error;

@end

@interface QredoConversationProtocolFinishState : QredoConversationProtocolFSMState
// keeping a separate flag `failed` just in case if it fails but for some reason `error` is nil.
// should not happen ideally, but still it is more important to call the correct method on delegate.
@property BOOL failed;
@property NSError *error;
@end


@interface QredoConversationProtocolExpectingState ()
@property (nonatomic, strong) BOOL(^block)(QredoConversationMessage *);
@end

@interface QredoConversationProtocolProcessingState ()
{
    BOOL finishedProcessing;
    BOOL wasInterrupted;
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
            [self.fsmProtocol didFailPublishingMessageWithState:self error:error];
            return ;
        }

        [self.fsmProtocol didPublishMessageWithState:self];
    }];
}

- (void)didPublishMessageWithState:(QredoConversationProtocolPublishingState *)state
{
    NSAssert(state == self, @"Unexpected state. Please debug");

    [self.fsmProtocol switchToNextState];
}

- (void)didFailPublishingMessageWithState:(QredoConversationProtocolPublishingState *)state
                                    error:(NSError *)error
{
    NSAssert(state == self, @"Unexpected state. Please debug");

    [self.fsmProtocol failWithError:error];
}


@end

@implementation QredoConversationProtocolCancelState
- (void)didEnter
{
    QredoConversationMessage *cancelMessage
    = [[QredoConversationMessage alloc] initWithValue:nil
                                             dataType:self.cancelMessageType
                                        summaryValues:nil];


    [self.conversationProtocol.conversation publishMessage:cancelMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
        // don't care about error at this state

        [self.fsmProtocol didFinishSendingCancelMessage];
    }];
}

- (void)didFinishSendingCancelMessage
{
    [self.fsmProtocol switchToState:self.fsmProtocol.finishState withConfigBlock:^{ }];
}
@end


@implementation QredoConversationProtocolErrorState

- (void)prepareForReuse {
    [super prepareForReuse];
    self.error = nil;
}

- (void)didEnter
{
    NSData* messageValue = [self.error.description dataUsingEncoding:NSUTF8StringEncoding];

    QredoConversationMessage *errorMessage
    = [[QredoConversationMessage alloc] initWithValue:messageValue
                                                  dataType:self.cancelMessageType
                                             summaryValues:nil];

    [self.conversationProtocol.conversation publishMessage:errorMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *publishError) {
        // don't care about error at this state

        [self didFinishSendingErrorMessageWithError:self.error];
    }];
}

- (void)didFinishSendingErrorMessageWithError:(NSError *)error {
    [self.fsmProtocol switchToState:self.fsmProtocol.finishState withConfigBlock:^{
        self.fsmProtocol.finishState.failed = YES;
        self.fsmProtocol.finishState.error = error;
    }];
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
    wasInterrupted = YES;
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

- (void)finishProcessing
{
    dispatch_sync(self.fsmProtocol.interruptQueue, ^{
        if (wasInterrupted) {
            return ;
        }

        NSAssert(!finishedProcessing, @"The state has already finished");
        finishedProcessing = YES;

        [self.fsmProtocol didFinishProcessingWithState:self];
    });
}

- (void)failWithError:(NSError *)error
{
    dispatch_sync(self.fsmProtocol.interruptQueue, ^{
        NSAssert(!finishedProcessing, @"The state has already finished");
        finishedProcessing = YES;

        [self.fsmProtocol didFailProcessingWithState:self error:error];
    });
}

- (void)didFailProcessingWithState:(QredoConversationProtocolProcessingState *)state error:(NSError *)error
{
    if (state == self) {
        [self.fsmProtocol failWithError:error];
    }
}

- (void)didFinishProcessingWithState:(QredoConversationProtocolProcessingState *)state
{
    if (state == self) {
        dispatch_sync(self.fsmProtocol.interruptQueue, ^{
            finishedProcessing = YES;
        });
        if (!wasInterrupted) {
            [self.fsmProtocol switchToNextState];
        }
    }
}

@end


@implementation QredoConversationProtocolFinishState

- (void)prepareForReuse {
    [super prepareForReuse];
    self.failed = NO;
    self.error = nil;
}

- (void)didEnter {
    [self.fsmProtocol stopObservingConversation];

    if (self.fsmProtocol.delegate) {
        if (self.failed) {
            [self.fsmProtocol.delegate qredoConversationProtocol:self.fsmProtocol didFailWithError:self.error];
        } else {
            [self.fsmProtocol.delegate qredoConversationProtocolDidFinishSuccessfuly:self.fsmProtocol];
        }
    }
}

@end


@implementation QredoConversationProtocolFSMState

- (QredoConversationProtocolFSM *)fsmProtocol
{
    return (QredoConversationProtocolFSM *)self.conversationProtocol;
}

- (void)didPublishMessageWithState:(QredoConversationProtocolPublishingState *)state
{
    [NSException raise:NSInternalInconsistencyException format:@"It is not a Publishing state"];
}

- (void)didFailPublishingMessageWithState:(QredoConversationProtocolPublishingState *)state error:(NSError *)error
{
    [NSException raise:NSInternalInconsistencyException format:@"It is not a Publishing state"];
}


- (void)didReceiveExpectedMessageWithState:(QredoConversationProtocolExpectingState *)state
{
    [NSException raise:NSInternalInconsistencyException format:@"It is not a Expecting state"];
}

- (void)didFinishProcessingWithState:(QredoConversationProtocolProcessingState *)state
{
    [NSException raise:NSInternalInconsistencyException format:@"It is not a Processing state"];
}

- (void)didFailProcessingWithState:(QredoConversationProtocolProcessingState *)state error:(NSError *)error
{
    [NSException raise:NSInternalInconsistencyException format:@"It is not a Processing state"];
}

- (void)didFinishSendingCancelMessage
{
    [NSException raise:NSInternalInconsistencyException format:@"It is not a Cancel state"];
}

- (void)didFinishSendingErrorMessageWithError:(NSError *)error
{
    [NSException raise:NSInternalInconsistencyException format:@"It is not an Error state"];
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
    self.finishState = [[QredoConversationProtocolFinishState alloc] init];

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
    [self startObservingConversation];
    [self switchToState:_states[_currentStateIndex] withConfigBlock:^{ }];
}

- (void)failWithError:(NSError *)error
{
    QredoLogError(@"failWithError");

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
        [self switchToState:self.finishState withConfigBlock:^{ }];
    }
}

- (void)cancel
{
    if (self.currentState == self.cancelState) {
        return;
    }
    [self switchToState:self.cancelState withConfigBlock:^{}];
}

@end


#pragma GCC diagnostic push
#pragma clang diagnostic push

#pragma GCC diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wprotocol"

@implementation QredoConversationProtocolFSM (Events)

@end

#pragma clang diagnostic pop
#pragma GCC diagnostic pop

#pragma mark - States implementation
