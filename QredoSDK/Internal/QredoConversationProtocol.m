/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocol.h"
#import "QredoConversation.h"



//=========================
#pragma mark - Interfaces -
//=========================


@interface QredoConversationProtocolState ()
@property (weak, nonatomic) QredoConversationProtocol *conversationProtocol;
- (void)prepareForReuseWithConversationProtocol:(QredoConversationProtocol *)conversationProtocol
                                    configBlock:(dispatch_block_t)configBlock;
@end


//------------
#pragma mark -

@interface QredoConversationProtocol ()<QredoConversationDelegate>
@property (nonatomic) dispatch_queue_t protocolQueue;
@property (nonatomic) QredoConversation *conversation;
@end



//====================================
#pragma mark - State Implementations -
//====================================


@implementation QredoConversationProtocolState


- (void)prepareForReuseWithConversationProtocol:(QredoConversationProtocol *)conversationProtocol
                                    configBlock:(dispatch_block_t)configBlock
{
    self.conversationProtocol = conversationProtocol;
    if (configBlock) {
        configBlock();
    }
}

- (void)prepareForReuse
{
    
}


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


//------------
#pragma mark -

@implementation QredoConversationProtocolCancelableState

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cancelMessageType = @"com.qredo.attestation.cancel";
    }
    return self;
}

- (void)didReceiveConversationMessage:(QredoConversationMessage *)message
{
    if ([message.dataType isEqualToString:self.cancelMessageType]) {
        // TODO [GR]: Send the correct error in stead of nil.
        [self didReceiveCancelConversationMessageWithError:nil];
    } else {
        [self didReceiveNonCancelConversationMessage:message];
    }
}

- (void)otherPartyHasLeftConversation
{
    [self didReceiveCancelConversationMessageWithError:nil];
}

- (void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message
{
}

- (void)didReceiveCancelConversationMessageWithError:(NSError *)error
{
}

@end



//======================================
#pragma mark - Protocol Implementation -
//======================================


@implementation QredoConversationProtocol


- (instancetype)initWithConversation:(QredoConversation *)conversation
{
    self = [super init];
    if (self) {
        _protocolQueue = dispatch_queue_create("QredoConversationProtocol__protocolQueue", DISPATCH_QUEUE_SERIAL);
        self.conversation = conversation;
        self.conversation.delegate = self;
    }
    return self;
}


#pragma mark Event handling

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        signature = [self.currentState methodSignatureForSelector:aSelector];
    }
    return signature;
}


- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation retainArguments];
    
    if (![self.currentState respondsToSelector:[anInvocation selector]]) {
        [super forwardInvocation:anInvocation];
        return;
    }
    
    if (anInvocation.methodSignature.methodReturnLength > 0) {
        [anInvocation invokeWithTarget:self.currentState];
        return;
    }
    
    dispatch_async(self.protocolQueue, ^{
        [anInvocation invokeWithTarget:self.currentState];
    });
}


- (void)switchToState:(QredoConversationProtocolState *)state withConfigBlock:(dispatch_block_t)configBlock
{
    NSAssert(state != nil, @"State is not initialized");

    [state prepareForReuseWithConversationProtocol:self configBlock:configBlock];
    
    [_currentState willExit];
    _currentState = state;
    [_currentState didEnter];
}


#pragma mark QredoConversationDelegate implementation

- (void)qredoConversation:(QredoConversation *)conversation
     didReceiveNewMessage:(QredoConversationMessage *)message
{
    [self didReceiveConversationMessage:message];
}

- (void)qredoConversationOtherPartyHasLeft:(QredoConversation *)conversation
{
    [self otherPartyHasLeftConversation];
}


@end


#pragma GCC diagnostic push
#pragma clang diagnostic push

#pragma GCC diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wprotocol"

@implementation QredoConversationProtocol(Events)
@end

#pragma clang diagnostic pop
#pragma GCC diagnostic pop


