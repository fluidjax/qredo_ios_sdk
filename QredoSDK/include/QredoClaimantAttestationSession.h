/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoAttestationRelyingParty.h"

@interface QredoAuthenticationResult : NSObject

@property BOOL verified;
@property NSError *error;

@end

typedef NS_ENUM(NSUInteger, QredoAuthenticationStatus) {
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

@class QredoClaimantAttestationSession;

@protocol QredoClaimantAttestationSessionDelegate <NSObject>

@required
- (void)QredoClaimantAttestationSession:(QredoClaimantAttestationSession*)claimantSession didReceiveClaims:(NSArray /* QredoClaim */ *)claims;
- (void)QredoClaimantAttestationSessionDidFinishAuthentication:(QredoClaimantAttestationSession *)claimantSession;

@optional
- (void)QredoClaimantAttestationSession:(QredoClaimantAttestationSession*)claimantSession claim:(QredoClaim *)claim didChangeStatusTo:(QredoAuthenticationStatus)status;

@end

@interface QredoClaimantAttestationSession : NSObject

// if claims are received before the delegate is set, then didReceiveClaims: will be called straight after receiving claims
@property id<QredoClaimantAttestationSessionDelegate> delegate;

- (void)startAuthentication;

- (void)cancelWithCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)finishAttestationWithResult:(BOOL)result completionHandler:(void(^)(NSError *error))completionHandler;

@end
