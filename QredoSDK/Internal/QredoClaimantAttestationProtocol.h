/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocol.h"
#import "QredoAuthenticationClaimsProtocol.h"
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

/**
 Event sent by the user when the claims are accepted.
 @param eventCompletionHandler  This handler is called after the event is received by the state machine. 
                                If the current state of the machine is able to accept this event, the hander will
                                be called with error nil. Otherwise the error will contain a value. Please note
                                that an error equal to nil does not mean that the event has been processed 
                                successfully. The success of failure of the processing of the event is relayed back
                                through the protocol delegate.
 */
- (void)acceptWithEventCompletionHandler:(void(^)(NSError *error))eventCompletionHandler;

/**
 Event sent by the user when the claims are rejected.
 @param eventCompletionHandler  This handler is called after the event is received by the state machine.
                                If the current state of the machine is able to accept this event, the hander will
                                be called with error nil. Otherwise the error will contain a value. Please note
                                that an error equal to nil does not mean that the event has been processed
                                successfully. The success of failure of the processing of the event is relayed back
                                through the protocol delegate.
 */
- (void)rejectWithEventCompletionHandler:(void(^)(NSError *error))eventCompletionHandler;

/**
 Event sent by the user when the attestation process is canceled.
 @param eventCompletionHandler  This handler is called after the event is received by the state machine.
                                If the current state of the machine is able to accept this event, the hander will
                                be called with error nil. Otherwise the error will contain a value. Please note
                                that an error equal to nil does not mean that the event has been processed
                                successfully. The success of failure of the processing of the event is relayed back
                                through the protocol delegate.
 */
- (void)cancelWithEventCompletionHandler:(void(^)(NSError *error))eventCompletionHandler;


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


