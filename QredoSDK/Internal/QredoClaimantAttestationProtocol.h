/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationProtocol.h"
#import <Foundation/Foundation.h>

@class QredoClaimantAttestationProtocol;



@protocol QredoClaimantAttestationProtocolDelegate <NSObject>

// connects with UI (similar to the delegates in the keychain transporter

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
           didReciveAuthentications:(NSArray *)authentications;

@end


@interface QredoClaimantAttestationState : QredoConversationProtocolState

#pragma mark Events

- (void)accept;
- (void)reject;
- (void)cancel;

@end



@interface QredoClaimantAttestationProtocol : QredoConversationProtocol

@property id<QredoClaimantAttestationProtocolDelegate> delegate;

@end


