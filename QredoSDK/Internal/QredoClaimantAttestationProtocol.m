/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoClaimantAttestationProtocol.h"



#pragma mark Interfaces

@interface QredoClaimantAttestationState()
@property (nonatomic, readonly) QredoClaimantAttestationProtocol *claimantAttestationProtocol;
@end


@interface QredoClaimantAttestationState_RequestingPresentaion : QredoClaimantAttestationState
@end

@interface QredoClaimantAttestationState_WaitingPresentaions : QredoClaimantAttestationState
@end

@interface QredoClaimantAttestationState_RecievedPresentaions : QredoClaimantAttestationState
@end

@interface QredoClaimantAttestationState_ReceivedAuthenticationResults : QredoClaimantAttestationState
@property (nonatomic, copy) NSArray *authentications;
@end

@interface QredoClaimantAttestationState_SendRelyingPartyChoice : QredoClaimantAttestationState
@property (nonatomic) BOOL claimsAccepted;
@end


@interface QredoClaimantAttestationProtocol()
@property (nonatomic) QredoClaimantAttestationState_ReceivedAuthenticationResults *receivedAuthenticationResultsState;
@property (nonatomic) QredoClaimantAttestationState_SendRelyingPartyChoice *sendVendorChoiceState;
@end

@interface QredoClaimantAttestationState_CancelConversation : QredoClaimantAttestationState
@end

@interface QredoClaimantAttestationState_Finish : QredoClaimantAttestationState
@end


#pragma mark Implementations

@implementation QredoClaimantAttestationState


- (QredoClaimantAttestationProtocol *)claimantAttestationProtocol
{
    return (QredoClaimantAttestationProtocol *)self.conversationProtocol;
}


#pragma mark Events

- (void)accept {}
- (void)reject {}
- (void)cancel {}

@end


@implementation QredoClaimantAttestationState_RequestingPresentaion
@end

@implementation QredoClaimantAttestationState_WaitingPresentaions
@end

@implementation QredoClaimantAttestationState_RecievedPresentaions
@end

@implementation QredoClaimantAttestationState_ReceivedAuthenticationResults

- (void)didEnterWithBlock:(dispatch_block_t)block
{
    [super didEnter];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                  didReciveAuthentications:self.authentications];
}

- (void)accept
{
    QredoClaimantAttestationState_SendRelyingPartyChoice *newState
    = self.claimantAttestationProtocol.sendVendorChoiceState;
    newState.claimsAccepted = YES;
    [self.conversationProtocol switchToState:newState];
}

- (void)reject
{
    QredoClaimantAttestationState_SendRelyingPartyChoice *newState
    = self.claimantAttestationProtocol.sendVendorChoiceState;
    newState.claimsAccepted = NO;
    [self.conversationProtocol switchToState:newState];
}

@end

@implementation QredoClaimantAttestationState_SendRelyingPartyChoice
@end

@implementation QredoClaimantAttestationState_CancelConversation
@end

@implementation QredoClaimantAttestationState_Finish
@end


@implementation QredoClaimantAttestationProtocol

- (instancetype)initWithConversation:(QredoConversation *)conversation
{
    self = [super init];
    if (self) {
        self.receivedAuthenticationResultsState = [QredoClaimantAttestationState_ReceivedAuthenticationResults new];
        self.sendVendorChoiceState = [QredoClaimantAttestationState_SendRelyingPartyChoice new];
    }
    return self;
}

@end


