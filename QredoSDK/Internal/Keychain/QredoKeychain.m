/* HEADER GOES HERE */
#import "QredoKeychain.h"
#import "QredoCryptoImplV1.h"
#import "QredoRawCrypto.h"
#import "QredoErrorCodes.h"
#import "NSData+QredoRandomData.h"
#import "QredoVaultCrypto.h"
#import "QredoUserCredentials.h"
#import "QredoKeyRef.h"

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

    QredoKeyRef *masterKeyRef = [[QredoKeyRef alloc] initWithKeyData:_masterKey];
    QredoKeyRef *vaultMasterKeyRef = [QredoVaultCrypto vaultMasterKeyWithUserMasterKeyRef:masterKeyRef];
    self.systemVaultKeys = [[QredoVaultKeys alloc] initWithVaultKeyRef:[QredoVaultCrypto systemVaultKeyWithVaultMasterKeyRef:vaultMasterKeyRef]];
    self.defaultVaultKeys = [[QredoVaultKeys alloc] initWithVaultKeyRef:[QredoVaultCrypto userVaultKeyWithVaultMasterKeyRef:vaultMasterKeyRef]];
}


@end
