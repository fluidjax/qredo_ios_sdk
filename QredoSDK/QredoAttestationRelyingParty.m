/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoAttestationRelyingParty.h"
#import "QredoAttestationRelyingPartyPrivate.h"
#import "QredoClaimantAttestationSessionPrivate.h"


@implementation QredoAttestationRelyingPartyMetadata

@end


@implementation QredoAttestationRelyingParty

- (instancetype)initWithRendezvous:(QredoRendezvous *)rendezvous
{
    self = [super init];
    if (!self) return nil;

    self.rendezvous = rendezvous;
    self.rendezvous.delegate = self;

    self.metadata = [[QredoAttestationRelyingPartyMetadata alloc] init];
    self.metadata.tag = self.rendezvous.tag;

    return self;
}

- (void)startListening
{
    [self.rendezvous startListening];
}

- (void)stopListening
{
    [self.rendezvous stopListening];
}


- (void)enumerateClaimantSessionsWithBlock:(void(^)(QredoClaimantAttestationSession *))block
                         completionHandler:(void(^)(NSError *error))completionHandler
{
    // TODO [GR]: Implement this

    completionHandler([NSError errorWithDomain:QredoErrorDomain
                                          code:QredoErrorCodeUnknown
                                      userInfo:@{NSLocalizedDescriptionKey: @"Not implemented"}]);
}


- (void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    NSLog(@"received response on rendezvous");
    QredoClaimantAttestationSession *attestationSession = [[QredoClaimantAttestationSession alloc] initWithConversation:conversation
                                                                                                       attestationTypes:nil
                                                                                                          authenticator:nil];
    [self.delegate qredoAttestationRelyingParty:self didStartClaimantSession:attestationSession];
}

@end
