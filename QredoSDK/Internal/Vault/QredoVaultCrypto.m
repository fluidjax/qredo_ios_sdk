#import "QredoVaultCrypto.h"
#import "QredoCrypto.h"
#import "NSData+QredoRandomData.h"

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

- (QLFEncryptedVaultItem *)encryptVaultItemLF:(QLFVaultItemLF *)vaultItemLF
                                   descriptor:(QLFVaultItemDescriptorLF *)vaultItemDescriptor {

    // Extract...
    QLFVaultItemMetaDataLF *vaultItemMetaDataLF = [vaultItemLF metadata];
    NSData *vaultItemValue = [vaultItemLF value];

    // Encrypt...
    QLFEncryptedVaultItemMetaData *encryptedVaultItemMetaData =
            [self encryptVaultItemMetaData:vaultItemMetaDataLF
                       vaultItemDescriptor:vaultItemDescriptor];
    NSData *encryptedVaultItemValue = vaultItemValue ? [self encryptVaultItemValue:vaultItemValue] : [NSData data];

    // Package...
    return [QLFEncryptedVaultItem encryptedVaultItemWithMeta:encryptedVaultItemMetaData
                                              encryptedValue:encryptedVaultItemValue];

}

- (QLFVaultItemLF *)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem {

    QLFVaultItemMetaDataLF *vaultItemMetaDataLF =
            [self decryptEncryptedVaultItemMetaData:[encryptedVaultItem meta]];
    NSData *value = [self decryptData:[encryptedVaultItem encryptedValue] key:_bulkKey];

    return [QLFVaultItemLF vaultItemLFWithMetadata:vaultItemMetaDataLF
                                             value:value];

}

- (QLFVaultItemMetaDataLF *)decryptEncryptedVaultItemMetaData:(QLFEncryptedVaultItemMetaData *)encryptedVaultItemMetaData
{
    NSData *encryptedHeaders = [encryptedVaultItemMetaData encryptedHeaders];
    NSData *decryptedHeaders = [self decryptData:encryptedHeaders key:_bulkKey];

    return [QredoPrimitiveMarshallers unmarshalObject:decryptedHeaders
                                         unmarshaller:[QLFVaultItemMetaDataLF unmarshaller]];

}

- (QLFEncryptedVaultItemMetaData *)encryptVaultItemMetaData:(QLFVaultItemMetaDataLF *)vaultItemMetaDataLF
                                        vaultItemDescriptor:(QLFVaultItemDescriptorLF *)vaultItemDescriptor {

    NSData *serializedHeaders = [QredoPrimitiveMarshallers marshalObject:vaultItemMetaDataLF
                                                              marshaller:[QLFVaultItemMetaDataLF marshaller]];
    NSData *encryptedHeaders = [self encryptData:serializedHeaders key:_bulkKey];
    QLFVaultId *vaultId = [vaultItemDescriptor vaultId];
    QLFVaultSequenceId *sequenceId = [vaultItemDescriptor sequenceId];

    return [QLFEncryptedVaultItemMetaData encryptedVaultItemMetaDataWithVaultId:vaultId
                                                                     sequenceId:sequenceId
                                                                  sequenceValue:[vaultItemDescriptor sequenceValue]
                                                                         itemId:[vaultItemDescriptor itemId]
                                                               encryptedHeaders:encryptedHeaders];
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