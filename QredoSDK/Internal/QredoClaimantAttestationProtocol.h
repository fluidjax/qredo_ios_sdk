/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocol.h"
#import "QredoAuthenticatoinClaimsProtocol.h"
#import <Foundation/Foundation.h>

@class QredoClaimantAttestationProtocol;
@class QredoPresentation, QredoAuthenticationResponse;



//==============================================================================================================
#pragma mark - Delegate and data source -
//==============================================================================================================


@protocol QredoClaimantAttestationProtocolDelegate <NSObject>

@optional

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

typedef void(^QredoClaimantAttestationProtocolAuthenticationCompletionHandler)(QredoAuthenticationResponse *response, NSError *error);

@protocol QredoClaimantAttestationProtocolDataSource <NSObject>

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
                authenticateRequest:(QredoAuthenticationRequest *)authenticationRequest
                      authenticator:(NSString *)authenticator
                  completionHandler:(QredoClaimantAttestationProtocolAuthenticationCompletionHandler)completionHandler;

@end



//==============================================================================================================
#pragma mark - Protocol -
//==============================================================================================================


@protocol QredoClaimantAttestationProtocolEvents <NSObject>

- (void)start;

- (void)acceptWithEventCompletionHandler:(void(^)(NSError *error))eventCompletionHandler;
- (void)rejectWithEventCompletionHandler:(void(^)(NSError *error))eventCompletionHandler;
- (void)cancelWithEventCompletionHandler:(void(^)(NSError *error))eventCompletionHandler;

- (void)presentationRequestPublishedWithError:(NSError *)error;

- (void)relyingPartyChoiceSentWithError:(NSError *)error;

- (void)conversationCanceledWithError:(NSError *)error;

@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@protocol QredoClaimantAttestationProtocolInfoMethods <NSObject>

- (BOOL)canCancel;
- (BOOL)canAcceptOrRejct;

@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationState : QredoConversationProtocolCancelableState<QredoClaimantAttestationProtocolEvents, QredoClaimantAttestationProtocolInfoMethods>
@end


//--------------------------------------------------------------------------------------------------------------
#pragma mark -

@interface QredoClaimantAttestationProtocol : QredoConversationProtocol

@property id<QredoClaimantAttestationProtocolDelegate> delegate;
@property id<QredoClaimantAttestationProtocolDataSource> dataSource;

- (instancetype)initWithConversation:(QredoConversation *)conversation
                    attestationTypes:(NSSet *)attestationTypes
                       authenticator:(NSString *)authenticator;


@end


@interface QredoClaimantAttestationProtocol(EventsAndInfo)<QredoClaimantAttestationProtocolEvents, QredoClaimantAttestationProtocolInfoMethods>
@end


