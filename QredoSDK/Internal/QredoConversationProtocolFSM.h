/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocol.h"

@class QredoConversationProtocolFSM;

NS_ASSUME_NONNULL_BEGIN

@protocol QredoConversationProtocolFSMDelegate <NSObject>

@required
- (void)qredoConversationProtocolDidFinishSuccessfuly:(QredoConversationProtocolFSM *)protocol;
- (void)qredoConversationProtocol:(QredoConversationProtocolFSM *)protocol didFailWithError:(NSError *)error;
@end

@interface QredoConversationProtocolFSMState : QredoConversationProtocolCancelableState
@end


@interface QredoConversationProtocolFSMBlockDelegate : NSObject <QredoConversationProtocolFSMDelegate>

@property (nonatomic, strong, nullable) void(^onSuccess)();
@property (nonatomic, strong, nullable) void(^onError)(NSError *error);

@end


@interface QredoConversationProtocolPublishingState : QredoConversationProtocolFSMState
- (instancetype)initWithBlock:(QredoConversationMessage *(^)())block;
@end

@interface QredoConversationProtocolExpectingState : QredoConversationProtocolFSMState
- (instancetype)initWithBlock:(BOOL(^)(QredoConversationMessage *))block;
@end

@interface QredoConversationProtocolProcessingState : QredoConversationProtocolFSMState
- (instancetype)initWithBlock:(void(^)(QredoConversationProtocolProcessingState *state))block;

- (void)onInterrupted:(void(^)())onInterruptedBlock;
- (void)failWithError:(NSError *)error;
- (void)finishProcessing;

@end

@interface QredoConversationProtocolFSM : QredoConversationProtocol

- (instancetype)initWithConversation:(QredoConversation *)conversation;

- (void)addStates:(nonnull NSArray *)states;

- (void)startWithDelegate:(id<QredoConversationProtocolFSMDelegate>)delegate;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END