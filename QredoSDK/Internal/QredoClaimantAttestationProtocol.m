/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoClaimantAttestationProtocol.h"
#import "QredoConversationMessage.h"


static NSString *kAttestationPresentationRequestMessageType = @"com.qredo.attestation.presentation.request";
static NSString *kAttestationPresentationMessageType = @"com.qredo.attestation.presentation";



#pragma mark Interfaces

@interface QredoClaimantAttestationState()
@property (nonatomic, readonly) QredoClaimantAttestationProtocol *claimantAttestationProtocol;
@end


@interface QredoClaimantAttestationState_RequestingPresentaion : QredoClaimantAttestationState
@end

@interface QredoClaimantAttestationState_WaitingForPresentaions : QredoClaimantAttestationState
@end

@interface QredoClaimantAttestationState_PresentaionsRecieved : QredoClaimantAttestationState
@property (nonatomic, copy) NSArray *presentations;
@end

@interface QredoClaimantAttestationState_AuthenticationResultsReceived : QredoClaimantAttestationState
@property (nonatomic, copy) NSArray *authentications;
@end

@interface QredoClaimantAttestationState_SendRelyingPartyChoice : QredoClaimantAttestationState
@property (nonatomic) BOOL claimsAccepted;
@end

@interface QredoClaimantAttestationState_RelyingPartyChoiceSent : QredoClaimantAttestationState
@end

@interface QredoClaimantAttestationState_CancelConversation : QredoClaimantAttestationState
@property (nonatomic) NSError *error;
@end

@interface QredoClaimantAttestationState_CanceledByClaimant : QredoClaimantAttestationState
@property (nonatomic) NSError *error;
@end

@interface QredoClaimantAttestationState_Finish : QredoClaimantAttestationState
@end


@interface QredoClaimantAttestationProtocol()

@property (nonatomic) QredoClaimantAttestationState_RequestingPresentaion *requestingPresentaionState;
@property (nonatomic) QredoClaimantAttestationState_WaitingForPresentaions *waitingForPresentaionsState;
@property (nonatomic) QredoClaimantAttestationState_PresentaionsRecieved *presentaionsRecievedState;
@property (nonatomic) QredoClaimantAttestationState_AuthenticationResultsReceived *authenticationResultsReceivedState;
@property (nonatomic) QredoClaimantAttestationState_SendRelyingPartyChoice *sendRelyingPartyChoiceState;
@property (nonatomic) QredoClaimantAttestationState_RelyingPartyChoiceSent *relyingPartyChoiceSentState;
@property (nonatomic) QredoClaimantAttestationState_CancelConversation *cancelConversationState;
@property (nonatomic) QredoClaimantAttestationState_CanceledByClaimant *canceledByClaimantState;
@property (nonatomic) QredoClaimantAttestationState_Finish *finishState;

@end



#pragma mark Implementations

@implementation QredoClaimantAttestationState


- (QredoClaimantAttestationProtocol *)claimantAttestationProtocol
{
    return (QredoClaimantAttestationProtocol *)self.conversationProtocol;
}


#pragma mark Events

- (void)accept
{
    // TODO [GR]: Send to error state
}

- (void)reject
{
    // TODO [GR]: Send to error state
}

- (void)cancel
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:nil];
}


- (void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         // TODO [GR]: Set the correct error on the next line.
         self.claimantAttestationProtocol.cancelConversationState.error = nil;
     }];
}

- (void)didReceiveCancelConversationMessageWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.canceledByClaimantState
                                    withConfigBlock:^
     {
         self.claimantAttestationProtocol.canceledByClaimantState.error = error;
     }];
}


- (void)presentationRequestPublishedWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         // TODO [GR]: Set the correct error on the next line.
         self.claimantAttestationProtocol.cancelConversationState.error = nil;
     }];
}

- (void)sendAtestationChioiceCompletedWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         // TODO [GR]: Set the correct error on the next line.
         self.claimantAttestationProtocol.cancelConversationState.error = nil;
     }];
}

- (void)conversationCanceledWithError:(NSError *)error
{
    // TODO [GR]: Decide on what is the wright thing to do here.
    // We probably need to ignore this.
}

@end


@implementation QredoClaimantAttestationState_RequestingPresentaion

- (void)didEnter
{
    [super didEnter];
    [self publishPresentationRequestWithCompletionHandler:^(NSError *error) {
        [self.claimantAttestationProtocol presentationRequestPublishedWithError:error];
    }];
    [self.claimantAttestationProtocol.delegate
     didStartClaimantAttestationProtocol:self.claimantAttestationProtocol];
}


#pragma mark Events

- (void)accept
{
    // TODO [GR]: Send to error state
}

- (void)reject
{
    // TODO [GR]: Send to error state
}

- (void)presentationRequestPublishedWithError:(NSError *)error
{
    if (error) {
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                        withConfigBlock:^
         {
             self.claimantAttestationProtocol.cancelConversationState.error = error;
         }];
    } else {
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.waitingForPresentaionsState
                                        withConfigBlock:nil];
    }
}


#pragma mark Utility methods

- (void)publishPresentationRequestWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    // TODO [GR]: Implement this.
}

@end

@implementation QredoClaimantAttestationState_WaitingForPresentaions

- (void)didEnter
{
    [super didEnter];
    
}

#pragma mark Events

- (void)accept
{
    // TODO [GR]: Send to error state
}

- (void)reject
{
    // TODO [GR]: Send to error state
}

- (void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message
{
    if ([message.dataType isEqualToString:kAttestationPresentationMessageType]) {
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.presentaionsRecievedState
                                        withConfigBlock:^
         {
             self.claimantAttestationProtocol.presentaionsRecievedState.presentations
             = [self presentationsFromMessage:message];
         }];
        
    } else {
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                        withConfigBlock:^
         {
             // TODO [GR]: Pass the correct error to cancel conversation state.
             self.claimantAttestationProtocol.cancelConversationState.error = nil;
         }];
    }
}

- (void)presentationRequestPublishedWithError:(NSError *)error
{
    // TODO [GR]: Send to error state
}


#pragma mark Utility methods

- (NSArray *)presentationsFromMessage:(QredoConversationMessage *)message
{
    // TODO [GR]: Implement this.
    return nil;
}

@end

@implementation QredoClaimantAttestationState_PresentaionsRecieved

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.presentations = nil;
}

- (void)didEnter
{
    [super didEnter];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                    didRecivePresentations:self.presentations];
}

#pragma mark Events

- (void)accept
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.sendRelyingPartyChoiceState
                                    withConfigBlock:^
    {
        self.claimantAttestationProtocol.sendRelyingPartyChoiceState.claimsAccepted = YES;
    }];
}

- (void)reject
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.sendRelyingPartyChoiceState
                                    withConfigBlock:^
     {
         self.claimantAttestationProtocol.sendRelyingPartyChoiceState.claimsAccepted = NO;
     }];
}

@end

@implementation QredoClaimantAttestationState_AuthenticationResultsReceived

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.authentications = nil;
}

- (void)didEnter
{
    [super didEnter];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                  didReciveAuthentications:self.authentications];
}

#pragma mark Events

- (void)accept
{
    [self.conversationProtocol switchToState:self.claimantAttestationProtocol.sendRelyingPartyChoiceState
                             withConfigBlock:^
     {
         self.claimantAttestationProtocol.sendRelyingPartyChoiceState.claimsAccepted = YES;
     }];
}

- (void)reject
{
    [self.conversationProtocol switchToState:self.claimantAttestationProtocol.sendRelyingPartyChoiceState
                             withConfigBlock:^
    {
        self.claimantAttestationProtocol.sendRelyingPartyChoiceState.claimsAccepted = NO;
    }];
}

@end

@implementation QredoClaimantAttestationState_SendRelyingPartyChoice

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.claimsAccepted = NO;
}

- (void)didEnter
{
    [super didEnter];
    [self sendRelyingPartyChoiceWithCompletionHandler:^(NSError *error) {
        [self.claimantAttestationProtocol sendAtestationChioiceCompletedWithError:error];
    }];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                         didStartSendingRelyingPartyChoice:self.claimsAccepted];
}

#pragma mark Events

- (void)sendAtestationChioiceCompletedWithError:(NSError *)error
{
    if (error) {
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                        withConfigBlock:^
         {
             // TODO [GR]: Set the correct error on the next line.
             self.claimantAttestationProtocol.cancelConversationState.error = nil;
         }];
    } else {
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.relyingPartyChoiceSentState
                                        withConfigBlock:^{}];
    }
}


#pragma mark Utility methods

- (void)sendRelyingPartyChoiceWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    // TODO [GR]: Implement this.
}

@end

@implementation QredoClaimantAttestationState_RelyingPartyChoiceSent

- (void)didEnter
{
    [super didEnter];
    [self cancelConversationWithCompletionHandler:^(NSError *error) {
        [self.claimantAttestationProtocol conversationCanceledWithError:error];
    }];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocolDidFinishSendingRelyingPartyChoice:self.claimantAttestationProtocol];
}

#pragma mark Events

- (void)didReceiveCancelConversationMessageWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.finishState
                                    withConfigBlock:nil];
}

#pragma mark Utility methods

- (void)cancelConversationWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    // TODO [GR]: Implement this.
}

@end

@implementation QredoClaimantAttestationState_CancelConversation
- (void)prepareForReuse
{
    [super prepareForReuse];
    self.error = nil;
}

- (void)didEnter
{
    [super didEnter];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                        didFinishWithError:self.error];
}

#pragma mark Events

- (void)accept {}
- (void)reject {}
- (void)cancel {}
- (void)presentationRequestPublishedWithError:(NSError *)error {}
- (void)sendAtestationChioiceCompletedWithError:(NSError *)error {}

- (void)conversationCanceledWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.finishState
                                    withConfigBlock:nil];
}

@end

@implementation QredoClaimantAttestationState_CanceledByClaimant

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.error = nil;
}

- (void)didEnter
{
    [super didEnter];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                        didFinishWithError:self.error];
}

#pragma mark Events

- (void)accept {}
- (void)reject {}
- (void)cancel {}
- (void)presentationRequestPublishedWithError:(NSError *)error {}
- (void)sendAtestationChioiceCompletedWithError:(NSError *)error {}
- (void)conversationCanceledWithError:(NSError *)error {}

@end

@implementation QredoClaimantAttestationState_Finish

#pragma mark Events

- (void)accept {}
- (void)reject {}
- (void)cancel {}
- (void)presentationRequestPublishedWithError:(NSError *)error {}
- (void)sendAtestationChioiceCompletedWithError:(NSError *)error {}
- (void)conversationCanceledWithError:(NSError *)error {}

@end



#pragma GCC diagnostic push
#pragma clang diagnostic push

#pragma GCC diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wprotocol"

@implementation QredoClaimantAttestationProtocol

- (instancetype)initWithConversation:(QredoConversation *)conversation
{
    self = [super init];
    if (self) {
        self.authenticationResultsReceivedState = [QredoClaimantAttestationState_AuthenticationResultsReceived new];
        self.sendRelyingPartyChoiceState = [QredoClaimantAttestationState_SendRelyingPartyChoice new];
    }
    return self;
}

@end


#pragma clang diagnostic pop
#pragma GCC diagnostic pop


