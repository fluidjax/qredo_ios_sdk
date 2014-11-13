#import "QredoVaultCrypto.h"
#import "QredoCrypto.h"
#import "NSData+QredoRandomData.h"
#import "QredoClientMarshallers.h"

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

- (QredoEncryptedVaultItem *)encryptVaultItemLF:(QredoVaultItemLF *)vaultItemLF
                                     descriptor:(QredoInternalVaultItemDescriptor *)vaultItemDescriptor {

    // Extract...
    QredoVaultItemMetaDataLF *vaultItemMetaDataLF = [vaultItemLF metadata];
    NSData *vaultItemValue = [vaultItemLF value];

    // Encrypt...
    QredoEncryptedVaultItemMetaData *encryptedVaultItemMetaData =
            [self encryptVaultItemMetaData:vaultItemMetaDataLF
                       vaultItemDescriptor:vaultItemDescriptor];
    NSData *encryptedVaultItemValue = [self encryptVaultItemValue:vaultItemValue];

    // Package...
    return [QredoEncryptedVaultItem encryptedVaultItemWithMeta:encryptedVaultItemMetaData
                                                encryptedValue:encryptedVaultItemValue];

}

- (QredoVaultItemLF *)decryptEncryptedVaultItem:(QredoEncryptedVaultItem *)encryptedVaultItem {

    QredoVaultItemMetaDataLF *vaultItemMetaDataLF =
            [self decryptEncryptedVaultItemMetaData:[encryptedVaultItem meta]];
    NSData *value = [self decryptData:[encryptedVaultItem encryptedValue] key:_bulkKey];

    return [QredoVaultItemLF vaultItemLFWithMetadata:vaultItemMetaDataLF
                                               value:value];

}

- (QredoVaultItemMetaDataLF *)decryptEncryptedVaultItemMetaData:(QredoEncryptedVaultItemMetaData *)encryptedVaultItemMetaData {

    NSData *encryptedHeaders = [encryptedVaultItemMetaData encryptedHeaders];
    NSData *decryptedHeaders = [self decryptData:encryptedHeaders key:_bulkKey];

    return [QredoPrimitiveMarshallers unmarshalObject:decryptedHeaders
                                         unmarshaller:[QredoClientMarshallers vaultItemMetaDataLFUnmarshaller]];

}

- (QredoEncryptedVaultItemMetaData *)encryptVaultItemMetaData:(QredoVaultItemMetaDataLF *)vaultItemMetaDataLF
                                          vaultItemDescriptor:(QredoInternalVaultItemDescriptor *)vaultItemDescriptor {

    NSData *serializedHeaders = [QredoPrimitiveMarshallers marshalObject:vaultItemMetaDataLF
                                                              marshaller:[QredoClientMarshallers vaultItemMetaDataLFMarshaller]];
    NSData *encryptedHeaders = [self encryptData:serializedHeaders key:_bulkKey];
    QredoVaultId *vaultId = [vaultItemDescriptor vaultId];
    QredoVaultSequenceId *sequenceId = [vaultItemDescriptor sequenceId];

    return [QredoEncryptedVaultItemMetaData encryptedVaultItemMetaDataWithVaultId:vaultId
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