@class QredoConversationProtocol;

@interface QredoConversationProtocolState : NSObject

@property (readonly) QredoConversationProtocol *protocol;

- (instancetype)initWithBlock:(void(^)())block;

- (void)onEnter; // calls the block from initWithBlock
- (void)didReceiveMessage:(QredoConversationMessage *)message;

@end

@interface QredoConversationProtocol : NSObject

@property (nonatomic) QredoConversationProtocolState *currentState;

// public
- (instancetype)initWithConversation:(QredoConversation *)conversation states:(NSDictionary /* string, QredoProtocolState */ *)states;

- (void)switchToStateWithName:(NSString *)stateName;

- (QredoConversationProtocolState *)stateForName:(NSString*)stateName;

- (void)cancelWithError:(NSError *)error; // send cancel message. message type in property?

// protected
- (void)didReceiveCancelMessage; // -> if state defines, otherwise common logic
- (void)didReceiveMessage:(QredoConversationMessage *)message; // -> state

@end

@protocol QredoClaimantAttestationDelegate <NSObject>
// connects with UI (similar to the delegates in the keychain transporter
@end

@interface QredoClaimantAttestationProtocol : QredoConversationProtocol

@property id<QredoClaimantAttestationDelegate> uiDelegate;

- (void)switchToReceivedPresentationsStateWithPresentation:(NSArray *)presentations;

@end

@interface QredoClaimantAttestationReceivedAuthenticationState : QredoConversationProtocolState

@end

@class QredoClaimantAttestationProtocol;

@implementation QredoClaimantAttestationReceivedAuthenticationState

- (void)onEnter {
    QredoClaimantAttestationProtocol *protocol;
}

@end

@implementation QredoClaimantAttestationProtocol

- (void)switchToReceivedPresentationsStateWithPresentation:(NSArray *)presentations
{
    self.currentState = [[QredoConversationProtocolState alloc] initWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate updateUIPresentations:presentations];
        });
    }];
}

- (instancetype)initWithConversation:(QredoConversation *)conversation states:(NSDictionary *)states
{

    QredoConversationProtocolState *waitingForPresentationState = [[QredoConversationProtocolState alloc] initWithBlock:^{

    }];

    QredoConversationProtocolState *authenticating = [[QredoConversationProtocolState alloc] initWithBlock:^{}];

    self = [super initWithConversation:conversation states:states];
}

@end
