/* HEADER GOES HERE */
#import "QredoSigner.h"
#import "CryptoImplV1.h"
#import "QredoRawCrypto.h"
#import "QredoErrorCodes.h"


@implementation QredoED25519Singer
{
    QredoED25519SigningKey *_signingKey;
}

-(instancetype)initWithSigningKey:(QredoED25519SigningKey *)signingKey {
    NSAssert(signingKey,@"The signing key must be provided.");
    self = [super init];
    if (self){
        _signingKey = signingKey;
    }
    
    return self;
}


-(NSData *)signData:(NSData *)data error:(NSError **)error {
    return [[CryptoImplV1 sharedInstance] qredoED25519SignMessage:data withKey:_signingKey error:error];
}


@end

