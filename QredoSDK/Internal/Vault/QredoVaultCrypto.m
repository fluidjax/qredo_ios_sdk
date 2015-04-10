#import "QredoVaultCrypto.h"
#import "QredoCrypto.h"
#import "NSData+QredoRandomData.h"
#import "CryptoImplV1.h"

#define QREDO_VAULT_MASTER_SALT  [@"U7TIOyVRqCKuFFNa" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_VAULT_SUBTYPE_SALT [@"rf3cxEQ8B9Nc8uFj" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_VAULT_LEAF_SALT    [@"pCN6lt8gryL3d0BN" dataUsingEncoding:NSUTF8StringEncoding]

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

    NSData *encryptedMetadata = [self encryptData:serializedMetadata key:_bulkKey];

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
    NSData *encryptedBody = [self encryptData:body key:_bulkKey];
    NSData *authCode = [self authenticationCodeWithData:encryptedBody vaultItemRef:encryptedVaultItemHeader.ref];

    return [QLFEncryptedVaultItem encryptedVaultItemWithHeader:encryptedVaultItemHeader
                                                 encryptedBody:encryptedBody
                                                      authCode:authCode];
}

- (QLFEncryptedVaultItem *)encryptVaultItemLF:(QLFVaultItem *)vaultItemLF
                                   descriptor:(QLFVaultItemRef *)vaultItemDescriptor {

    // Extract...
    QLFVaultItemMetadata *vaultItemMetaDataLF = [vaultItemLF metadata];
    NSData *vaultItemValue = [vaultItemLF body];

    // Encrypt...
    QLFEncryptedVaultItemHeader *encryptedVaultItemMetaData =
            [self encryptVaultItemMetaData:vaultItemMetaDataLF
                       vaultItemDescriptor:vaultItemDescriptor];
    NSData *encryptedVaultItemValue = vaultItemValue ? [self encryptVaultItemValue:vaultItemValue] : [NSData data];

    // Package...
    return [QLFEncryptedVaultItem encryptedVaultItemWithHeader:encryptedVaultItemMetaData
                                                 encryptedBody:encryptedVaultItemValue
                                                      authCode:nil]; // FIXME:

}

- (QLFVaultItem *)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem {

    QLFVaultItemMetadata *vaultItemMetaDataLF =
            [self decryptEncryptedVaultItemHeader:[encryptedVaultItem header]];
    NSData *value = [self decryptData:[encryptedVaultItem encryptedBody] key:_bulkKey];

    return [QLFVaultItem vaultItemWithRef:encryptedVaultItem.header.ref metadata:vaultItemMetaDataLF body:value];
}

- (QLFVaultItemMetadata *)decryptEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
{
    NSData *encryptedHeaders = [encryptedVaultItemHeader encryptedMetadata];
    NSData *decryptedHeaders = [self decryptData:encryptedHeaders key:_bulkKey];

    return [QredoPrimitiveMarshallers unmarshalObject:decryptedHeaders
                                         unmarshaller:[QLFVaultItemMetadata unmarshaller]];

}

- (QLFEncryptedVaultItemHeader *)encryptVaultItemMetaData:(QLFVaultItemMetadata *)vaultItemMetaDataLF
                                      vaultItemDescriptor:(QLFVaultItemRef *)vaultItemDescriptor
{

    NSData *serializedHeaders = [QredoPrimitiveMarshallers marshalObject:vaultItemMetaDataLF
                                                              marshaller:[QLFVaultItemMetadata marshaller]];
    NSData *encryptedHeaders = [self encryptData:serializedHeaders key:_bulkKey];
    QLFVaultId *vaultId = [vaultItemDescriptor vaultId];
    QLFVaultSequenceId *sequenceId = [vaultItemDescriptor sequenceId];

    QLFVaultItemRef *vaultItemRef = [QLFVaultItemRef vaultItemRefWithVaultId:vaultId
                                                                  sequenceId:sequenceId
                                                               sequenceValue:[vaultItemDescriptor sequenceValue]
                                                                      itemId:[vaultItemDescriptor itemId]];

    return [QLFEncryptedVaultItemHeader encryptedVaultItemHeaderWithRef:vaultItemRef
                                                      encryptedMetadata:encryptedHeaders
                                                               authCode:nil]; // FIXME:
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
    NSData *encryptedData = [QredoCrypto encryptData:data withAesKey:key iv:iv];
    NSMutableData *encryptedDataWithIv = [NSMutableData dataWithData:iv];
    [encryptedDataWithIv appendData:encryptedData];
    return encryptedDataWithIv;
}

- (NSData *)encryptVaultItemValue:(NSData *)data {
    return [self encryptData:data key:_bulkKey];
}

@end