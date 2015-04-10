#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"

@interface QredoVaultCrypto : NSObject

@property (readonly) NSData *bulkKey;
@property (readonly) NSData *authenticationKey;

+ (instancetype)vaultCryptoWithBulkKey:(NSData *)bulkKey authenticationKey:(NSData *)authenticationKey;

- (instancetype)initWithBulkKey:(NSData *)bulkKey authenticationKey:(NSData *)authenticationKey;

- (QLFEncryptedVaultItemHeader *)encryptVaultItemHeaderWithItemRef:(QLFVaultItemRef *)vaultItemRef
                                                          metadata:(QLFVaultItemMetadata *)metadata;

- (QLFEncryptedVaultItem *)encryptVaultItemWithBody:(NSData *)body
                           encryptedVaultItemHeader:( QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader;

- (QLFVaultItem *)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem;
- (QLFVaultItemMetadata *)decryptEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader;


// Used for testing
+ (NSData *)vaultMasterKeyWithUserMasterKey:(NSData *)userMasterKey;
+ (NSData *)vaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey info:(NSString *)info;
+ (QredoED25519SigningKey *)ownershipSigningKeyWithVaultKey:(NSData *)vaultKey;
+ (QLFVaultKeyPair *)vaultKeyPairWithVaultKey:(NSData *)vaultKey;

@end