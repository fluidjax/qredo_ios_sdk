#import "QredoVaultCrypto.h"
#import "QredoCrypto.h"
#import "NSData+QredoRandomData.h"
#import "CryptoImplV1.h"
#import "QredoErrorCodes.h"

#define QREDO_VAULT_MASTER_SALT  [@"U7TIOyVRqCKuFFNa" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_VAULT_SUBTYPE_SALT [@"rf3cxEQ8B9Nc8uFj" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_VAULT_LEAF_SALT    [@"pCN6lt8gryL3d0BN" dataUsingEncoding:NSUTF8StringEncoding]

#define QREDO_VAULT_SYSTEM_INFO  @"System Vault"
#define QREDO_VAULT_USER_INFO    @"User Vault"

@implementation QredoVaultCrypto

///////////////////////////////////////////////////////////////////////////////
// Encryption Helpers
///////////////////////////////////////////////////////////////////////////////

+ (instancetype)vaultCryptoWithBulkKey:(NSData *)bulkKey
                     authenticationKey:(NSData *)authenticationKey {
    return [[self alloc] initWithBulkKey:bulkKey
                       authenticationKey:authenticationKey];
}

- (instancetype)initWithBulkKey:(NSData *)bulkKey
              authenticationKey:(NSData *)authenticationKey {
    self = [super init];
    _bulkKey           = [QredoCrypto sha256:bulkKey];
    _authenticationKey = [QredoCrypto sha256:authenticationKey];
    return self;
}

///////////////////////////////////////////////////////////////////////////////
// QredoVaultCrypto Interface
///////////////////////////////////////////////////////////////////////////////

+ (NSData *)systemVaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey
{
    return [self vaultKeyWithVaultMasterKey:vaultMasterKey info:QREDO_VAULT_SYSTEM_INFO];
}

+ (NSData *)userVaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey
{
    return [self vaultKeyWithVaultMasterKey:vaultMasterKey info:QREDO_VAULT_USER_INFO];
}


+ (NSData *)vaultMasterKeyWithUserMasterKey:(NSData *)userMasterKey
{
    return [QredoCrypto hkdfSha256WithSalt:QREDO_VAULT_MASTER_SALT initialKeyMaterial:userMasterKey info:nil];
}

+ (NSData *)vaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey info:(NSString *)info
{
    return [QredoCrypto hkdfSha256WithSalt:QREDO_VAULT_SUBTYPE_SALT
                        initialKeyMaterial:vaultMasterKey
                                      info:[info dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (QredoED25519SigningKey *)ownershipSigningKeyWithVaultKey:(NSData *)vaultKey
{
    return [[CryptoImplV1 sharedInstance] qredoED25519SigningKeyWithSeed:vaultKey];
}

+ (QLFVaultKeyPair *)vaultKeyPairWithVaultKey:(NSData *)vaultKey
{
    NSData *encryptionKey = [QredoCrypto hkdfSha256WithSalt:QREDO_VAULT_LEAF_SALT
                                         initialKeyMaterial:vaultKey
                                                       info:[@"Encryption" dataUsingEncoding:NSUTF8StringEncoding]];

    NSData *authentication = [QredoCrypto hkdfSha256WithSalt:QREDO_VAULT_LEAF_SALT
                                          initialKeyMaterial:vaultKey
                                                        info:[@"Authentication" dataUsingEncoding:NSUTF8StringEncoding]];

    return [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:encryptionKey authenticationKey:authentication];
}

- (NSData *)encryptMetadata:(QLFVaultItemMetadata *)metadata
{
    NSData *serializedMetadata = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:NO];

    return [self encryptIncludingMessageHeaderWithData:serializedMetadata];
}

- (NSData *)encryptIncludingMessageHeaderWithData:(NSData *)data
{
    NSData *encryptedMetadata = [self encryptData:data key:_bulkKey];

    NSData *encryptedMetadataWithMessageHeader =
    [QredoPrimitiveMarshallers marshalObject:encryptedMetadata
                                  marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]
                               includeHeader:YES];

    return encryptedMetadataWithMessageHeader;
}

- (NSData *)authenticationCodeWithData:(NSData *)data vaultItemRef:(QLFVaultItemRef *)vaultItemRef
{
    NSData *serializedItemRef = [QredoPrimitiveMarshallers marshalObject:vaultItemRef includeHeader:NO];
    NSMutableData *authCodeData = [NSMutableData dataWithData:data];
    [authCodeData appendData:serializedItemRef];

    return [[CryptoImplV1 sharedInstance] getAuthCodeWithKey:_authenticationKey data:authCodeData];
}

- (QLFEncryptedVaultItemHeader *)encryptVaultItemHeaderWithItemRef:(QLFVaultItemRef *)vaultItemRef
                                                          metadata:(QLFVaultItemMetadata *)metadata
{
    NSData *encryptedMetadata = [self encryptMetadata:metadata];
    NSData *authCode = [self authenticationCodeWithData:encryptedMetadata vaultItemRef:vaultItemRef];

    return [QLFEncryptedVaultItemHeader encryptedVaultItemHeaderWithRef:vaultItemRef
                                                      encryptedMetadata:encryptedMetadata
                                                               authCode:authCode];
}

- (QLFEncryptedVaultItem *)encryptVaultItemWithBody:(NSData *)body
                           encryptedVaultItemHeader:( QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
{
    NSData *encryptedBody = [self encryptIncludingMessageHeaderWithData:body];
    NSData *authCode = [self authenticationCodeWithData:encryptedBody vaultItemRef:encryptedVaultItemHeader.ref];

    return [QLFEncryptedVaultItem encryptedVaultItemWithHeader:encryptedVaultItemHeader
                                                 encryptedBody:encryptedBody
                                                      authCode:authCode];
}

- (QLFVaultItem *)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem
                                      error:(NSError **)error
{

    QLFVaultItemMetadata *vaultItemMetaDataLF = [self decryptEncryptedVaultItemHeader:[encryptedVaultItem header] error:error];
    if (!vaultItemMetaDataLF) return nil;

    NSData *authenticationCode = [self authenticationCodeWithData:encryptedVaultItem.encryptedBody
                                                     vaultItemRef:encryptedVaultItem.header.ref];

    if (![authenticationCode isEqualToData:encryptedVaultItem.authCode]) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeMalformedOrTamperedData
                                     userInfo:nil];
        }
        return nil;
    }


    NSData *encryptedBodyRaw
    = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItem.encryptedBody
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];

    NSData *value = [self decryptData:encryptedBodyRaw key:_bulkKey];

    return [QLFVaultItem vaultItemWithRef:encryptedVaultItem.header.ref metadata:vaultItemMetaDataLF body:value];
}

- (QLFVaultItemMetadata *)decryptEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                                                    error:(NSError **)error
{
    NSData *authenticationCode = [self authenticationCodeWithData:encryptedVaultItemHeader.encryptedMetadata
                                                     vaultItemRef:encryptedVaultItemHeader.ref];

    if (![authenticationCode isEqualToData:encryptedVaultItemHeader.authCode]) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeMalformedOrTamperedData
                                     userInfo:nil];
        }
        return nil;
    }

    NSData *encryptedHeaders = [encryptedVaultItemHeader encryptedMetadata];
    NSData *encyrptedHeadersRaw
    = [QredoPrimitiveMarshallers unmarshalObject:encryptedHeaders
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];

    NSData *decryptedHeaders = [self decryptData:encyrptedHeadersRaw key:_bulkKey];

    return [QredoPrimitiveMarshallers unmarshalObject:decryptedHeaders
                                         unmarshaller:[QLFVaultItemMetadata unmarshaller]
                                          parseHeader:NO];

}

- (NSData *)decryptData:(NSData *)encryptedDataWithIv key:(NSData *)key {
    NSData *iv = [NSData dataWithBytes:[encryptedDataWithIv bytes]
                                length:16];
    NSData *encryptedData = [NSData dataWithBytes:[encryptedDataWithIv bytes]  + [iv length]
                                           length:[encryptedDataWithIv length] - [iv length]];
    return [QredoCrypto decryptData:encryptedData
                         withAesKey:key
                                 iv:iv];
}

- (NSData *)encryptData:(NSData *)data key:(NSData *)key {
    NSData *iv = [QredoCrypto secureRandomWithSize:16];
    NSData *encryptedData;
    if (data) {
        encryptedData = [QredoCrypto encryptData:data withAesKey:key iv:iv];
    } else {
        encryptedData = [NSData data];
    }
    NSMutableData *encryptedDataWithIv = [NSMutableData dataWithData:iv];
    [encryptedDataWithIv appendData:encryptedData];
    return encryptedDataWithIv;
}

- (NSData *)encryptVaultItemValue:(NSData *)data {
    return [self encryptData:data key:_bulkKey];
}

@end