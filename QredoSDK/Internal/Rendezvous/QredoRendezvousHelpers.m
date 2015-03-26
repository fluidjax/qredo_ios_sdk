/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelpers.h"
#import "QredoRendezvousAnonymousHelper.h"
#import "QredoRendezvousEd25519Helper.h"
#import "QredoRendezvousX509PemHelper.h"
#import "QredoRendezvousRsa2048PemHelper.h"
#import "QredoRendezvousRsa4096PemHelper.h"
#import "QredoRendezvousRsaPemCommonHelper.h"
#import "QredoLogging.h"

@implementation QredoRendezvousHelpers

+ (id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                 fullTag:(NSString *)fullTag
                                                                  crypto:(id<CryptoImpl>)crypto
                                                         trustedRootRefs:(NSArray *)trustedRootRefs
                                                                signingHandler:(signDataBlock)signingHandler
                                                                   error:(NSError **)error
{
    switch (authenticationType) {
            
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousCreateHelper alloc] initWithFullTag:fullTag
                                                                          crypto:crypto
                                                                 trustedRootRefs:trustedRootRefs
                                                                  signingHandler:signingHandler
                                                                           error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeEd25519:
            return [[QredoRendezvousEd25519CreateHelper alloc] initWithFullTag:fullTag
                                                                        crypto:crypto
                                                               trustedRootRefs:trustedRootRefs
                                                                signingHandler:signingHandler
                                                                         error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeX509Pem:
            return [[QredoRendezvousX509PemCreateHelper alloc] initWithFullTag:fullTag
                                                                        crypto:crypto
                                                               trustedRootRefs:trustedRootRefs
                                                                signingHandler:signingHandler
                                                                         error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeRsa2048Pem:
            return [[QredoRendezvousRsa2048PemCreateHelper alloc] initWithFullTag:fullTag
                                                                           crypto:crypto
                                                                  trustedRootRefs:trustedRootRefs
                                                                   signingHandler:signingHandler
                                                                            error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeRsa4096Pem:
            return [[QredoRendezvousRsa4096PemCreateHelper alloc] initWithFullTag:fullTag
                                                                           crypto:crypto
                                                                  trustedRootRefs:trustedRootRefs
                                                                   signingHandler:signingHandler
                                                                            error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeX509PemSelfsigned:
            // TODO: DH - add X.509 Self-signed support
            LogError(@"Add X.509 Self-signed support!");
            NSAssert(0, @"Add X.509 Self-signed support");
            return nil;
            
    }
    
    return nil;
}

+ (id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                  fullTag:(NSString *)fullTag
                                                                   crypto:(id<CryptoImpl>)crypto
                                                          trustedRootRefs:(NSArray *)trustedRootRefs
                                                                    error:(NSError **)error
{
    switch (authenticationType) {
            
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousRespondHelper alloc] initWithFullTag:fullTag
                                                                           crypto:crypto
                                                                  trustedRootRefs:trustedRootRefs
                                                                            error:error];
            
        case QredoRendezvousAuthenticationTypeEd25519:
            return [[QredoRendezvousEd25519RespondHelper alloc] initWithFullTag:fullTag
                                                                         crypto:crypto
                                                                trustedRootRefs:trustedRootRefs
                                                                          error:error];
            
        case QredoRendezvousAuthenticationTypeX509Pem:
            return [[QredoRendezvousX509PemRespondHelper alloc] initWithFullTag:fullTag
                                                                         crypto:crypto
                                                                trustedRootRefs:trustedRootRefs
                                                                          error:error];
            
        case QredoRendezvousAuthenticationTypeRsa2048Pem:
            return [[QredoRendezvousRsa2048PemRespondHelper alloc] initWithFullTag:fullTag
                                                                            crypto:crypto
                                                                   trustedRootRefs:trustedRootRefs
                                                                             error:error];
            
        case QredoRendezvousAuthenticationTypeRsa4096Pem:
            return [[QredoRendezvousRsa4096PemRespondHelper alloc] initWithFullTag:fullTag
                                                                            crypto:crypto
                                                                   trustedRootRefs:trustedRootRefs
                                                                             error:error];

        case QredoRendezvousAuthenticationTypeX509PemSelfsigned:
            // TODO: DH - add X.509 Self-signed support
            LogError(@"Add X.509 Self-signed support!");
            NSAssert(0, @"Add X.509 Self-signed support");
            return nil;
            
    }
    
    return nil;
}

+ (NSInteger)saltLengthForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
{
    switch (authenticationType) {
            
        case QredoRendezvousAuthenticationTypeAnonymous:
        case QredoRendezvousAuthenticationTypeEd25519:
            return -1; // Salt not used

        case QredoRendezvousAuthenticationTypeX509Pem:
            return kX509AuthenticatedRendezvousSaltLength;
            
        case QredoRendezvousAuthenticationTypeRsa2048Pem:
        case QredoRendezvousAuthenticationTypeRsa4096Pem:
            return kRsaAuthenticatedRendezvousSaltLength;
        
        case QredoRendezvousAuthenticationTypeX509PemSelfsigned:
            // TODO: DH - add X.509 Self-signed support
            LogError(@"Add X.509 Self-signed support!");
            NSAssert(0, @"Add X.509 Self-signed support");
            return -1;
    }
}

@end
