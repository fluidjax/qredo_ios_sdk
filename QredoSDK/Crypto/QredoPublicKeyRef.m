//
//  QredoPublicKeyRef.m
//  QredoSDK
//
//  Created by Christopher Morris on 24/08/2017.
//
//

#import "QredoPublicKeyRef.h"
#import "QredoCryptoKeychain.h"

@implementation QredoPublicKeyRef


-(NSData*)data{
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    return [keychain retrieveWithRef:self];
}


@end
