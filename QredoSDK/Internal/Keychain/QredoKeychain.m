/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychain.h"
#import "CryptoImplV1.h"
#import "QredoCrypto.h"
#import "QredoErrorCodes.h"
#import <CommonCrypto/CommonCrypto.h>
#import "NSData+QredoRandomData.h"

#define SALT_RECOVERY_INFO [@"Zestybus" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_KEYSTORE_KEYS [@"Ferirama" dataUsingEncoding:NSUTF8StringEncoding]

// TODO: DH - replace 'Bioyino' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_CREDENTIAL_AUTHENTICATION [@"Bioyino" dataUsingEncoding:NSUTF8StringEncoding]
// TODO: DH - replace 'Waratel' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_CREDENTIAL_ENCRYPTION [@"Waratel" dataUsingEncoding:NSUTF8StringEncoding]

#define SALT_KEYCHAIN_ENCRYPTION [@"Ukewaiqv" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_KEYCHAIN_AUTHENTICATION [@"Owyurdefip" dataUsingEncoding:NSUTF8StringEncoding]

// TODO: DH - replace 'Goulbap' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_VAULT_KEYS [@"Goulbap" dataUsingEncoding:NSUTF8StringEncoding]

// TODO: DH - replace 'Replitz' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_VAULT_ENCRYPTION_0 [@"Replitz" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_1 [@"Dizoolexa" dataUsingEncoding:NSUTF8StringEncoding]
// TODO: DH - replace 'Aloidia' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_VAULT_ENCRYPTION_2 [@"Aloidia" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_3 [@"Loheckle" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_4 [@"Uliratha" dataUsingEncoding:NSUTF8StringEncoding]

#define SALT_DERIVE_VAULT_AUTHENTICATION_0 [@"Loopnova" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_1 [@"Mogotrevo" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_2 [@"Ethosien" dataUsingEncoding:NSUTF8StringEncoding]

// TODO: DH - replace 'Hioffpo' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_VAULT_AUTHENTICATION_3 [@"Hioffpo" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_4 [@"Yokovich" dataUsingEncoding:NSUTF8StringEncoding]

static uint8_t zeroBytes32[32] = {0};

@interface QredoKeychain ()
{
    BOOL _isInitialized;
    QredoQUID *_vaultId;
    QredoED25519SigningKey *_vaultSigningKey;

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

- (instancetype)initWithOperatorInfo:(QLFOperatorInfo *)operatorInfo {
    self = [super init];
    if (self) {
        [self initialize];
        _isInitialized = NO;
        _operatorInfo = operatorInfo;
    }
    return self;
}

- (instancetype)initWithOperatorInfo:(QLFOperatorInfo *)operatorInfo vaultId:(QredoQUID*)vaultId authenticationKey:(NSData*)authenticationKey bulkKey:(NSData*)bulkKey
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

    QLFKeychain *keychain = [QredoPrimitiveMarshallers unmarshalObject:serializedData unmarshaller:[QLFKeychain unmarshaller]];

    _operatorInfo = keychain.operatorInfo;

    _vaultId = keychain.vaultInfo.vaultID;
    QredoED25519VerifyKey *vaultVerifyKey = [[QredoED25519VerifyKey alloc] initWithKeyData:_vaultId.data];

    _vaultSigningKey = [[QredoED25519SigningKey alloc] initWithSeed:nil
                                                            keyData:keychain.vaultInfo.ownershipPrivateKey
                                                          verifyKey:vaultVerifyKey];

    QLFVaultKeyStore *keystore = (QLFVaultKeyStore*)[keychain.vaultInfo.keyStore anyObject];
    NSData *encryptedVaultKeys = keystore.encryptedVaultKeys;

    uint8_t zeroBytes32[32] = {0};
    NSData *noCredential = [NSData dataWithBytes:zeroBytes32 length:32];

    QLFVaultKeyPair *keys = [self keysFromCredential:noCredential salt:SALT_KEYSTORE_KEYS];

    NSError *error = nil;
    QLFAccessLevelVaultKeys *vaultKeys = [self unmarshalData:encryptedVaultKeys
                                                unmarshaller:[QLFAccessLevelVaultKeys unmarshaller]
                                                        keys:keys
                                                       error:&error];

    _encryptedRecoveryInfo = keychain.encryptedRecoveryInfo.encryptedMasterKey;

    QLFVaultKeyPair *defaultKeys = [vaultKeys.vaultKeys objectAtIndex:0];

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

- (QLFVaultKeyPair *)derrivedKeysWithPassword:(NSData *)password initSalt:(NSData*)initSalt encSalt:(NSData *)encSalt authSalt:(NSData*)authSalt {
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
    return [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:encryptionKey authenticationKey:authenticationKey];
}

- (QLFVaultKeyPair *)keysFromCredential:(NSData *)credential salt:(NSData *)salt {
    return [self derrivedKeysWithPassword:credential initSalt:salt encSalt:SALT_DERIVE_CREDENTIAL_ENCRYPTION authSalt:SALT_DERIVE_CREDENTIAL_AUTHENTICATION];
}

- (NSData *)marshalObject:(id)object marshaller:(QredoMarshaller)marshaller keys:(QLFVaultKeyPair*)keys
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

- (id)unmarshalData:(NSData *)encryptedDataWithAuthCode unmarshaller:(QredoUnmarshaller)unmarshaller keys:(QLFVaultKeyPair *)keys error:(NSError **)error
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

- (QLFVaultKeyPair *)vaultKeys
{
    return [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:_bulkKey authenticationKey:_authKey];
}

- (NSData *)data
{
    if (!_isInitialized) return nil;


    NSData *zeroData32 = [NSData dataWithBytes:zeroBytes32 length:32];

    NSData *noCredential = [NSData dataWithBytes:zeroBytes32 length:32];

    QLFVaultKeyPair *vaultKeyPair = [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:_bulkKey authenticationKey:_authKey];

    QLFVaultKeyPair *zeroKeyPair = [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:zeroData32 authenticationKey:zeroData32];

    QLFAccessLevelVaultKeys *accessLevelVaultKeys = [QLFAccessLevelVaultKeys accessLevelVaultKeysWithMaxAccessLevel:0
                                                                                                              vaultKeys:@[vaultKeyPair,
                                                                                                                          zeroKeyPair,
                                                                                                                          zeroKeyPair,
                                                                                                                          zeroKeyPair,
                                                                                                                          zeroKeyPair]];

    QLFVaultKeyPair *keystoreKeys = [self keysFromCredential:noCredential salt:SALT_KEYSTORE_KEYS];


    NSData *encryptedVaultKeys = [self marshalObject:accessLevelVaultKeys marshaller:[QLFAccessLevelVaultKeys marshaller] keys:keystoreKeys];

    QLFVaultKeyStore *vaultKeyStore = [QLFVaultKeyStore vaultKeyStoreWithAccessLevel:0
                                                                      credentialType:QredoCredentialTypeNoCredential
                                                                  encryptedVaultKeys:encryptedVaultKeys];

    QLFVaultInfoType *vaultInfoType = [QLFVaultInfoType vaultInfoTypeWithVaultID:_vaultId
                                                             ownershipPrivateKey:_vaultSigningKey.data
                                                                        keyStore:[NSSet setWithObject:vaultKeyStore]];


    NSData *encryptedRecoveryData = _encryptedRecoveryInfo;

    QLFEncryptedRecoveryInfoType *encryptedRecoveryInfo =
    [QLFEncryptedRecoveryInfoType encryptedRecoveryInfoTypeWithCredentialType:0
                                                           encryptedMasterKey:encryptedRecoveryData];

    QLFKeychain *keychain = [QLFKeychain keychainWithCredentialType:QredoCredentialTypeNoCredential
                                                       operatorInfo:_operatorInfo
                                                          vaultInfo:vaultInfoType
                                              encryptedRecoveryInfo:encryptedRecoveryInfo];

    NSData *keychainData = [QredoPrimitiveMarshallers marshalObject:keychain marshaller:[QLFKeychain marshaller]];

    return keychainData;
}

- (void)setVaultId:(QredoQUID*)newVaultId {
    _vaultId = newVaultId;
}

- (void)generateNewKeys
{
    _isInitialized = YES;

    _vaultSigningKey = [[CryptoImplV1 sharedInstance] qredoED25519SigningKey];

    _vaultId = [[QredoQUID alloc] initWithQUIDData:_vaultSigningKey.verifyKey.data];

    NSData *masterKey = [NSData dataWithRandomBytesOfLength:32];
    NSData *noCredential = [NSData dataWithBytes:zeroBytes32 length:32];
    QLFVaultKeyPair *recoveryInfoKeys = [self keysFromCredential:noCredential salt:SALT_RECOVERY_INFO];
    QLFRecoveryInfoType *recoveryInfo = [QLFRecoveryInfoType recoveryInfoTypeWithCredentialType:QredoCredentialTypeRandomBytes
                                                                                      masterKey:masterKey];

    _encryptedRecoveryInfo = [self marshalObject:recoveryInfo
                                      marshaller:[QLFRecoveryInfoType marshaller] keys:recoveryInfoKeys];


    QLFVaultKeyPair *keys = [self derrivedKeysWithPassword:masterKey initSalt:SALT_DERIVE_VAULT_KEYS encSalt:SALT_DERIVE_VAULT_ENCRYPTION_0 authSalt:SALT_DERIVE_VAULT_AUTHENTICATION_0];
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

- (QredoED25519SigningKey *)vaultSigningKey
{
    return _vaultSigningKey;
}

@end
