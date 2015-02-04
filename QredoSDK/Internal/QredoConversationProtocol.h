/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>


@class QredoConversationProtocol, QredoConversation, QredoConversationMessage;

@interface QredoConversationProtocolErrorMessage : NSObject
@property (nonatomic) NSError *error;
@end



@interface QredoConversationProtocolState : NSObject

@property (weak, nonatomic, readonly) QredoConversationProtocol *conversationProtocol;


#pragma mark State life cycle

- (void)didEnterWithBlock:(dispatch_block_t)block;
- (void)willExit;


#pragma mark Events (conversation message handling)

- (void)didReceiveConversationMessage:(id)message;
- (void)otherPartyHasLeftConversation;


@end



@interface QredoConversationProtocol : NSObject

@property (nonatomic, readonly) QredoConversationProtocolState *currentState;

- (instancetype)initWithConversation:(QredoConversation *)conversation;

#pragma mark Event handling

- (void)switchToState:(QredoConversationProtocolState *)state withBlock:(dispatch_block_t)block;

- (void)handleEventWithBlock:(dispatch_block_t)block;

@end


