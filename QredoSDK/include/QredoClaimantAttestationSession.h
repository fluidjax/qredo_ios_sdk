/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoAttestationRelyingParty.h"


@class QredoClaimantAttestationSession;

@interface QredoAuthenticationResult : NSObject

@property BOOL verified;
@property NSError *error;

@end



typedef NS_ENUM(NSUInteger, QredoAuthenticationStatus) {
    QredoAuthenticationStatusWaitingAuthentication,
    QredoAuthenticationStatusAuthenticating,
    QredoAuthenticationStatusReceivedResult,
    QredoAuthenticationStatusFailed
};



@interface QredoClaim : NSObject

@property NSString *name;
@property NSString *dataType;
@property NSData   *value;

@property QredoAuthenticationStatus authenticationStatus;
@property QredoAuthenticationResult *authenticationResult;

@end



@protocol QredoClaimantAttestationSessionDelegate <NSObject>

@required
- (void)qredoClaimantAttestationSession:(QredoClaimantAttestationSession*)claimantSession didReceiveClaims:(NSArray /* QredoClaim */ *)claims;
- (void)qredoClaimantAttestationSessionDidFinishAuthentication:(QredoClaimantAttestationSession *)claimantSession;
- (void)qredoClaimantAttestationSession:(QredoClaimantAttestationSession*)claimantSession didFailWithError:(NSError *)error;

@optional
- (void)qredoClaimantAttestationSession:(QredoClaimantAttestationSession*)claimantSession claim:(QredoClaim *)claim didChangeStatusTo:(QredoAuthenticationStatus)status;

@end



@interface QredoClaimantAttestationSession : NSObject

// if claims are received before the delegate is set, then didReceiveClaims: will be called straight after receiving claims
@property id<QredoClaimantAttestationSessionDelegate> delegate;

- (void)startAuthentication;

- (void)cancelWithCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)finishAttestationWithResult:(BOOL)result completionHandler:(void(^)(NSError *error))completionHandler;

@end


