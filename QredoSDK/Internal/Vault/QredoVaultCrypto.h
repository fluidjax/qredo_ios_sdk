#import <Foundation/Foundation.h>
#import "QredoClient.h"

@interface QredoVaultCrypto : NSObject

@property (readonly) NSData *bulkKey;
@property (readonly) NSData *authenticationKey;

+ (instancetype)vaultCryptoWithBulkKey:(NSData *)bulkKey authenticationKey:(NSData *)authenticationKey;

- (instancetype)initWithBulkKey:(NSData *)bulkKey authenticationKey:(NSData *)authenticationKey;

- (QLFEncryptedVaultItem *)encryptVaultItemLF:(QLFVaultItemLF *)vaultItemLF
                                   descriptor:(QLFVaultItemDescriptorLF *)vaultItemDescriptor;
- (QLFVaultItemLF *)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem;
- (QLFVaultItemMetaDataLF *)decryptEncryptedVaultItemMetaData:(QLFEncryptedVaultItemMetaData *)encryptedVaultItemMetaData;

@end