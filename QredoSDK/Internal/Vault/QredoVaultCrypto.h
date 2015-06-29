#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"

@interface QredoVaultKeys : NSObject

@property QredoED25519SigningKey *ownershipKeyPair;
@property QLFEncryptionKey256 *encryptionKey;
@property QLFAuthenticationKey256 *authenticationKey;
@property QredoQUID *vaultId;
@property NSData *vaultKey;

- (instancetype)initWithVaultKey:(NSData *)vaultKey;
@end


@interface QredoVaultCrypto : NSObject

@property (readonly) NSData *bulkKey;
@property (readonly) NSData *authenticationKey;

+ (instancetype)vaultCryptoWithBulkKey:(NSData *)bulkKey authenticationKey:(NSData *)authenticationKey;

- (instancetype)initWithBulkKey:(NSData *)bulkKey authenticationKey:(NSData *)authenticationKey;

- (QLFEncryptedVaultItemHeader *)encryptVaultItemHeaderWithItemRef:(QLFVaultItemRef *)vaultItemRef
                                                          metadata:(QLFVaultItemMetadata *)metadata;

- (QLFEncryptedVaultItem *)encryptVaultItemWithBody:(NSData *)body
                           encryptedVaultItemHeader:( QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader;

- (QLFVaultItem *)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem
                                      error:(NSError **)error;
- (QLFVaultItemMetadata *)decryptEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                                                    error:(NSError **)error;

+ (NSData *)systemVaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey;
+ (NSData *)userVaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey;

// Used for testing
+ (NSData *)vaultMasterKeyWithUserMasterKey:(NSData *)userMasterKey;
+ (NSData *)vaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey infoData:(NSData *)infoData;
+ (NSData *)vaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey info:(NSString *)info;
+ (QredoED25519SigningKey *)ownershipSigningKeyWithVaultKey:(NSData *)vaultKey;
+ (QLFVaultKeyPair *)vaultKeyPairWithVaultKey:(NSData *)vaultKey;

- (void)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem
                           origin:(QredoVaultItemOrigin)origin
                completionHandler:(void(^)(QredoVaultItem *vaultItem, NSError *error))completionHandler;

- (void)decryptEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                                 origin:(QredoVaultItemOrigin)origin
                      completionHandler:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, NSError *error))completionHandler;

@end