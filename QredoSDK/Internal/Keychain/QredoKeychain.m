/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoKeychain.h"
#import "QredoCryptoImplV1.h"
#import "QredoCryptoRaw.h"
#import "QredoErrorCodes.h"
#import "NSData+QredoRandomData.h"
#import "QredoVaultCrypto.h"
#import "QredoUserCredentials.h"
#import "QredoKeyRef.h"
#import "QredoCryptoKeychain.h"

@interface QredoKeychain (){
    BOOL _isInitialized;
    QredoKeyRef *_masterKeyRef;
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
//        _masterKey = [serializedData copy];
        _masterKeyRef = [QredoKeyRef keyRefWithKeyData:[serializedData copy]];
        [self deriveKeys];
    }
    return self;
}


-(NSData *)masterKeyData{
    if (!_isInitialized)return nil;
    NSData *_masterKey = [[QredoCryptoKeychain standardQredoCryptoKeychain] retrieveWithRef:_masterKeyRef];
    return _masterKey;
}


-(void)generateNewKeys:(QredoUserCredentials *)userCredentials {
    _isInitialized = YES;
    _masterKeyRef = [userCredentials generateMasterKeyRef];
    [self deriveKeys];
}


-(void)deriveKeys {
    //QredoKeyRef *masterKeyRef = [QredoKeyRef keyRefWithKeyData:_masterKey];
    QredoKeyRef *vaultMasterKeyRef = [QredoVaultCrypto vaultMasterKeyRefWithUserMasterKeyRef:_masterKeyRef];
    self.systemVaultKeys = [[QredoVaultKeys alloc] initWithVaultKeyRef:[QredoVaultCrypto systemVaultKeyRefWithVaultMasterKeyRef:vaultMasterKeyRef]];
    self.defaultVaultKeys = [[QredoVaultKeys alloc] initWithVaultKeyRef:[QredoVaultCrypto userVaultKeyRefWithVaultMasterKeyRef:vaultMasterKeyRef]];
}


@end
