/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelpers.h"
#import "QredoRendezvousAnonymousHelper.h"
#import "QredoRendezvousEd25519Helper.h"

@implementation QredoRendezvousHelpers

+ (id<QredoRendezvousHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType tag:(NSString *)tag crypto:(id<CryptoImpl>)crypto
{
    switch (authenticationType) {
            
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousHelper alloc] initWithTag:tag crypto:crypto];
            
        case QredoRendezvousAuthenticationTypeX509Pem:
            return [[QredoRendezvousEd25519Helper alloc] initWithTag:tag crypto:crypto];
            
        case QredoRendezvousAuthenticationTypeX509PemSelfsigned:
        case QredoRendezvousAuthenticationTypeEd25519:
        case QredoRendezvousAuthenticationTypeRsa2048Pem:
        case QredoRendezvousAuthenticationTypeRsa4096Pem:
            return nil;
            
    }
    
    return nil;
}

@end
