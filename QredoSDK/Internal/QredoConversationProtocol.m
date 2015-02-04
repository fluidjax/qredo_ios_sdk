/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocol.h"
#import "QredoConversation.h"



#pragma mark Interfaces

@interface QredoConversationProtocolState ()
@property (weak, nonatomic) QredoConversationProtocol *conversationProtocol;
@end



@interface QredoConversationProtocol ()<QredoConversationDelegate>
@property (nonatomic) dispatch_queue_t protocolQueue;
@property (nonatomic) QredoConversation *conversation;
@end



#pragma mark Implementations

@implementation QredoConversationProtocolState


#pragma mark State life cycle

- (void)didEnter
{
}

- (void)willExit
{
}


#pragma mark Events (conversation message handling)

- (void)didReceiveConversationMessage:(QredoConversationMessage *)message
{
}

- (void)otherPartyHasLeftConversation
{
}

@end



@implementation QredoConversationProtocol


- (instancetype)initWithConversation:(QredoConversation *)conversation
{
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.conversation.delegate = self;
    }
    return self;
}


#pragma mark Event handling

- (void)handleEventWithBlock:(dispatch_block_t)block
{
    dispatch_async(self.protocolQueue, block);
}

- (void)switchToState:(QredoConversationProtocolState *)state
{
    dispatch_async(self.protocolQueue, ^{
        
        state.conversationProtocol = self;
        
        [_currentState willExit];
        _currentState = state;
        [_currentState didEnter];
        
    });
}


#pragma mark QredoConversationDelegate implementation

- (void)qredoConversation:(QredoConversation *)conversation
     didReceiveNewMessage:(QredoConversationMessage *)message
{
    [self handleEventWithBlock:^{
        [self.currentState didReceiveConversationMessage:message];
    }];
}

- (void)qredoConversationOtherPartyHasLeft:(QredoConversation *)conversation
{
    [self handleEventWithBlock:^{
        [self.currentState otherPartyHasLeftConversation];
    }];
}


@end


