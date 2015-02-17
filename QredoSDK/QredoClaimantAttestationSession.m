/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoClaimantAttestationSession.h"
#import "QredoClaimantAttestationSessionPrivate.h"


@implementation QredoAuthenticationResult
@end

@implementation QredoClaim : NSObject
@end


@implementation QredoClaimantAttestationSession

- (instancetype)initWithConversation:(QredoConversation *)conversation
                    attestationTypes:(NSSet *)attestationTypes
                       authenticator:(NSString *)authenticator
{
    self = [super init];
    if (!self) return nil;

    self.attestationProtocol = [[QredoClaimantAttestationProtocol alloc] initWithConversation:conversation
                                                                             attestationTypes:attestationTypes
                                                                                authenticator:authenticator];

    return self;
}

- (void)startAuthentication
{
    [self.attestationProtocol start];
}

- (void)cancelWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self.attestationProtocol cancel];

    // 1. check if we are on the right state (not at Start, Finish or Relying Party Choice Sent) -> protocol.canCancelNow
    // 2. if not, then call completionHandler(error=wrong state)
    // 3. if ok, store the completionHandler
    // 4. call the completionHandler from didFinishWithError
}

- (void)finishAttestationWithResult:(BOOL)result completionHandler:(void(^)(NSError *error))completionHandler
{
    // 1. check if we are on the right state -> protocol.canSetResult
    // 2. if not, then call completionHandler(error=wrong state)
    // 3. if ok, store the completionHandler
    // 4. call the completionHandler from claimantAttestationProtocolDidFinishSendingRelyingPartyChoice
    if (result) {
        [self.attestationProtocol accept];
    } else {
        [self.attestationProtocol reject];
    }
}

#pragma mark - Delegate

- (void)didStartClaimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
{
    // not used here
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
             didRecivePresentations:(QredoPresentation *)presentation
{
    NSArray *claims = nil; // TODO:
    [self.delegate qredoClaimantAttestationSession:self
                                  didReceiveClaims:claims];
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
           didReciveAuthentications:(QredoAuthenticationResponse *)authentications
{
    // delegate.didChangeStateTo
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
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
                 didFinishWithError:(NSError *)error
{
    // call completionHandler from cancelWithCompletionHandler and return
}

#pragma mark - Data Source

- (QredoAuthenticationProtocol *)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
                             authenticationProtocolWithError:(NSError **)error
{
    return nil;
}


@end


