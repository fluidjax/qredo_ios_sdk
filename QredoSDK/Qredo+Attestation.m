/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"

#import "QredoAttestationRelyingPartyPrivate.h"

static NSString *KAttestationClaimantConversationType = @"com.qredo.attestation.demo.relyingparty";



@implementation QredoClient (Attestation)

- (void)registerAttestationRelyingPartyWithTypes:(NSArray*)attestationTypes /* dob, photo */
                               completionHandler:(void(^)(QredoAttestationRelyingParty *relyingParty, NSError *error))completionHandler
{

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:KAttestationClaimantConversationType
                                                                                                 durationSeconds:nil
                                                                                        isUnlimitedResponseCount:YES];

    NSString *tag = [[QredoQUID QUID] QUIDString];
//    NSString *tag = [NSString stringWithFormat:@"att-%ld", random() % 20000]; // TODO: short tags for manual testing only
    [self createAnonymousRendezvousWithTag:tag
                             configuration:configuration
                         completionHandler:^(QredoRendezvous *rendezvous, NSError *error)
    {
        if (error) {
            completionHandler(nil, error);
            return ;
        }
        
        // TODO: add attestation types to QredoAttestationRelyingParty
        
        QredoAttestationRelyingParty *attestation = [[QredoAttestationRelyingParty alloc] initWithRendezvous:rendezvous attestationTypes:attestationTypes];
        completionHandler(attestation, nil);
    }];
    
    
}

- (void)enumeratateAttestationRelyingPartiesWithBlock:(void(^)(QredoAttestationRelyingParty *relyingParty, BOOL *stop))block
                                    completionHandler:(void(^)(NSError *error))completionHandler
{
    // TODO: implement in the next version of the attestation demo
}

@end
