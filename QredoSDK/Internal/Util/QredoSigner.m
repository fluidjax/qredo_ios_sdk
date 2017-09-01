/* HEADER GOES HERE */
#import "QredoSigner.h"
#import "QredoCryptoImplV1.h"
#import "QredoCryptoRaw.h"
#import "QredoErrorCodes.h"


@implementation QredoED25519Signer{
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
    return [[QredoCryptoImplV1 sharedInstance] qredoED25519SignMessage:data withKey:_signingKey error:error];
}


@end

