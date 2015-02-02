/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoClaimantAttestationSession.h"

@class QredoAttestationRelyingParty;
@protocol QredoAttestationRelyingPartyDelegate <NSObject>

@required
- (void)qredoAttestationRelyingParty:(QredoAttestationRelyingParty*)attestationRelyingParty didStartClaimantSession:(QredoClaimantAttestationSession*)claimantAttestationSession;

@optional
- (void)qredoAttestationRelyingParty:(QredoAttestationRelyingParty*)attestationRelyingParty didFinishClaimantSession:(QredoClaimantAttestationSession*)claimantAttestationSession;

@end

@interface QredoAttestationRelyingPartyMetadata : NSObject

@end

@interface QredoAttestationRelyingParty : NSObject

@property QredoAttestationRelyingPartyMetadata *metadata;

@property id<QredoAttestationRelyingPartyDelegate> delegate;

// return only new
- (void)startListening;
- (void)stopListening;

// return only active
- (void)enumerateClaimantSessionsWithBlock:(void(^)(QredoClaimantAttestationSession *))block completionHandler:(void(^)(NSError *error))completionHandler;

@end
