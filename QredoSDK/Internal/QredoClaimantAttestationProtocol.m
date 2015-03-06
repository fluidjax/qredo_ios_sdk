/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoClaimantAttestationProtocol.h"
#import "QredoConversation.h"
#import "QredoConversationMessage.h"
#import "QredoAttestationInternal.h"
#import "QredoCrypto.h"
#import <QredoClient.h>
#import <QredoPrimitiveMarshallers.h>
#import <QredoClientMarshallers.h>
#import "QredoErrorCodes.h"


static NSString *kAttestationPresentationCancelMessageType = @"com.qredo.attestation.demo.presentation.cancel";
static NSString *kAttestationPresentationRequestMessageType = @"com.qredo.attestation.demo.presentation.request";
static NSString *kAttestationPresentationMessageType = @"com.qredo.attestation.demo.presentation";

static NSString *kAttestationRelyingPartyChoiceMessageType = @"com.qredo.attestation.demo.relyingparty.decision";
static NSString *kAttestationRelyingPartyChoiceAccepted = @"ACCEPTED";
static NSString *kAttestationRelyingPartyChoiceRejected = @"REJECTED";


static const NSTimeInterval kWaitingForPresentationTimeout = 60;
static const NSTimeInterval kAuthenticateTimeout = 60;


//==============================================================================================================
#pragma mark - Private events -
//==============================================================================================================

@protocol QredoClaimantAttestationProtocolPrivateEvents <NSObject>

- (void)authenticationFinishedWithResponse:(QredoAuthenticationResponse *)authenticationResponse
                                     error:(NSError *)error;

@end

//==============================================================================================================
#pragma mark - State interfaces -
//==============================================================================================================


@interface QredoClaimantAttestationState()<QredoClaimantAttestationProtocolPrivateEvents>
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

@interface QredoClaimantAttestationState_Authenticate : QredoClaimantAttestationState
@property (nonatomic) QredoPresentation *presentation;
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
@property (nonatomic) NSError *error;
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

@interface QredoClaimantAttestationProtocol(PrivateEvents)<QredoClaimantAttestationProtocolPrivateEvents>
@end



//==============================================================================================================
#pragma mark - State implementations -
//==============================================================================================================


@implementation QredoClaimantAttestationState

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.cancelMessageType = kAttestationPresentationCancelMessageType;

    return self;
}

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
         NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                              code:QredoErrorCodeConversationProtocolWrongState
                                          userInfo:nil];
         
         self.claimantAttestationProtocol.cancelConversationState.error = error;
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
         NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                              code:QredoErrorCodeConversationProtocolWrongState
                                          userInfo:nil];
         
         self.claimantAttestationProtocol.cancelConversationState.error = error;
     }];
}

- (void)conversationCanceledWithMessage:(QredoConversationMessage *)message
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.canceledByClaimantState
                                    withConfigBlock:^
     {
         NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                              code:QredoErrorCodeConversationProtocolCancelledByOtherSide
                                          userInfo:
                           @{
                             NSLocalizedDescriptionKey: NSLocalizedString(@"Cancelled by claimant.", @"Localized error description")
                             }];
         
         self.claimantAttestationProtocol.canceledByClaimantState.error = error;
     }];
}

- (void)presentationRequestPublishedWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         NSError *localError = [NSError errorWithDomain:QredoErrorDomain
                                              code:QredoErrorCodeConversationProtocolWrongState
                                          userInfo:nil];

         self.claimantAttestationProtocol.cancelConversationState.error = localError;
     }];
}

- (void)authenticationFinishedWithResponse:(QredoAuthenticationResponse *)authenticationResponse
                                     error:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         NSError *localError = [NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeConversationProtocolWrongState
                                               userInfo:nil];
         
         self.claimantAttestationProtocol.cancelConversationState.error = localError;
     }];
}

- (void)relyingPartyChoiceSentWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         NSError *localError = [NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeConversationProtocolWrongState
                                               userInfo:nil];
         
         self.claimantAttestationProtocol.cancelConversationState.error = localError;
     }];
}

- (void)conversationCanceledWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         NSError *localError = [NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeConversationProtocolWrongState
                                               userInfo:nil];
         
         self.claimantAttestationProtocol.cancelConversationState.error = localError;
     }];
}


#pragma mark Info methods

- (BOOL)canCancel
{
    return YES;
}

- (BOOL)canAcceptOrRejct
{
    return NO;
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTimeout:kWaitingForPresentationTimeout];
    }
    return self;
}

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
        
        [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                        didRecivePresentations:presentation];

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

- (void)didTimeout
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
    {
        self.claimantAttestationProtocol.cancelConversationState.error
        = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeConversationProtocolTimeout userInfo:nil];
    }];
}

#pragma mark Utility methods

- (QredoPresentation *)presentationFromMessage:(QredoConversationMessage *)message error:(NSError **)error
{
    if (![message.dataType isEqualToString:kAttestationPresentationMessageType]) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationProtocolUnexpectedMessageType
                                     userInfo:nil];
        }
        return nil;
    }
    
    if ([message.value length] < 1) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationProtocolReceivedMalformedData
                                     userInfo:nil];
        }
        return nil;
    }
    
    QredoPresentation *presentation = nil;
    @try {
        presentation = [QredoPrimitiveMarshallers unmarshalObject:message.value
                                                     unmarshaller:[QredoClientMarshallers presentationUnmarshaller]];
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationProtocolReceivedMalformedData
                                     userInfo:nil];
        }
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTimeout:kAuthenticateTimeout];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.presentation = nil;
    self.authenticationResponse = nil;
    self.authenticationError = nil;
}

- (void)didEnter
{
    [super didEnter];
    
    NSError *error = nil;
    if (![self sendAuthenticationRequestWithError:&error]) {

        if (!error) {
            error = [NSError errorWithDomain:QredoErrorDomain
                                        code:QredoErrorCodeConversationProtocolUnknown
                                    userInfo:nil];
        }

        self.authenticationError = error;
        
        [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                        withConfigBlock:^
        {
            self.claimantAttestationProtocol.cancelConversationState.error = error;
        }];
        
    };
}

- (void)willExit
{
    [super willExit];
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

- (void)authenticationFinishedWithResponse:(QredoAuthenticationResponse *)authenticationResponse
                                     error:(NSError *)error
{
    self.authenticationResponse = authenticationResponse;
    self.authenticationError = error;
    
    if (!error) {
        [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                      didReciveAuthentications:self.authenticationResponse];
    }
    
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.authenticationResultsReceivedState
                                    withConfigBlock:nil];
    
}

- (void)didTimeout
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.cancelConversationState
                                    withConfigBlock:^
     {
         self.authenticationError
         = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeConversationProtocolTimeout userInfo:nil];
         
         [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.authenticationResultsReceivedState
                                         withConfigBlock:nil];
     }];
}

#pragma mark Info methods

- (BOOL)canAcceptOrRejct
{
    return YES;
}

#pragma mark Utility methods

- (BOOL)sendAuthenticationRequestWithError:(NSError **)error
{
    BOOL succeeded = NO;
    
    QredoClaimantAttestationProtocol *protocol = self.claimantAttestationProtocol;
    id<QredoClaimantAttestationProtocolDataSource> dataSource = protocol.dataSource;
    
    
    if (dataSource) {
        
        succeeded = YES;
        
        NSMutableArray *claimMessages = [[NSMutableArray alloc] init];
        for (QredoAttestation *attestation in self.presentation.attestations) {
            
            NSData *claimHash = [self calculateHashOfClaim:attestation.claim error:error];
            if (!claimHash) {
                succeeded = NO;
                break;
            }
            
            QredoClaimMessage *claimMessage = [[QredoClaimMessage alloc] initWithClaimHash:claimHash
                                                                                credential:attestation.credential];
            
            [claimMessages addObject:claimMessage];
        }
        
        if (succeeded) {

            QredoAuthenticationRequest *authenticationRequest
            = [[QredoAuthenticationRequest alloc] initWithClaimMessages:claimMessages conversationSecret:nil];
            
            [dataSource claimantAttestationProtocol:protocol
                                authenticateRequest:authenticationRequest
                                      authenticator:protocol.authenticator
                                  completionHandler:^(QredoAuthenticationResponse *response, NSError *error)
             {
                 [protocol authenticationFinishedWithResponse:response error:error];
             }];
            
        }
        
    } else {
        
        succeeded = NO;
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationProtocolUnknown
                                     userInfo:
                      @{
                        NSLocalizedDescriptionKey:
                            NSLocalizedString(@"Un unkown error has occured.", @"Localized error description"),
                        QredoAttestationErrorTechnicalDescriptionKey:
                            @"The attestation protocol has no data source.",
                        }];
        }
        
    }
    
    return succeeded;
}

- (NSData *)calculateHashOfClaim:(QredoLFClaim *)claim error:(NSError **)error
{
    if (!claim) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationProtocolUnknown
                                     userInfo:
                      @{
                        NSLocalizedDescriptionKey:
                            NSLocalizedString(@"Un unkown error has occured.", @"Localized error description"),
                        QredoAttestationErrorTechnicalDescriptionKey:
                            @"Trying to calculate the hash claim of a claim while the claim is nil.",
                        }];
        }
        return nil;
    }
    
    NSData *claimHash = nil;
    @try {
        NSData *claimData = [QredoPrimitiveMarshallers marshalObject:claim
                                                          marshaller:[QredoClientMarshallers claimMarshaller]];
        claimHash = [QredoCrypto sha256:claimData];
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationProtocolUnknown
                                     userInfo:
                      @{
                        NSLocalizedDescriptionKey:
                            NSLocalizedString(@"Un unkown error has occured.", @"Localized error description"),
                        QredoAttestationErrorTechnicalDescriptionKey:
                            @"An exeption has been raized while trying to hash a claim.",
                        }];
        }
    }
    @finally {
    }
    return claimHash;
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

#pragma mark Info methods

- (BOOL)canAcceptOrRejct
{
    return YES;
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
        [self.claimantAttestationProtocol relyingPartyChoiceSentWithError:error];
    }];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                         didStartSendingRelyingPartyChoice:self.claimsAccepted];
}

#pragma mark Events

- (void)relyingPartyChoiceSentWithError:(NSError *)error
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

#pragma mark Info methods

- (BOOL)canCancel
{
    return NO;
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
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocolDidFinishSendingRelyingPartyChoice:self.claimantAttestationProtocol];
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.finishState
                                    withConfigBlock:nil];
}

#pragma mark Info methods

- (BOOL)canCancel
{
    return NO;
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
}

#pragma mark Events

- (void)didReceiveConversationMessage:(QredoConversationMessage *)message {}
- (void)otherPartyHasLeftConversation {}

- (void)accept {}
- (void)reject {}
- (void)cancel {}
- (void)presentationRequestPublishedWithError:(NSError *)error {}
- (void)relyingPartyChoiceSentWithError:(NSError *)error {}

- (void)conversationCanceledWithError:(NSError *)error
{
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.finishState
                                    withConfigBlock:^
     {
         self.claimantAttestationProtocol.finishState.error = self.error;
     }];
}

- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error {}

- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol
               didFinishWithResults:(QredoAuthenticationResponse *)results {}

#pragma mark Info methods

- (BOOL)canCancel
{
    return NO;
}

#pragma mark Utility methods

- (void)cancelConversationWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self publishCancelMessageWithCompletionHandler:completionHandler];
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
    [self.claimantAttestationProtocol switchToState:self.claimantAttestationProtocol.finishState
                                    withConfigBlock:^
    {
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeConversationProtocolCancelledByOtherSide
                                         userInfo:nil];
        self.claimantAttestationProtocol.finishState.error = error;
    }];
}

#pragma mark Events

- (void)didReceiveConversationMessage:(QredoConversationMessage *)message {}
- (void)otherPartyHasLeftConversation {}

- (void)accept {}
- (void)reject {}
- (void)cancel {}
- (void)presentationRequestPublishedWithError:(NSError *)error {}
- (void)relyingPartyChoiceSentWithError:(NSError *)error {}
- (void)conversationCanceledWithError:(NSError *)error {}
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error {}
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol
               didFinishWithResults:(QredoAuthenticationResponse *)results {}

#pragma mark Info methods

- (BOOL)canCancel
{
    return NO;
}

@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@implementation QredoClaimantAttestationState_Finish

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.error = nil;
}

- (void)didEnter
{
    [super didEnter];
    [self.conversationProtocol.conversation stopListening];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                        didFinishWithError:self.error];
}

#pragma mark Events

- (void)didReceiveConversationMessage:(QredoConversationMessage *)message {}
- (void)otherPartyHasLeftConversation {}

- (void)accept {}
- (void)reject {}
- (void)cancel {}
- (void)presentationRequestPublishedWithError:(NSError *)error {}
- (void)relyingPartyChoiceSentWithError:(NSError *)error {}
- (void)conversationCanceledWithError:(NSError *)error {}
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error {}
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol
               didFinishWithResults:(QredoAuthenticationResponse *)results {}

#pragma mark Info methods

- (BOOL)canCancel
{
    return NO;
}

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

@implementation QredoClaimantAttestationProtocol(EventsAndInfo)
@end

@implementation QredoClaimantAttestationProtocol(PrivateEvents)
@end

#pragma clang diagnostic pop
#pragma GCC diagnostic pop


