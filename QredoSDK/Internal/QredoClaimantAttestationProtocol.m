/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoClaimantAttestationProtocol.h"
#import "QredoConversation.h"
#import "QredoConversationMessage.h"
#import "QredoAttestationInternal.h"
#import <QredoClient.h>
#import <QredoPrimitiveMarshallers.h>
#import <QredoClientMarshallers.h>


static NSString *KAttestationClaimantConversationType = @"com.qredo.attesation.relyingparty";

static NSString *kAttestationPresentationRequestMessageType = @"com.qredo.attestation.presentation.request";
static NSString *kAttestationPresentationMessageType = @"com.qredo.attestation.presentation";

static NSString *kAttestationRelyingPartyChoiceMessageType = @"com.qredo.attestation.relyingparty.decision";
static NSString *kAttestationRelyingPartyChoiceAccepted = @"ACCEPTED";
static NSString *kAttestationRelyingPartyChoiceRejected = @"REJECTED";





#pragma mark Interfaces

@interface QredoClaimantAttestationState()
@property (nonatomic, readonly) QredoClaimantAttestationProtocol *claimantAttestationProtocol;
@end


@interface QredoClaimantAttestationState_RequestingPresentaion : QredoClaimantAttestationState
@property (nonatomic, copy) NSSet *attestationTypes;
@property (nonatomic, copy) NSString *authenticator;
@end

@interface QredoClaimantAttestationState_WaitingForPresentaions : QredoClaimantAttestationState
@end

@interface QredoClaimantAttestationState_PresentaionsRecieved : QredoClaimantAttestationState
@property (nonatomic) QredoPresentation *presentation;
@end

@interface QredoClaimantAttestationState_AuthenticationResultsReceived : QredoClaimantAttestationState
@property (nonatomic, copy) QredoAuthenticationResponse *authentications;
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
         self.claimantAttestationProtocol.cancelConversationState.error = error;
     }];
}

- (void)sendAtestationChioiceCompletedWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         self.claimantAttestationProtocol.cancelConversationState.error = error;
     }];
}

- (void)conversationCanceledWithError:(NSError *)error
{
    // TODO [GR]: Decide on what is the wright thing to do here.
    // We probably need to ignore this.
}

@end


@implementation QredoClaimantAttestationState_RequestingPresentaion

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.attestationTypes = nil;
    self.authenticator = nil;
}

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
    QredoPresentationRequest *presentationRequest
    = [[QredoPresentationRequest alloc] initWithRequestedAttestationTypes:self.attestationTypes
                                                            authenticator:self.authenticator];
    NSData *messageValue
    = [QredoPrimitiveMarshallers marshalObject:presentationRequest
                                    marshaller:[QredoClientMarshallers presentationRequestMarshaller]];
    
    QredoConversationMessage *message
    = [[QredoConversationMessage alloc] initWithValue:messageValue
                                             dataType:kAttestationPresentationRequestMessageType
                                        summaryValues:nil];
    
    [self.conversationProtocol.conversation publishMessage:message
                                         completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error)
     {
         completionHandler(error);
     }];
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
    NSError *error = nil;
    
    QredoPresentation *presentation = [self presentationFromMessage:message error:&error];
    if (presentation) {
        
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.presentaionsRecievedState
                                        withConfigBlock:^
         {
             self.claimantAttestationProtocol.presentaionsRecievedState.presentation = presentation;
         }];
        
    } else {
        
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                        withConfigBlock:^
         {
             self.claimantAttestationProtocol.cancelConversationState.error = error;
         }];
        
    }
}

#pragma mark Utility methods

- (QredoPresentation *)presentationFromMessage:(QredoConversationMessage *)message error:(NSError **)error
{
    if (![message.dataType isEqualToString:kAttestationPresentationMessageType]) {
        updateQredoClaimantAttestationProtocolError(error, QredoAttestationErrorCodeUnexpectedMessageType, nil);
        return nil;
    }
    
    if ([message.value length] < 1) {
        updateQredoClaimantAttestationProtocolError(error, QredoAttestationErrorCodePresentationMessageDoesNotHaveValue, nil);
        return nil;
    }
    
    QredoPresentation *presentation = nil;
    @try {
        presentation = [QredoPrimitiveMarshallers unmarshalObject:message.value
                                                     unmarshaller:[QredoClientMarshallers presentationUnmarshaller]];
    }
    @catch (NSException *exception) {
        updateQredoClaimantAttestationProtocolError(error, QredoAttestationErrorCodePresentationMessageHasCorruptValue, nil);
        presentation = nil;
    }
    @finally {
    }
    
    return presentation;
}

@end

@implementation QredoClaimantAttestationState_PresentaionsRecieved

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.presentation = nil;
}

- (void)didEnter
{
    [super didEnter];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                    didRecivePresentations:self.presentation];
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
             self.claimantAttestationProtocol.cancelConversationState.error = error;
         }];
    } else {
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.relyingPartyChoiceSentState
                                        withConfigBlock:^{}];
    }
}


#pragma mark Utility methods

- (void)sendRelyingPartyChoiceWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSString *choiceString
    = self.claimsAccepted ? kAttestationRelyingPartyChoiceAccepted : kAttestationRelyingPartyChoiceRejected;
    
    NSData *messageValue = [choiceString dataUsingEncoding:NSUTF8StringEncoding];
    
    QredoConversationMessage *message
    = [[QredoConversationMessage alloc] initWithValue:messageValue
                                             dataType:kAttestationRelyingPartyChoiceMessageType
                                        summaryValues:nil];
    
    [self.claimantAttestationProtocol.conversation publishMessage:message
                                                completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error)
    {
        completionHandler(error);
    }];
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

- (void)conversationCanceledWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.finishState
                                    withConfigBlock:nil];
}

#pragma mark Utility methods

- (void)cancelConversationWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self.claimantAttestationProtocol.conversation deleteConversationWithCompletionHandler:^(NSError *error) {
        completionHandler(error);
    }];
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
    [self cancelConversationWithCompletionHandler:^(NSError *error) {
        [self.claimantAttestationProtocol conversationCanceledWithError:error];
    }];
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

#pragma mark Utility methods

- (void)cancelConversationWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self.claimantAttestationProtocol.conversation deleteConversationWithCompletionHandler:^(NSError *error) {
        completionHandler(error);
    }];
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
                    attestationTypes:(NSSet *)attestationTypes
                       authenticator:(NSString *)authenticator
{
    self = [super initWithConversation:conversation];
    if (self) {
        
        self.requestingPresentaionState = [QredoClaimantAttestationState_RequestingPresentaion new];
        self.waitingForPresentaionsState = [QredoClaimantAttestationState_WaitingForPresentaions new];
        self.presentaionsRecievedState = [QredoClaimantAttestationState_PresentaionsRecieved new];
        self.authenticationResultsReceivedState = [QredoClaimantAttestationState_AuthenticationResultsReceived new];
        self.sendRelyingPartyChoiceState = [QredoClaimantAttestationState_SendRelyingPartyChoice new];
        self.relyingPartyChoiceSentState = [QredoClaimantAttestationState_RelyingPartyChoiceSent new];
        self.cancelConversationState = [QredoClaimantAttestationState_CancelConversation new];
        self.canceledByClaimantState = [QredoClaimantAttestationState_CanceledByClaimant new];
        self.finishState = [QredoClaimantAttestationState_Finish new];
        
        [self switchToState:self.requestingPresentaionState withConfigBlock:^{
            self.requestingPresentaionState.attestationTypes = attestationTypes;
            self.requestingPresentaionState.authenticator = authenticator;
        }];
        
    }
    return self;
}

@end


#pragma clang diagnostic pop
#pragma GCC diagnostic pop


