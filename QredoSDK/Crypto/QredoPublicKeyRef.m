/* HEADER GOES HERE */


#import "QredoPublicKeyRef.h"
#import "QredoCryptoKeychain.h"

@implementation QredoPublicKeyRef


-(NSData*)data{
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    return [keychain retrieveWithRef:self];
}


@end
