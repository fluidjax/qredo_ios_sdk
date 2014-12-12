/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychain.h"
#import "QredoClientMarshallers.h"
#import "CryptoImplV1.h"
#import "QredoCrypto.h"
#import "QredoErrorCodes.h"
#import <CommonCrypto/CommonCrypto.h>

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

static int QredoKeychainNoCredentialType = 0;

@interface QredoKeychain ()
{
    BOOL isInitialized;
    QredoQUID *vaultId;
    QredoOperatorInfo *operatorInfo;

    NSData *authKey;
    NSData *bulkKey;

    CryptoImplV1 *crypto;
}

@end

@implementation QredoKeychain

- (void)initialize {
    crypto = [CryptoImplV1 new];
}

- (instancetype)initWithOperatorInfo:(QredoOperatorInfo *)_operatorInfo
{
    self = [super init];

    [self initialize];

    isInitialized = NO;
    operatorInfo = _operatorInfo;

    return self;
}

- (instancetype)initWithData:(NSData *)serializedData
{
    self = [super init];

    [self initialize];

    isInitialized = YES;

    QredoLFKeychain *keychain = [QredoPrimitiveMarshallers unmarshalObject:serializedData unmarshaller:[QredoClientMarshallers keychainUnmarshaller]];

    operatorInfo = keychain.operatorInfo;

    vaultId = keychain.vaultInfo.vaultID;

    QredoVaultKeyStore *keystore = (QredoVaultKeyStore*)[keychain.vaultInfo.keyStore anyObject];
    NSData *encryptedVaultKeys = keystore.encryptedVaultKeys;

    NSLog(@"%@", encryptedVaultKeys);


    uint8_t zeroBytes32[32] = {0};
    NSData *noCredential = [NSData dataWithBytes:zeroBytes32 length:32];

    QredoVaultKeyPair *keys = [self keysFromCredential:noCredential salt:SALT_KEYSTORE_KEYS];

    NSError *error = nil;
    QredoAccessLevelVaultKeys *vaultKeys = [self unmarshalData:encryptedVaultKeys unmarshaller:[QredoClientMarshallers accessLevelVaultKeysUnmarshaller] keys:keys error:&error];


    QredoVaultKeyPair *defaultKeys = [vaultKeys.vaultKeys objectAtIndex:0];
    bulkKey = defaultKeys.encryptionKey;
    authKey = defaultKeys.authenticationKey;
    return self;
}

- (NSData*)serializeBytes:(uint8_t*)bytes length:(NSUInteger)length {
    NSData *serializedData = [QredoPrimitiveMarshallers marshalObject:[NSData dataWithBytes:bytes length:length]
                                                           marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]];

    NSData *auth = [crypto getAuthCodeWithKey:authKey data:serializedData];

    NSMutableData *resultData = [NSMutableData dataWithData:serializedData];
    [resultData appendData:auth];

    return resultData;
}

- (QredoVaultKeyPair *)keysFromCredential:(NSData *)credential salt:(NSData *)salt {
    NSData *initialDerivation = [QredoCrypto pbkdf2Sha256WithSalt:salt
                                            bypassSaltLengthCheck:YES
                                                     passwordData:credential
                                           requiredKeyLengthBytes:32
                                                       iterations:10000];

    NSData *encryptionKey = [QredoCrypto pbkdf2Sha256WithSalt:SALT_DERIVE_CREDENTIAL_ENCRYPTION
                                        bypassSaltLengthCheck:YES
                                                 passwordData:initialDerivation
                                       requiredKeyLengthBytes:32
                                                   iterations:1];

    NSData *authenticationKey = [QredoCrypto pbkdf2Sha256WithSalt:SALT_DERIVE_CREDENTIAL_AUTHENTICATION
                                            bypassSaltLengthCheck:YES
                                                     passwordData:initialDerivation
                                           requiredKeyLengthBytes:32
                                                       iterations:1];
    return [QredoVaultKeyPair vaultKeyPairWithEncryptionKey:encryptionKey authenticationKey:authenticationKey];
}

- (NSData *)marshalObject:(id)object marshaller:(QredoMarshaller)marshaller keys:(QredoVaultKeyPair*)keys
{
    NSData *clearData = [QredoPrimitiveMarshallers marshalObject:object marshaller:marshaller];


    NSData *encryptedMessage = [crypto encryptWithKey:keys.encryptionKey data:clearData];

    NSData *serialiedEncryptedMessage =
    [QredoPrimitiveMarshallers marshalObject:encryptedMessage
                                  marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]];

    NSData * auth = [crypto getAuthCodeWithKey:keys.authenticationKey data:serialiedEncryptedMessage];

    NSMutableData *result = [NSMutableData data];
    [result appendData:serialiedEncryptedMessage];
    [result appendData:auth];

    return result;
}

- (id)unmarshalData:(NSData *)encryptedDataWithAuthCode unmarshaller:(QredoUnmarshaller)unmarshaller keys:(QredoVaultKeyPair *)keys error:(NSError **)error
{
    BOOL verified = [crypto verifyAuthCodeWithKey:keys.authenticationKey data:encryptedDataWithAuthCode];

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


    NSData *decryptedMessageData = [crypto decryptWithKey:keys.encryptionKey data:deserializedEncryptedData];


    return [QredoPrimitiveMarshallers unmarshalObject:decryptedMessageData unmarshaller:unmarshaller];
}

- (QredoVaultKeyPair *)vaultKeys
{
    return [QredoVaultKeyPair vaultKeyPairWithEncryptionKey:bulkKey authenticationKey:authKey];
}

- (NSData *)data
{
    if (!isInitialized) return nil;

    uint8_t zeroBytes32[32] = {0};
    NSData *zeroData32 = [NSData dataWithBytes:zeroBytes32 length:32];

    NSData *noCredential = [NSData dataWithBytes:zeroBytes32 length:32];

    QredoVaultKeyPair *vaultKeyPair = [QredoVaultKeyPair vaultKeyPairWithEncryptionKey:bulkKey authenticationKey:authKey];

    QredoVaultKeyPair *zeroKeyPair = [QredoVaultKeyPair vaultKeyPairWithEncryptionKey:zeroData32 authenticationKey:zeroData32];


    QredoAccessLevelVaultKeys *accessLevelVaultKeys = [QredoAccessLevelVaultKeys accessLevelVaultKeysWithMaxAccessLevel:@0
                                                                                                              vaultKeys:@[vaultKeyPair,
                                                                                                                          zeroKeyPair,
                                                                                                                          zeroKeyPair,
                                                                                                                          zeroKeyPair,
                                                                                                                          zeroKeyPair]];






    QredoVaultKeyPair *keys = [self keysFromCredential:noCredential salt:SALT_KEYSTORE_KEYS];

    NSData *encryptedVaultKeys = [self marshalObject:accessLevelVaultKeys marshaller:[QredoClientMarshallers accessLevelVaultKeysMarshaller] keys:keys];

    QredoVaultKeyStore *vaultKeyStore = [QredoVaultKeyStore vaultKeyStoreWithAccessLevel:@0
                                                                          credentialType:[NSNumber numberWithInt:QredoKeychainNoCredentialType]
                                                                      encryptedVaultKeys:encryptedVaultKeys];


    QredoVaultInfoType *vaultInfoType = [QredoVaultInfoType vaultInfoTypeWithVaultID:vaultId
                                                                            keyStore:[NSSet setWithObject:vaultKeyStore]];


    uint8_t encryptedMasterKeyBytes[144] = {
        0x35, 0x1b, 0xf8, 0x0c, 0xe4, 0x36, 0x8c, 0x19, 0x9d, 0x78, 0x7a, 0x0a,
        0x6a, 0xbc, 0xab, 0x9f, 0x1b, 0x49, 0x47, 0x26, 0x07, 0x3e, 0xaa, 0x42,
        0xc0, 0xfb, 0x7d, 0xc1, 0xf0, 0xe2, 0x4e, 0x02, 0x50, 0x87, 0xcb, 0x68,
        0x17, 0xdb, 0xe9, 0x6c, 0xa4, 0x6c, 0x09, 0x6d, 0xcb, 0x12, 0x85, 0xad,
        0x4e, 0xf4, 0xd1, 0x26, 0xa4, 0x2b, 0x69, 0xf3, 0xff, 0x63, 0x6d, 0xd1,
        0xb3, 0x87, 0xbf, 0x64, 0x3e, 0x95, 0xac, 0x7c, 0x3e, 0x24, 0xb3, 0x9e,
        0x79, 0x68, 0xcb, 0x20, 0x2d, 0x5a, 0x72, 0x40, 0x44, 0xb5, 0x12, 0x27,
        0x22, 0x2d, 0xd0, 0xc3, 0x14, 0x03, 0xd0, 0xa2, 0x17, 0x02, 0xaf, 0x9c,
        0x52, 0x95, 0xdb, 0x33, 0x51, 0x8f, 0xce, 0x38, 0x54, 0x7c, 0x75, 0x8c,
        0xa3, 0xc5, 0x80, 0x56, 0x37, 0x2c, 0xb3, 0x49, 0x7d, 0xe5, 0xcf, 0x01,
        0xf4, 0x49, 0x57, 0x5b, 0x78, 0x6c, 0x9f, 0x15, 0x4b, 0x56, 0xa4, 0x6f,
        0x99, 0xba, 0x13, 0x56, 0x1f, 0x9b, 0xbe, 0x67, 0x04, 0xa4, 0x94, 0x22
    };

    QredoEncryptedRecoveryInfoType *encryptedRecoveryInfo =
        [QredoEncryptedRecoveryInfoType encryptedRecoveryInfoTypeWithCredentialType:@0
                                                                 encryptedMasterKey:[self serializeBytes:encryptedMasterKeyBytes length:sizeof(encryptedMasterKeyBytes)]];

    QredoLFKeychain *keychain = [QredoLFKeychain keychainWithCredentialType:[NSNumber numberWithInt:QredoKeychainNoCredentialType]
                                                               operatorInfo:operatorInfo
                                                                  vaultInfo:vaultInfoType
                                                      encryptedRecoveryInfo:encryptedRecoveryInfo];

    NSData *keychainData = [QredoPrimitiveMarshallers marshalObject:keychain marshaller:[QredoClientMarshallers keychainMarshaller]];

    return keychainData;
}

- (void)setVaultId:(QredoQUID*)newVaultId {
    vaultId = newVaultId;
}

- (void)generateNewKeys
{
    isInitialized = YES;
}

- (void)setVaultAuthKey:(NSData *)_authKey bulkKey:(NSData *)_bulkKey
{
    isInitialized = YES;
    authKey = [_authKey copy];
    bulkKey = [_bulkKey copy];
}

- (QredoQUID *)vaultId
{
    return vaultId;
}

- (NSData *)vaultBulkKeyForAccessLevel:(int)accessLevel credential:(NSData *)credential
{
    return nil;
}

- (NSData *)vaultAuthKeyForAccessLevel:(int)accessLevel credential:(NSData *)credential
{
    return nil;
}


@end
