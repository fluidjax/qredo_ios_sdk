/* HEADER GOES HERE */
#import "QredoKeychain.h"
#import "QredoCryptoImplV1.h"
#import "QredoRawCrypto.h"
#import "QredoErrorCodes.h"
#import "NSData+QredoRandomData.h"
#import "QredoVaultCrypto.h"
#import "QredoUserCredentials.h"

@interface QredoKeychain (){
    BOOL _isInitialized;
    NSData *_masterKey;
    QredoCryptoImplV1 *_crypto;
}

@end

@implementation QredoKeychain

-(void)initialize {
    _crypto = [QredoCryptoImplV1 new];
}


-(instancetype)initWithOperatorInfo:(QLFOperatorInfo *)operatorInfo {
    self = [super init];
    if (self){
        [self initialize];
        _isInitialized = NO;
        _operatorInfo = operatorInfo;
    }
    return self;
}


-(instancetype)initWithData:(NSData *)serializedData {
    self = [super init];
    if (self){
        [self initialize];
        _isInitialized = YES;
        _masterKey = [serializedData copy];
        [self deriveKeys];
    }
    return self;
}


-(NSData *)data {
    if (!_isInitialized)return nil;
    return _masterKey;
}


-(void)generateNewKeys:(QredoUserCredentials *)userCredentials {
    _isInitialized = YES;
    _masterKey = [userCredentials masterKey];
    [self deriveKeys];
}


-(void)deriveKeys {
    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:_masterKey];
    self.systemVaultKeys = [[QredoVaultKeys alloc] initWithVaultKey:[QredoVaultCrypto systemVaultKeyWithVaultMasterKey:vaultMasterKey]];
    self.defaultVaultKeys = [[QredoVaultKeys alloc] initWithVaultKey:[QredoVaultCrypto userVaultKeyWithVaultMasterKey:vaultMasterKey]];
}


@end
