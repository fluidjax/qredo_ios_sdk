/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelpers.h"
#import "QredoRendezvousAnonymousHelper.h"
#import "QredoRendezvousEd25519Helper.h"

@implementation QredoRendezvousHelpers

+ (id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                  prefix:(NSString *)prefix
                                                                  crypto:(id<CryptoImpl>)crypto
                                                                   error:(NSError **)error
{
    switch (authenticationType) {
            
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousHelper alloc] initWithPrefix:prefix crypto:crypto error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeEd25519:
            return [[QredoRendezvousEd25519CreateHelper alloc] initWithPrefix:prefix crypto:crypto error:(NSError **)error];
            
        case QredoRendezvousAuthenticationTypeX509Pem:
        case QredoRendezvousAuthenticationTypeX509PemSelfsigned:
        case QredoRendezvousAuthenticationTypeRsa2048Pem:
        case QredoRendezvousAuthenticationTypeRsa4096Pem:
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
        case QredoRendezvousAuthenticationTypeX509PemSelfsigned:
        case QredoRendezvousAuthenticationTypeRsa2048Pem:
        case QredoRendezvousAuthenticationTypeRsa4096Pem:
            return nil;
            
    }
    
    return nil;
}

@end
