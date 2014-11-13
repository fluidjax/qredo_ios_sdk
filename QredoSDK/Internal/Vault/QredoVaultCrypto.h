#import <Foundation/Foundation.h>
#import "QredoClient.h"

@interface QredoVaultCrypto : NSObject

@property (readonly) NSData *bulkKey;
@property (readonly) NSData *authenticationKey;

+ (instancetype)vaultCryptoWithBulkKey:(NSData *)bulkKey authenticationKey:(NSData *)authenticationKey;

- (instancetype)initWithBulkKey:(NSData *)bulkKey authenticationKey:(NSData *)authenticationKey;

- (QredoEncryptedVaultItem *)encryptVaultItemLF:(QredoVaultItemLF *)vaultItemLF
                                     descriptor:(QredoInternalVaultItemDescriptor *)vaultItemDescriptor;
- (QredoVaultItemLF *)decryptEncryptedVaultItem:(QredoEncryptedVaultItem *)encryptedVaultItem;
- (QredoVaultItemMetaDataLF *)decryptEncryptedVaultItemMetaData:(QredoEncryptedVaultItemMetaData *)encryptedVaultItemMetaData;

@end