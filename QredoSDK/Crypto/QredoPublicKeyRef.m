/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/




#import "QredoPublicKeyRef.h"
#import "QredoCryptoKeychain.h"

@implementation QredoPublicKeyRef


-(NSData*)data{
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    return [keychain retrieveWithRef:self];
}


@end
