/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychain.h"
#import "QredoClientMarshallers.h"
#import "CryptoImplV1.h"
#import "QredoCrypto.h"
#import "QredoErrorCodes.h"
#import <CommonCrypto/CommonCrypto.h>
#import "NSData+QredoRandomData.h"

#define SALT_RECOVERY_INFO [@"Zestybus" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_KEYSTORE_KEYS [@"Ferirama" dataUsingEncoding:NSUTF8StringEncoding]

#define SALT_DERIVE_CREDENTIAL_AUTHENTICATION [@"Bioyino" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_CREDENTIAL_ENCRYPTION [@"Waratel" dataUsingEncoding:NSUTF8StringEncoding]

#define SALT_KEYCHAIN_ENCRYPTION [@"Ukewaiqv" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_KEYCHAIN_AUTHENTICATION [@"Owyurdefip" dataUsingEncoding:NSUTF8StringEncoding]

#define SALT_DERIVE_VAULT_KEYS [@"Goulbap" dataUsingEncoding:NSUTF8StringEncoding]

#define SALT_DERIVE_VAULT_ENCRYPTION_0 [@"Replitz" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_1 [@"Dizoolexa" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_2 [@"Aloidia" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_3 [@"Loheckle" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_4 [@"Uliratha" dataUsingEncoding:NSUTF8StringEncoding]

#define SALT_DERIVE_VAULT_AUTHENTICATION_0 [@"Loopnova" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_1 [@"Mogotrevo" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_2 [@"Ethosien" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_3 [@"Hioffpo" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_4 [@"Yokovich" dataUsingEncoding:NSUTF8StringEncoding]

static uint8_t zeroBytes32[32] = {0};

@interface QredoKeychain ()
{
    BOOL _isInitialized;
    QredoQUID *_vaultId;

    NSData *_authKey;
    NSData *_bulkKey;

    NSData *_encryptedRecoveryInfo;

    CryptoImplV1 *_crypto;
}

@end

@implementation QredoKeychain

- (void)initialize {
    _crypto = [CryptoImplV1 new];
}

- (instancetype)initWithOperatorInfo:(QredoOperatorInfo *)operatorInfo {
    self = [super init];
    if (self) {
        [self initialize];
        _isInitialized = NO;
        _operatorInfo = operatorInfo;
    }
    return self;
}

- (instancetype)initWithOperatorInfo:(QredoOperatorInfo *)operatorInfo vaultId:(QredoQUID*)vaultId authenticationKey:(NSData*)authenticationKey bulkKey:(NSData*)bulkKey
{
    self = [super init];
    if (self) {
        [self initialize];
        _isInitialized = YES;
        _operatorInfo = operatorInfo;
        _vaultId = vaultId;
        _bulkKey = bulkKey;
        _authKey = authenticationKey;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)serializedData
{
    self = [super init];

    [self initialize];

    _isInitialized = YES;

    QredoLFKeychain *keychain = [QredoPrimitiveMarshallers unmarshalObject:serializedData unmarshaller:[QredoClientMarshallers keychainUnmarshaller]];

    _operatorInfo = keychain.operatorInfo;

    _vaultId = keychain.vaultInfo.vaultID;

    QredoVaultKeyStore *keystore = (QredoVaultKeyStore*)[keychain.vaultInfo.keyStore anyObject];
    NSData *encryptedVaultKeys = keystore.encryptedVaultKeys;

    NSLog(@"%@", encryptedVaultKeys);


    uint8_t zeroBytes32[32] = {0};
    NSData *noCredential = [NSData dataWithBytes:zeroBytes32 length:32];

    QredoVaultKeyPair *keys = [self keysFromCredential:noCredential salt:SALT_KEYSTORE_KEYS];

    NSError *error = nil;
    QredoAccessLevelVaultKeys *vaultKeys = [self unmarshalData:encryptedVaultKeys unmarshaller:[QredoClientMarshallers accessLevelVaultKeysUnmarshaller] keys:keys error:&error];

    _encryptedRecoveryInfo = keychain.encryptedRecoveryInfo.encryptedMasterKey;

    QredoVaultKeyPair *defaultKeys = [vaultKeys.vaultKeys objectAtIndex:0];

    _bulkKey = defaultKeys.encryptionKey;
    _authKey = defaultKeys.authenticationKey;

    return self;
}

- (NSData*)serializeBytes:(uint8_t*)bytes length:(NSUInteger)length {
    NSData *serializedData = [QredoPrimitiveMarshallers marshalObject:[NSData dataWithBytes:bytes length:length]
                                                           marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]];

    NSData *auth = [_crypto getAuthCodeWithKey:_authKey data:serializedData];

    NSMutableData *resultData = [NSMutableData dataWithData:serializedData];
    [resultData appendData:auth];

    return resultData;
}

- (QredoVaultKeyPair *)derrivedKeysWithPassword:(NSData *)password initSalt:(NSData*)initSalt encSalt:(NSData *)encSalt authSalt:(NSData*)authSalt {
    NSData *initialDerivation = [QredoCrypto pbkdf2Sha256WithSalt:initSalt
                                            bypassSaltLengthCheck:YES
                                                     passwordData:password
                                           requiredKeyLengthBytes:32
                                                       iterations:10000];

    NSData *encryptionKey = [QredoCrypto pbkdf2Sha256WithSalt:encSalt
                                        bypassSaltLengthCheck:YES
                                                 passwordData:initialDerivation
                                       requiredKeyLengthBytes:32
                                                   iterations:1];

    NSData *authenticationKey = [QredoCrypto pbkdf2Sha256WithSalt:authSalt
                                            bypassSaltLengthCheck:YES
                                                     passwordData:initialDerivation
                                           requiredKeyLengthBytes:32
                                                       iterations:1];
    return [QredoVaultKeyPair vaultKeyPairWithEncryptionKey:encryptionKey authenticationKey:authenticationKey];
}

- (QredoVaultKeyPair *)keysFromCredential:(NSData *)credential salt:(NSData *)salt {
    return [self derrivedKeysWithPassword:credential initSalt:salt encSalt:SALT_DERIVE_CREDENTIAL_ENCRYPTION authSalt:SALT_DERIVE_CREDENTIAL_AUTHENTICATION];
}

- (NSData *)marshalObject:(id)object marshaller:(QredoMarshaller)marshaller keys:(QredoVaultKeyPair*)keys
{
    NSData *clearData = [QredoPrimitiveMarshallers marshalObject:object marshaller:marshaller];


    NSData *encryptedMessage = [_crypto encryptWithKey:keys.encryptionKey data:clearData];

    NSData *serialiedEncryptedMessage =
    [QredoPrimitiveMarshallers marshalObject:encryptedMessage
                                  marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]];

    NSData * auth = [_crypto getAuthCodeWithKey:keys.authenticationKey data:serialiedEncryptedMessage];

    NSMutableData *result = [NSMutableData data];
    [result appendData:serialiedEncryptedMessage];
    [result appendData:auth];

    return result;
}

- (id)unmarshalData:(NSData *)encryptedDataWithAuthCode unmarshaller:(QredoUnmarshaller)unmarshaller keys:(QredoVaultKeyPair *)keys error:(NSError **)error
{
    BOOL verified = [_crypto verifyAuthCodeWithKey:keys.authenticationKey data:encryptedDataWithAuthCode];

    if (!verified) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationWrongAuthenticationCode
                                     userInfo:@{NSLocalizedDescriptionKey: @"Authentication code doesn't match"}];
        }
        return nil;
    }

    NSData *encryptedData = [encryptedDataWithAuthCode subdataWithRange:NSMakeRange(0, encryptedDataWithAuthCode.length - CC_SHA256_DIGEST_LENGTH)];


    NSData *deserializedEncryptedData = [QredoPrimitiveMarshallers unmarshalObject:encryptedData
                                                                      unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]];


    NSData *decryptedMessageData = [_crypto decryptWithKey:keys.encryptionKey data:deserializedEncryptedData];


    return [QredoPrimitiveMarshallers unmarshalObject:decryptedMessageData unmarshaller:unmarshaller];
}

- (QredoVaultKeyPair *)vaultKeys
{
    return [QredoVaultKeyPair vaultKeyPairWithEncryptionKey:_bulkKey authenticationKey:_authKey];
}

- (NSData *)data
{
    if (!_isInitialized) return nil;


    NSData *zeroData32 = [NSData dataWithBytes:zeroBytes32 length:32];

    NSData *noCredential = [NSData dataWithBytes:zeroBytes32 length:32];

    QredoVaultKeyPair *vaultKeyPair = [QredoVaultKeyPair vaultKeyPairWithEncryptionKey:_bulkKey authenticationKey:_authKey];

    QredoVaultKeyPair *zeroKeyPair = [QredoVaultKeyPair vaultKeyPairWithEncryptionKey:zeroData32 authenticationKey:zeroData32];

    QredoAccessLevelVaultKeys *accessLevelVaultKeys = [QredoAccessLevelVaultKeys accessLevelVaultKeysWithMaxAccessLevel:@0
                                                                                                              vaultKeys:@[vaultKeyPair,
                                                                                                                          zeroKeyPair,
                                                                                                                          zeroKeyPair,
                                                                                                                          zeroKeyPair,
                                                                                                                          zeroKeyPair]];

    QredoVaultKeyPair *keystoreKeys = [self keysFromCredential:noCredential salt:SALT_KEYSTORE_KEYS];


    NSData *encryptedVaultKeys = [self marshalObject:accessLevelVaultKeys marshaller:[QredoClientMarshallers accessLevelVaultKeysMarshaller] keys:keystoreKeys];

    QredoVaultKeyStore *vaultKeyStore = [QredoVaultKeyStore vaultKeyStoreWithAccessLevel:@0
                                                                          credentialType:[NSNumber numberWithInt:QredoCredentialTypeNoCredential]
                                                                      encryptedVaultKeys:encryptedVaultKeys];

    QredoVaultInfoType *vaultInfoType = [QredoVaultInfoType vaultInfoTypeWithVaultID:_vaultId
                                                                            keyStore:[NSSet setWithObject:vaultKeyStore]];


    NSData *encryptedRecoveryData = _encryptedRecoveryInfo;

    QredoEncryptedRecoveryInfoType *encryptedRecoveryInfo =
        [QredoEncryptedRecoveryInfoType encryptedRecoveryInfoTypeWithCredentialType:@0
                                                                 encryptedMasterKey:encryptedRecoveryData];

    QredoLFKeychain *keychain = [QredoLFKeychain keychainWithCredentialType:[NSNumber numberWithInt:QredoCredentialTypeNoCredential]
                                                               operatorInfo:_operatorInfo
                                                                  vaultInfo:vaultInfoType
                                                      encryptedRecoveryInfo:encryptedRecoveryInfo];

    NSData *keychainData = [QredoPrimitiveMarshallers marshalObject:keychain marshaller:[QredoClientMarshallers keychainMarshaller]];

    return keychainData;
}

- (void)setVaultId:(QredoQUID*)newVaultId {
    _vaultId = newVaultId;
}

- (void)generateNewKeys
{
    _isInitialized = YES;
    _vaultId = [QredoQUID QUID];

    NSData *masterKey = [NSData dataWithRandomBytesOfLength:32];
    NSData *noCredential = [NSData dataWithBytes:zeroBytes32 length:32];
    QredoVaultKeyPair *recoveryInfoKeys = [self keysFromCredential:noCredential salt:SALT_RECOVERY_INFO];
    QredoRecoveryInfoType *recoveryInfo = [QredoRecoveryInfoType recoveryInfoTypeWithCredentialType:[NSNumber numberWithInteger:QredoCredentialTypeRandomBytes]
                                                                                          masterKey:masterKey];

    _encryptedRecoveryInfo = [self marshalObject:recoveryInfo
                                      marshaller:[QredoClientMarshallers recoveryInfoTypeMarshaller] keys:recoveryInfoKeys];


    QredoVaultKeyPair *keys = [self derrivedKeysWithPassword:masterKey initSalt:SALT_DERIVE_VAULT_KEYS encSalt:SALT_DERIVE_VAULT_ENCRYPTION_0 authSalt:SALT_DERIVE_VAULT_AUTHENTICATION_0];
    _bulkKey = keys.encryptionKey;
    _authKey = keys.authenticationKey;
}

- (void)setVaultAuthKey:(NSData *)authKey bulkKey:(NSData *)bulkKey
{
    _isInitialized = YES;
    _authKey = [authKey copy];
    _bulkKey = [bulkKey copy];
}

- (QredoQUID *)vaultId
{
    return _vaultId;
}



@end
