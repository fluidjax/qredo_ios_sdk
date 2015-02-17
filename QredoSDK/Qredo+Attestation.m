/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"

#import "QredoAttestationRelyingPartyPrivate.h"

@implementation QredoClient (Attestation)

- (void)registerAttestationRelyingPartyWithTypes:(NSArray*)attestationTypes /* dob, photo */
                               completionHandler:(void(^)(QredoAttestationRelyingParty *relyingParty, NSError *error))completionHandler
{

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"com.qredo.attestation.demo"
                                                                                              authenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                                                                 durationSeconds:nil
                                                                                                maxResponseCount:nil
                                                                                                        transCap:nil];

    NSString *tag = [[QredoQUID QUID] QUIDString];
    [self createRendezvousWithTag:tag
                    configuration:configuration
                completionHandler:^(QredoRendezvous *rendezvous, NSError *error)
     {

         if (error) {
             completionHandler(nil, error);
             return ;
         }

         QredoAttestationRelyingParty *attestation = [[QredoAttestationRelyingParty alloc] initWithRendezvous:rendezvous];
         completionHandler(attestation, nil);
     }];

}

- (void)enumeratateAttestationRelyingPartiesWithBlock:(void(^)(QredoAttestationRelyingParty *relyingParty, BOOL *stop))block
                                    completionHandler:(void(^)(NSError *error))completionHandler
{
    // TODO: implement in the next version of the attestation demo
}

@end
