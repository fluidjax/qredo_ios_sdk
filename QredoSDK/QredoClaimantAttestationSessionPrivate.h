/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"
#import "QredoClaimantAttestationSession.h"
#import "QredoClaimantAttestationProtocol.h"

@interface QredoClaimantAttestationSession () <QredoClaimantAttestationProtocolDelegate, QredoClaimantAttestationProtocolDataSource>

@property (nonatomic) QredoClaimantAttestationProtocol *attestationProtocol;

- (instancetype)initWithConversation:(QredoConversation *)conversation
                    attestationTypes:(NSSet *)attestationTypes
                       authenticator:(NSString *)authenticator;


@end