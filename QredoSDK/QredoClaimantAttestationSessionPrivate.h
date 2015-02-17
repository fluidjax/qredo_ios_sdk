/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"
#import "QredoClaimantAttestationSession.h"

@interface QredoClaimantAttestationSession ()

@property (nonatomic) QredoConversation *conversation;

- (instancetype)initWithConversation:(QredoConversation *)conversation;

@end