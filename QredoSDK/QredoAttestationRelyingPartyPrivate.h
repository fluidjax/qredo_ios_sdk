/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"

@interface QredoAttestationRelyingPartyMetadata ()

@property (nonatomic, readwrite) NSString *tag;

@end


@interface QredoAttestationRelyingParty () <QredoRendezvousDelegate>

@property (nonatomic) QredoRendezvous *rendezvous;

- (instancetype)initWithRendezvous:(QredoRendezvous *)rendezvous;

@end