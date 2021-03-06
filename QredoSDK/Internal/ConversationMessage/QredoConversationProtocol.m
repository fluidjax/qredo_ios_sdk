/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoConversationProtocol.h"
#import "QredoConversationMessagePrivate.h"
#import "QredoConversation.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"


static NSString *const kDefaultCancelMessageType = @"com.qredo.cancel";

@protocol QredoConversationProtocolPrivateEvents <NSObject>
-(void)didReceiveTimeoutCallbackWithIdentifier:(QredoQUID *)identifier;
@end



@interface QredoConversationProtocolState ()
@property (weak,nonatomic) QredoConversationProtocol *conversationProtocol;
-(void)prepareForReuseWithConversationProtocol:(QredoConversationProtocol *)conversationProtocol
                                   configBlock:(dispatch_block_t)configBlock;
@end



@interface QredoConversationProtocol ()<QredoConversationObserver>{
    BOOL _isObservingConversation;
}
@property (nonatomic) dispatch_queue_t protocolQueue;
@property (nonatomic) QredoConversation *conversation;
@end



@interface QredoConversationProtocol (PrivateEvents)<QredoConversationProtocolPrivateEvents>
@end


@implementation QredoConversationProtocolState{
    BOOL _timeoutEnabled;
    NSTimeInterval _timeoutInterval;
    QredoQUID *_timeoutIdentifier;
}

-(void)prepareForReuseWithConversationProtocol:(QredoConversationProtocol *)conversationProtocol
                                   configBlock:(dispatch_block_t)configBlock {
    self.conversationProtocol = conversationProtocol;
    if (configBlock){
        configBlock();
    }
}


-(void)prepareForReuse {
}


#pragma mark State life cycle

-(void)didEnter {
    if (_timeoutEnabled){
        QredoQUID *timeoutIdentifier = [QredoQUID QUID];
        _timeoutIdentifier = timeoutIdentifier;
        
        __weak QredoConversationProtocol *protocol = self.conversationProtocol;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(_timeoutInterval * NSEC_PER_SEC)),
                       protocol.protocolQueue,^
                       {
                           [protocol.currentState didReceiveTimeoutCallbackWithIdentifier:timeoutIdentifier];
                       });
    }
}


-(void)willExit {
    _timeoutIdentifier = nil;
}


#pragma mark Events (conversation message handling)

-(void)didReceiveConversationMessage:(QredoConversationMessage *)message {
}


-(void)otherPartyHasLeftConversation {
}


-(void)didReceiveTimeoutCallbackWithIdentifier:(QredoQUID *)identifier {
    if ([_timeoutIdentifier isEqual:identifier]){
        [self didTimeout];
    }
}


#pragma mark Utility methods

-(void)setTimeout:(NSTimeInterval)timeout {
    _timeoutEnabled = YES;
    _timeoutInterval = timeout;
}


-(void)didTimeout {
}


@end


@implementation QredoConversationProtocolCancelableState

-(instancetype)init {
    self = [super init];
    if (self){
        _cancelMessageType = kDefaultCancelMessageType;
    }
    return self;
}


-(void)didReceiveConversationMessage:(QredoConversationMessage *)message {
    if ([message.dataType isEqualToString:self.cancelMessageType]){
        [self conversationCanceledWithMessage:message];
    } else {
        [self didReceiveNonCancelConversationMessage:message];
    }
}


-(void)otherPartyHasLeftConversation {
    [self conversationCanceledWithMessage:nil];
}


-(void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message {
}


-(void)conversationCanceledWithMessage:(QredoConversationMessage *)message {
}


#pragma mark Utilities

-(void)publishCancelMessageWithCompletionHandler:(void (^)(NSError *error))completionHandler;
{
    QredoConversationMessage *message
    = [[QredoConversationMessage alloc] initWithValue:nil
                                             dataType:self.cancelMessageType
                                        summaryValues:nil];
    [self.conversationProtocol.conversation
     publishMessage:message
     completionHandler:^(QredoConversationHighWatermark *messageHighWatermark,
                         NSError *error)
     {
         if (completionHandler) completionHandler(error);
     }];
}

@end



#pragma mark - Protocol Implementation -

@implementation QredoConversationProtocol


-(instancetype)initWithConversation:(QredoConversation *)conversation {
    self = [super init];
    if (self){
        _protocolQueue = dispatch_queue_create("QredoConversationProtocol__protocolQueue",DISPATCH_QUEUE_SERIAL);
        self.conversation = conversation;
    }
    return self;
}


-(void)startObservingConversation {
    if (_isObservingConversation){
        NSAssert1(TRUE,@"Attempting to start observing a conversation in %@ while the conversation is already observed.",NSStringFromClass([self class]));
        return;
    }
    [self.conversation addConversationObserver:self];
    _isObservingConversation = YES;
}


-(void)stopObservingConversation {
    if (!_isObservingConversation){
        NSAssert1(TRUE,@"Attempting to stop observing a conversation in %@ while the conversation is not being observed.",NSStringFromClass([self class]));
        return;
    }
    
    [self.conversation removeConversationObserver:self];
    _isObservingConversation = NO;
}


#pragma mark Event handling

-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature){
        signature = [self.currentState methodSignatureForSelector:aSelector];
    }
    return signature;
}


-(void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation retainArguments];
    
    if (![self.currentState respondsToSelector:[anInvocation selector]]){
        [super forwardInvocation:anInvocation];
        return;
    }
    
    if (anInvocation.methodSignature.methodReturnLength > 0){
        [anInvocation invokeWithTarget:self.currentState];
        return;
    }
    
    dispatch_async(self.protocolQueue,^{
        [anInvocation invokeWithTarget:self.currentState];
    });
}


-(void)switchToState:(QredoConversationProtocolState *)state withConfigBlock:(dispatch_block_t)configBlock {
    NSAssert(state != nil,@"State is not initialized");
    [state prepareForReuseWithConversationProtocol:self configBlock:configBlock];
    [_currentState willExit];
    _currentState = state;
    [_currentState didEnter];
}


#pragma mark QredoConversationObserver implementation

-(void)qredoConversation:(QredoConversation *)conversation
    didReceiveNewMessage:(QredoConversationMessage *)message {
    [self didReceiveConversationMessage:message];
}


-(void)qredoConversationOtherPartyHasLeft:(QredoConversation *)conversation {
    [self otherPartyHasLeftConversation];
}


@end


#pragma GCC diagnostic push
#pragma clang diagnostic push

#pragma GCC diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wprotocol"

@implementation QredoConversationProtocol (Events)
@end

@implementation QredoConversationProtocol (PrivateEvents)
@end

#pragma clang diagnostic pop
#pragma GCC diagnostic pop
