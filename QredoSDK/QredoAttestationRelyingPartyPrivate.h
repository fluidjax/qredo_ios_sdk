/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"

@interface QredoAttestationRelyingPartyMetadata ()

@property (nonatomic, readwrite) NSString *tag;

@end


@interface QredoAttestationRelyingParty () <QredoRendezvousObserver>

@property (nonatomic) QredoRendezvous *rendezvous;
@property (nonatomic) NSArray *attestationTypes;

- (instancetype)initWithRendezvous:(QredoRendezvous *)rendezvous attestationTypes:(NSArray */* NSString */)attestationTypes;

@end