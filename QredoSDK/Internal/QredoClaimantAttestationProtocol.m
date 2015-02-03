/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoClaimantAttestationProtocol.h"


#pragma mark Interfaces

@interface QredoClaimantAttestationState : QredoConversationProtocolState

@property (nonatomic, readonly) QredoClaimantAttestationProtocol *claimantAttestationProtocol;

#pragma mark Events

- (void)vendorDidAcept;
- (void)vendorDidReject;
- (void)vendorDidCancel;

@end


@interface QredoClaimantAttestationStateReceivedAuthenticationResults : QredoClaimantAttestationState
@property (nonatomic, copy) NSArray *authentications;
@end

@interface QredoClaimantAttestationStateSendVendorChoice : QredoClaimantAttestationState
@property (nonatomic) BOOL claimsAccepted;
@end


@interface QredoClaimantAttestationProtocol()
@property (nonatomic) QredoClaimantAttestationStateReceivedAuthenticationResults *receivedAuthenticationResultsState;
@property (nonatomic) QredoClaimantAttestationStateSendVendorChoice *sendVendorChoiceState;
@end


#pragma mark Implementations

@implementation QredoClaimantAttestationState


- (QredoClaimantAttestationProtocol *)claimantAttestationProtocol
{
    return (QredoClaimantAttestationProtocol *)self.conversationProtocol;
}


#pragma mark Events

- (void)vendorDidAcept {}
- (void)vendorDidReject {}
- (void)vendorDidCancel {}

@end


@implementation QredoClaimantAttestationStateReceivedAuthenticationResults

- (void)didEnterWithBlock:(dispatch_block_t)block
{
    [super didEnterWithBlock:block];
    [self.claimantAttestationProtocol.delegate claimantAttestationProtocol:self.claimantAttestationProtocol
                                                  didReciveAuthentications:self.authentications];
}

- (void)vendorDidAcept
{
    QredoClaimantAttestationStateSendVendorChoice *newState
    = self.claimantAttestationProtocol.sendVendorChoiceState;
    
    [self.conversationProtocol switchToState:newState withBlock:^{
        newState.claimsAccepted = YES;
    }];
}

- (void)vendorDidReject
{
    QredoClaimantAttestationStateSendVendorChoice *newState
    = self.claimantAttestationProtocol.sendVendorChoiceState;
    
    [self.conversationProtocol switchToState:newState withBlock:^{
        newState.claimsAccepted = NO;
    }];
}

@end

@implementation QredoClaimantAttestationStateSendVendorChoice



@end





@implementation QredoClaimantAttestationProtocol

- (instancetype)initWithConversation:(QredoConversation *)conversation
{
    self = [super init];
    if (self) {
        self.receivedAuthenticationResultsState = [QredoClaimantAttestationStateReceivedAuthenticationResults new];
        self.sendVendorChoiceState = [QredoClaimantAttestationStateSendVendorChoice new];
    }
    return self;
}

@end
