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



//==============================================================================================================
#pragma mark - State interfaces -
//==============================================================================================================


@interface QredoClaimantAttestationState()
@property (nonatomic, readonly) QredoClaimantAttestationProtocol *claimantAttestationProtocol;
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_Start : QredoClaimantAttestationState
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_RequestingPresentaion : QredoClaimantAttestationState
@property (nonatomic) NSError *error;
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_WaitingForPresentaions : QredoClaimantAttestationState
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_Authenticate : QredoClaimantAttestationState<QredoAuthenticationProtocolDelegate>
@property (nonatomic) QredoPresentation *presentation;
@property (nonatomic) QredoAuthenticationProtocol *authenticationProtocol;
@property (nonatomic) QredoAuthenticationResponse *authenticationResponse;
@property (nonatomic) NSError *authenticationError;
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_AuthenticationResultsReceived : QredoClaimantAttestationState
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_SendRelyingPartyChoice : QredoClaimantAttestationState
@property (nonatomic) BOOL claimsAccepted;
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_RelyingPartyChoiceSent : QredoClaimantAttestationState
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_CancelConversation : QredoClaimantAttestationState
@property (nonatomic) NSError *error;
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_CanceledByClaimant : QredoClaimantAttestationState
@property (nonatomic) NSError *error;
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState_Finish : QredoClaimantAttestationState
@end



//==============================================================================================================
#pragma mark - Protocol interface -
//==============================================================================================================


@interface QredoClaimantAttestationProtocol()

@property (nonatomic) QredoClaimantAttestationState_Start *startState;
@property (nonatomic) QredoClaimantAttestationState_RequestingPresentaion *requestingPresentaionState;
@property (nonatomic) QredoClaimantAttestationState_WaitingForPresentaions *waitingForPresentaionsState;
@property (nonatomic) QredoClaimantAttestationState_Authenticate *presentaionsRecievedState;
@property (nonatomic) QredoClaimantAttestationState_AuthenticationResultsReceived *authenticationResultsReceivedState;
@property (nonatomic) QredoClaimantAttestationState_SendRelyingPartyChoice *sendRelyingPartyChoiceState;
@property (nonatomic) QredoClaimantAttestationState_RelyingPartyChoiceSent *relyingPartyChoiceSentState;
@property (nonatomic) QredoClaimantAttestationState_CancelConversation *cancelConversationState;
@property (nonatomic) QredoClaimantAttestationState_CanceledByClaimant *canceledByClaimantState;
@property (nonatomic) QredoClaimantAttestationState_Finish *finishState;

@property (nonatomic, copy) NSSet *attestationTypes;
@property (nonatomic, copy) NSString *authenticator;

@property (nonatomic) QredoAuthenticationProtocol *authenticationProtocol;

@end



//==============================================================================================================
#pragma mark - State implementations -
//==============================================================================================================


@implementation QredoClaimantAttestationState


- (QredoClaimantAttestationProtocol *)claimantAttestationProtocol
{
    return (QredoClaimantAttestationProtocol *)self.conversationProtocol;
}


#pragma mark Events

- (void)start
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         // TODO [GR]: Set the correct error on the next line.
         self.claimantAttestationProtocol.cancelConversationState.error = nil;
     }];
}

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

- (void)authenticationResultsRecievedWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         // TODO [GR]: Set the correct error on the next line.
         self.claimantAttestationProtocol.cancelConversationState.error = nil;
     }];
}

- (void)relyingPartyChioiceSentWithError:(NSError *)error
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


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@implementation QredoClaimantAttestationState_Start

- (void)start
{
    [self.conversationProtocol.conversation startListening];
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.requestingPresentaionState
                                   withConfigBlock:^{}];
}

@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@implementation QredoClaimantAttestationState_RequestingPresentaion

- (void)prepareForReuse
{
    [super prepareForReuse];
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
    NSSet *attestationTypes = self.claimantAttestationProtocol.attestationTypes;
    NSString *authenticator = self.claimantAttestationProtocol.authenticator;
    
    QredoPresentationRequest *presentationRequest
    = [[QredoPresentationRequest alloc] initWithRequestedAttestationTypes:attestationTypes
                                                            authenticator:authenticator];
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


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

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


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@implementation QredoClaimantAttestationState_Authenticate

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.presentation = nil;
    self.authenticationProtocol = nil;
    self.authenticationResponse = nil;
    self.authenticationError = nil;
}

- (void)didEnter
{
    [super didEnter];
    
    NSError *error = nil;
    
    self.authenticationProtocol = [self createAuthenticationProtocolWithError:&error];
    if (self.authenticationProtocol) {
        
        self.authenticationProtocol.delegate = self;
        if (![self sendAuthenticationRequestWithError:&error]) {
            [self authenticationResultsRecievedWithError:error];
        };
        
    } else {
        [self authenticationResultsRecievedWithError:error];
    }
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                    didRecivePresentations:self.presentation];
}

- (void)willExit
{
    [super willExit];
    self.authenticationProtocol.delegate = nil;
    // TODO [GR]: Think of other things to cancel or nil here.
    
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                          didFinishAuthenticationWithError:self.authenticationError];
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

- (void)authenticationResultsRecievedWithError:(NSError *)error
{
    self.authenticationError = error;
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.authenticationResultsReceivedState
                                    withConfigBlock:nil];
}

#pragma mark Utility methods

- (BOOL)sendAuthenticationRequestWithError:(NSError **)error
{
    NSMutableArray *claimMessages = [[NSMutableArray alloc] init];
    for (QredoAttestation *attestation in self.presentation.attestations) {
        
        NSData *claimHash = attestation.credential.hashedClaim;
        
        QredoClaimMessage *claimMessage
        = [[QredoClaimMessage alloc] initWithClaimHash:claimHash credential:attestation.credential];
        
        [claimMessages addObject:claimMessage];
        
    }
    
    QredoAuthenticationRequest *authenticationRequest
    = [[QredoAuthenticationRequest alloc] initWithClaimMessages:claimMessages conversationSecret:nil];
    
    [self.authenticationProtocol sendAuthenticationRequest:authenticationRequest];
    
    return YES;
}

- (QredoAuthenticationProtocol *)createAuthenticationProtocolWithError:(NSError **)error
{
    return [self.claimantAttestationProtocol.dataSource claimantAttestationProtocol:self.claimantAttestationProtocol
                                                    authenticationProtocolWithError:error];
}

#pragma mark QredoAuthenticationProtocolDelegate methods

- (void)qredoAuthenticationProtocolDidSendClaims:(QredoAuthenticationProtocol *)protocol
{
    // Ignored
}

- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error
{
    [self.claimantAttestationProtocol authenticationResultsRecievedWithError:error];
}

- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol
               didFinishWithResults:(QredoAuthenticationResponse *)results
{
    self.authenticationResponse = results;
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                  didReciveAuthentications:self.authenticationResponse];
    [self.claimantAttestationProtocol authenticationResultsRecievedWithError:nil];
}

@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@implementation QredoClaimantAttestationState_AuthenticationResultsReceived

- (void)prepareForReuse
{
    [super prepareForReuse];
}

- (void)didEnter
{
    [super didEnter];
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


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

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
        [self.claimantAttestationProtocol relyingPartyChioiceSentWithError:error];
    }];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                         didStartSendingRelyingPartyChoice:self.claimsAccepted];
}

#pragma mark Events

- (void)relyingPartyChioiceSentWithError:(NSError *)error
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


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@implementation QredoClaimantAttestationState_RelyingPartyChoiceSent

- (void)didEnter
{
    [super didEnter];
    [self cancelConversationWithCompletionHandler:^(NSError *error) {
        [self.claimantAttestationProtocol conversationCanceledWithError:error];
    }];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocolDidFinishSendingRelyingPartyChoice:self.claimantAttestationProtocol];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol didFinishWithError:nil];
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


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

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
- (void)relyingPartyChioiceSentWithError:(NSError *)error {}

- (void)conversationCanceledWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.finishState
                                    withConfigBlock:nil];
}

- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error {}

- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol
               didFinishWithResults:(QredoAuthenticationResponse *)results {}


#pragma mark Utility methods

- (void)cancelConversationWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self.claimantAttestationProtocol.conversation deleteConversationWithCompletionHandler:^(NSError *error) {
        completionHandler(error);
    }];
}

@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

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
- (void)relyingPartyChioiceSentWithError:(NSError *)error {}
- (void)conversationCanceledWithError:(NSError *)error {}
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error {}
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol
               didFinishWithResults:(QredoAuthenticationResponse *)results {}

@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@implementation QredoClaimantAttestationState_Finish

- (void)didEnter
{
    [super didEnter];
    [self.conversationProtocol.conversation stopListening];

}

#pragma mark Events

- (void)accept {}
- (void)reject {}
- (void)cancel {}
- (void)presentationRequestPublishedWithError:(NSError *)error {}
- (void)relyingPartyChioiceSentWithError:(NSError *)error {}
- (void)conversationCanceledWithError:(NSError *)error {}
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error {}
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol
               didFinishWithResults:(QredoAuthenticationResponse *)results {}

@end



//==============================================================================================================
#pragma mark - Protocol implementation -
//==============================================================================================================


@implementation QredoClaimantAttestationProtocol

- (instancetype)initWithConversation:(QredoConversation *)conversation
                    attestationTypes:(NSSet *)attestationTypes
                       authenticator:(NSString *)authenticator
{
    self = [super initWithConversation:conversation];
    if (self) {
        
        self.attestationTypes = attestationTypes;
        self.authenticator = authenticator;
        
        self.startState = [QredoClaimantAttestationState_Start new];
        self.requestingPresentaionState = [QredoClaimantAttestationState_RequestingPresentaion new];
        self.waitingForPresentaionsState = [QredoClaimantAttestationState_WaitingForPresentaions new];
        self.presentaionsRecievedState = [QredoClaimantAttestationState_Authenticate new];
        self.authenticationResultsReceivedState = [QredoClaimantAttestationState_AuthenticationResultsReceived new];
        self.sendRelyingPartyChoiceState = [QredoClaimantAttestationState_SendRelyingPartyChoice new];
        self.relyingPartyChoiceSentState = [QredoClaimantAttestationState_RelyingPartyChoiceSent new];
        self.cancelConversationState = [QredoClaimantAttestationState_CancelConversation new];
        self.canceledByClaimantState = [QredoClaimantAttestationState_CanceledByClaimant new];
        self.finishState = [QredoClaimantAttestationState_Finish new];
        
        [self switchToState:self.startState withConfigBlock:^{}];
        
    }
    return self;
}

@end



#pragma GCC diagnostic push
#pragma clang diagnostic push

#pragma GCC diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wprotocol"

@implementation QredoClaimantAttestationProtocol(Events)
@end

#pragma clang diagnostic pop
#pragma GCC diagnostic pop


