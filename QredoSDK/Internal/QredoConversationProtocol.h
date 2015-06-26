/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>


@class QredoConversationProtocol, QredoConversation, QredoConversationMessage;



//==============================================================================================================
#pragma mark - Events -
//==============================================================================================================


@protocol QredoConversationProtocolEvents <NSObject>

- (void)didReceiveConversationMessage:(QredoConversationMessage *)message;
- (void)otherPartyHasLeftConversation;

@end



//==============================================================================================================
#pragma mark - States -
//==============================================================================================================


@interface QredoConversationProtocolState : NSObject<QredoConversationProtocolEvents>

@property (weak, nonatomic, readonly) QredoConversationProtocol *conversationProtocol;

/**
 * Must be overidden in subclasses which declare properties. This method is called by
 * switch state before swiching to this state. Subclass implementations should reset the
 * properties of the state that need to be reset before the state becomes active.
 */
- (void)prepareForReuse;


#pragma mark State life cycle

- (void)didEnter;
- (void)willExit;


#pragma mark Events (conversation message handling)

- (void)didReceiveConversationMessage:(QredoConversationMessage *)message;
- (void)otherPartyHasLeftConversation;

#pragma mark Utility methods

- (void)setTimeout:(NSTimeInterval)timeout;
- (void)didTimeout;

@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoConversationProtocolCancelableState : QredoConversationProtocolState

@property (nonatomic, copy) NSString *cancelMessageType;

- (void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message;
- (void)conversationCanceledWithMessage:(QredoConversationMessage *)message;

#pragma mark Utilities

- (void)publishCancelMessageWithCompletionHandler:(void(^)(NSError *error))completionHandler;

@end



//==============================================================================================================
#pragma mark - Protocol -
//==============================================================================================================


@interface QredoConversationProtocol : NSObject

@property (nonatomic, readonly) QredoConversationProtocolState *currentState;
@property (nonatomic, readonly) QredoConversation *conversation;

- (instancetype)initWithConversation:(QredoConversation *)conversation;

- (void)startObservingConversation;
- (void)stopObservingConversation;


#pragma mark Event handling

- (void)switchToState:(QredoConversationProtocolState *)state withConfigBlock:(dispatch_block_t)configBlock;

@end


@interface QredoConversationProtocol(Events)<QredoConversationProtocolEvents>
@end


