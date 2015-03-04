/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoClaimantAttestationSession.h"
#import "QredoClaimantAttestationSessionPrivate.h"

#import "QredoConversationPrivate.h"

static NSString *const kQredoAttestationRendezvousTag = @"MEGAVISA15";


@implementation QredoAuthenticationResult
@end

@implementation QredoClaim
@end


@implementation QredoClaimantAttestationSession

- (instancetype)initWithConversation:(QredoConversation *)conversation
                    attestationTypes:(NSSet *)attestationTypes
                       authenticator:(NSString *)authenticator
{
    self = [super init];
    if (!self) return nil;

    self.client = conversation.client;

    self.attestationProtocol = [[QredoClaimantAttestationProtocol alloc] initWithConversation:conversation
                                                                             attestationTypes:attestationTypes
                                                                                authenticator:authenticator];

    self.attestationProtocol.delegate = self;
    self.attestationProtocol.dataSource = self;

    return self;
}

- (void)startAuthentication
{
    [self.attestationProtocol start];
}

- (void)cancelWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    // 1. check if we are on the right state (not at Start, Finish or Relying Party Choice Sent) -> protocol.canCancelNow
    // 2. if not, then call completionHandler(error=wrong state)
    // 3. if ok, store the completionHandler
    // 4. call the completionHandler from didFinishWithError

    if (![self.attestationProtocol canCancel]) {
        completionHandler([NSError errorWithDomain:QredoErrorDomain
                                              code:QredoErrorCodeConversationProtocolWrongState
                                          userInfo:@{NSLocalizedDescriptionKey : @"Can't cancel at this state"}]);
        return;
    }

    [self.attestationProtocol cancelWithWrongStateHandler:^(NSError *error) {
        if (!error) {
            sendResultsCompletionHandler = completionHandler;
        } else {
            if (completionHandler) {
                completionHandler(error);
            }
        }
    }];
}

- (void)finishAttestationWithResult:(BOOL)result completionHandler:(void(^)(NSError *error))completionHandler
{
    // 1. check if we are on the right state -> protocol.canSetResult
    // 2. if not, then call completionHandler(error=wrong state)
    // 3. if ok, store the completionHandler
    // 4. call the completionHandler from claimantAttestationProtocolDidFinishSendingRelyingPartyChoice

    if (![self.attestationProtocol canAcceptOrRejct]) {
        completionHandler([NSError errorWithDomain:QredoErrorDomain
                                              code:QredoErrorCodeConversationProtocolWrongState
                                          userInfo:@{NSLocalizedDescriptionKey : @"Can't cancel at this state"}]);
        return;
    }

    void(^acceptOrRejectWrongStateHandler)(NSError*) = ^(NSError *error) {
        if (!error) {
            sendResultsCompletionHandler = completionHandler;
        } else {
            if (completionHandler) {
                completionHandler(error);
            }
        }
    };
    
    if (result) {
        [self.attestationProtocol acceptWithWrongStateHandler:acceptOrRejectWrongStateHandler];
    } else {
        [self.attestationProtocol rejectWithWrongStateHandler:acceptOrRejectWrongStateHandler];
    }
}

- (void)authenticateRequest:(QredoAuthenticationRequest *)authenticationRequest
              authenticator:(NSString *)authenticator
               conversation:(QredoConversation *)conversation
{
    self.authenticationProtocol = [[QredoAuthenticationProtocol alloc] initWithConversation:conversation];
    self.authenticationProtocol.delegate = self;
    [self.authenticationProtocol sendAuthenticationRequest:authenticationRequest];
}

- (void)notifyAuthenticationStatus:(QredoAuthenticationStatus)status
           inAuthenticationRequest:(QredoAuthenticationRequest *)authenticationRequest
{
    for (QredoClaimMessage *claimMessage in authenticationRequest.claimMessages) {
        QredoClaim *claim = [self.claimsHashes objectForKey:claimMessage.claimHash];
        if (!claim) {
            NSLog(@"Didn't find matching claim for hash: %@", claimMessage.claimHash);
            continue;
        }

        [self.delegate qredoClaimantAttestationSession:self claim:claim didChangeStatusTo:status];
    }
    
}

#pragma mark - Claimant Attestation Protocol Delegate

- (void)didStartClaimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
{
    // not used here
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
             didRecivePresentations:(QredoPresentation *)presentation
{
    NSMutableArray *claims = [NSMutableArray array];
    NSMutableDictionary *hashes = [NSMutableDictionary dictionary];

    for (QredoAttestation *attestation in presentation.attestations) {
        QredoLFClaim *claimLF = attestation.claim;

        QredoClaim *claim = [[QredoClaim alloc] init];
        claim.name      = [claimLF.name anyObject];
        claim.dataType  = claimLF.datatype;
        claim.value     = claimLF.value;

        claim.authenticationStatus = QredoAuthenticationStatusWaitingAuthentication;

        [claims addObject:claim];
        [hashes setObject:claim forKey:attestation.credential.hashedClaim];
    }

    // making immutable copies
    self.claims = [claims copy];
    self.claimsHashes = [hashes copy];

    [self.delegate qredoClaimantAttestationSession:self didReceiveClaims:self.claims];
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
           didReciveAuthentications:(QredoAuthenticationResponse *)authentications
{
    for (QredoAuthenticatedClaim *authenticatedClaim in authentications.credentialValidationResults) {
        QredoClaim *claim = [self.claimsHashes objectForKey:authenticatedClaim.claimHash];
        if (!claim) {
            NSLog(@"Didn't find matching claim for hash: %@", authenticatedClaim.claimHash);
            continue;
        }

        [self.delegate qredoClaimantAttestationSession:self claim:claim didChangeStatusTo:QredoAuthenticationStatusReceivedResult];
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
   didFinishAuthenticationWithError:(NSError *)error
{
    [self.delegate qredoClaimantAttestationSessionDidFinishAuthentication:self];
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
  didStartSendingRelyingPartyChoice:(BOOL)claimsAccepted
{
    // not used
}

- (void)claimantAttestationProtocolDidFinishSendingRelyingPartyChoice:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
{
    // call completionHandler from `finishAttestationWithResult`
    if (sendResultsCompletionHandler) {
        sendResultsCompletionHandler(nil);
        sendResultsCompletionHandler = nil;
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
                 didFinishWithError:(NSError *)error
{
    // call completionHandler from cancelWithCompletionHandler and return

    BOOL notifiedCompletionHandler = NO;

    if (cancelCompletionHandler) {
        cancelCompletionHandler(error);
        cancelCompletionHandler = nil;
        notifiedCompletionHandler = YES;
    }

    if (sendResultsCompletionHandler) {
        sendResultsCompletionHandler(error);
        sendResultsCompletionHandler = nil;
        notifiedCompletionHandler = YES;
    }

    if (!notifiedCompletionHandler && error) {
        [self.delegate qredoClaimantAttestationSession:self didFailWithError:error];
    }
}

#pragma mark - Claimant Attestation Protocol Data Source

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
                authenticateRequest:(QredoAuthenticationRequest *)authenticationRequest
                      authenticator:(NSString *)authenticator
                  completionHandler:(QredoClaimantAttestationProtocolAuthenticationCompletionHandler)completionHandler;
{
    [self notifyAuthenticationStatus:QredoAuthenticationStatusAuthenticating
             inAuthenticationRequest:authenticationRequest];

    authenticationCompletionHandler = completionHandler;

    [self.client respondWithTag:kQredoAttestationRendezvousTag
              completionHandler:^(QredoConversation *conversation, NSError *error)
    {
        if (error) {
            completionHandler(nil, error);
            authenticationCompletionHandler = nil;

            [self notifyAuthenticationStatus:QredoAuthenticationStatusFailed
                     inAuthenticationRequest:authenticationRequest];

            return ;
        }

        [self authenticateRequest:authenticationRequest authenticator:authenticator conversation:conversation];
    }];
}

#pragma mark - Authentication Protocol Delegate

- (void)qredoAuthenticationProtocolDidSendClaims:(QredoAuthenticationProtocol *)protocol
{
    // not used
}

- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFinishWithResults:(QredoAuthenticationResponse *)results
{
    if (authenticationCompletionHandler) {
        authenticationCompletionHandler(results, nil);
        authenticationCompletionHandler = nil;
    }
}

- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error
{
    if (authenticationCompletionHandler) {
        authenticationCompletionHandler(nil, error);
        authenticationCompletionHandler = nil;
    }
}

@end


