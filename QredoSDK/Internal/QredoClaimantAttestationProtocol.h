/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocol.h"
#import <Foundation/Foundation.h>

@class QredoClaimantAttestationProtocol;
@class QredoPresentation, QredoAuthenticationResponse;


@protocol QredoClaimantAttestationProtocolDelegate <NSObject>

- (void)didStartClaimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol;

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
             didRecivePresentations:(QredoPresentation *)presentation;

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
           didReciveAuthentications:(QredoAuthenticationResponse *)authentications;

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
  didStartSendingRelyingPartyChoice:(BOOL)claimsAccepted;

- (void)claimantAttestationProtocolDidFinishSendingRelyingPartyChoice:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol;

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
                 didFinishWithError:(NSError *)error;

@end



@protocol QredoClaimantAttestationProtocolEvents <NSObject>

- (void)accept;
- (void)reject;
- (void)cancel;

- (void)presentationRequestPublishedWithError:(NSError *)error;

- (void)sendAtestationChioiceCompletedWithError:(NSError *)error;

- (void)conversationCanceledWithError:(NSError *)error;

@end



@interface QredoClaimantAttestationState : QredoConversationProtocolCancelableState<QredoClaimantAttestationProtocolEvents>
@end



@interface QredoClaimantAttestationProtocol : QredoConversationProtocol<QredoClaimantAttestationProtocolEvents>

@property id<QredoClaimantAttestationProtocolDelegate> delegate;

- (instancetype)initWithConversation:(QredoConversation *)conversation
                    attestationTypes:(NSSet *)attestationTypes
                       authenticator:(NSString *)authenticator;

@end


