/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelpers.h"
#import "QredoRendezvousAnonymousHelper.h"
#import "QredoRendezvousEd25519Helper.h"
#import "QredoRendezvousX509PemHelper.h"
#import "QredoLogging.h"

@implementation QredoRendezvousHelpers

+ (id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                 fullTag:(NSString *)fullTag
                                                                  crypto:(id<CryptoImpl>)crypto
                                                                signingHandler:(signDataBlock)signingHandler
                                                                   error:(NSError **)error
{
    switch (authenticationType) {
            
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousHelper alloc] initWithFullTag:fullTag crypto:crypto signingHandler:signingHandler error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeEd25519:
            return [[QredoRendezvousEd25519CreateHelper alloc] initWithFullTag:fullTag crypto:crypto signingHandler:signingHandler error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeX509Pem:
            return [[QredoRendezvousX509PemCreateHelper alloc] initWithFullTag:fullTag crypto:crypto signingHandler:signingHandler error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeX509PemSelfsigned:
        case QredoRendezvousAuthenticationTypeRsa2048Pem:
        case QredoRendezvousAuthenticationTypeRsa4096Pem:
            // TODO: DH - add all other authentication types
            return nil;
            
    }
    
    return nil;
}

+ (id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                  fullTag:(NSString *)fullTag
                                                                   crypto:(id<CryptoImpl>)crypto
                                                                    error:(NSError **)error
{
    switch (authenticationType) {
            
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousHelper alloc] initWithFullTag:fullTag crypto:crypto error:error];
            
        case QredoRendezvousAuthenticationTypeEd25519:
            return [[QredoRendezvousEd25519RespondHelper alloc] initWithFullTag:fullTag crypto:crypto error:error];
            
        case QredoRendezvousAuthenticationTypeX509Pem:
            return [[QredoRendezvousX509PemRespondHelper alloc] initWithFullTag:fullTag crypto:crypto error:error];
            
        case QredoRendezvousAuthenticationTypeX509PemSelfsigned:
        case QredoRendezvousAuthenticationTypeRsa2048Pem:
        case QredoRendezvousAuthenticationTypeRsa4096Pem:
            // TODO: DH - add all other authentication types
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
            
        case QredoRendezvousAuthenticationTypeX509PemSelfsigned:
        case QredoRendezvousAuthenticationTypeRsa2048Pem:
        case QredoRendezvousAuthenticationTypeRsa4096Pem:
            LogError(@"To be completed!");
            NSAssert(0, @"To be completed!");
            return -1;
    }
}

@end
