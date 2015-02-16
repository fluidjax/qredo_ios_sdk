/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocol.h"
#import "QredoAuthenticatoinClaimsProtocol.h"
#import <Foundation/Foundation.h>

@class QredoClaimantAttestationProtocol;
@class QredoPresentation, QredoAuthenticationResponse;



//=======================================
#pragma mark - Delegate and data source -
//=======================================


@protocol QredoClaimantAttestationProtocolDelegate <NSObject>

- (void)didStartClaimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol;

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
             didRecivePresentations:(QredoPresentation *)presentation;

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
           didReciveAuthentications:(QredoAuthenticationResponse *)authentications;

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
           didFinishAuthenticationWithError:(NSError *)error;

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
  didStartSendingRelyingPartyChoice:(BOOL)claimsAccepted;

- (void)claimantAttestationProtocolDidFinishSendingRelyingPartyChoice:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol;

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
                 didFinishWithError:(NSError *)error;

@end

@protocol QredoClaimantAttestationProtocolDataSource <NSObject>

- (QredoAuthenticationProtocol *)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
                             authenticationProtocolWithError:(NSError **)error;

@end



//=======================
#pragma mark - Protocol -
//=======================


@protocol QredoClaimantAttestationProtocolEvents <NSObject>

- (void)accept;
- (void)reject;
- (void)cancel;

- (void)presentationRequestPublishedWithError:(NSError *)error;

- (void)authenticationResultsRecievedWithError:(NSError *)error;

- (void)relyingPartyChioiceSentWithError:(NSError *)error;

- (void)conversationCanceledWithError:(NSError *)error;

@end


//------------
#pragma mark -

@interface QredoClaimantAttestationState : QredoConversationProtocolCancelableState<QredoClaimantAttestationProtocolEvents>
@end


//------------
#pragma mark -

@interface QredoClaimantAttestationProtocol : QredoConversationProtocol

@property id<QredoClaimantAttestationProtocolDelegate> delegate;
@property id<QredoClaimantAttestationProtocolDataSource> dataSource;

- (instancetype)initWithConversation:(QredoConversation *)conversation
                    attestationTypes:(NSSet *)attestationTypes
                       authenticator:(NSString *)authenticator;

@end


@interface QredoClaimantAttestationProtocol(Events)<QredoClaimantAttestationProtocolEvents>
@end


