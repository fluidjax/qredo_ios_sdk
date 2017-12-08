/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoED25519SigningKey.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "QredoKeyRefPair.h"

@class QredoKeyRef;


@interface QredoVaultKeys :NSObject


@property QredoKeyRefPair *ownershipKeyPairRef;
@property QredoKeyRef *encryptionKeyRef;
@property QredoKeyRef *authenticationKeyRef;
@property QredoQUID *vaultId;
@property QredoKeyRef *vaultKeyRef;

-(instancetype)initWithVaultKeyRef:(QredoKeyRef *)vaultKeyRef;
@end


@interface QredoVaultCrypto :NSObject

@property (readonly) QredoKeyRef *bulkKeyRef;
@property (readonly) QredoKeyRef *authenticationKeyRef;

+(instancetype)vaultCryptoWithBulkKeyRef:(QredoKeyRef *)bulkKeyRef authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef;

-(instancetype)initWithBulkKeyRef:(QredoKeyRef *)bulkKeyRef authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef;

-(QLFEncryptedVaultItemHeader *)encryptVaultItemHeaderWithItemRef:(QLFVaultItemRef *)vaultItemRef
                                                         metadata:(QLFVaultItemMetadata *)metadata
                                                               iv:(NSData*)iv;

-(QLFEncryptedVaultItem *)encryptVaultItemWithBody:(NSData *)body
                          encryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                                                iv:(NSData*)iv;

-(QLFVaultItem *)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem
                                     error:(NSError **)error;
-(QLFVaultItemMetadata *)decryptEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                                                   error:(NSError **)error;

+(QredoKeyRef *)systemVaultKeyRefWithVaultMasterKeyRef:(QredoKeyRef *)vaultMasterKeyRef;
+(QredoKeyRef *)userVaultKeyRefWithVaultMasterKeyRef:(QredoKeyRef *)vaultMasterKeyRef;

//Used for testing
+(QredoKeyRef *)vaultMasterKeyRefWithUserMasterKeyRef:(QredoKeyRef *)userMasterKeyRef;
+(QredoKeyRef *)vaultKeyRefWithVaultMasterKeyRef:(QredoKeyRef *)vaultMasterKeyRef infoData:(NSData *)infoData;
+(QredoKeyRef *)vaultKeyRefWithVaultMasterKeyRef:(QredoKeyRef *)vaultMasterKeyRef info:(NSString *)info;
+(QLFVaultKeyPair *)vaultKeyPairWithVaultKeyRef:(QredoKeyRef *)vaultKey;

-(void)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem
                          origin:(QredoVaultItemOrigin)origin
               completionHandler:(void (^)(QredoVaultItem *vaultItem,NSError *error))completionHandler;

-(void)decryptEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                                origin:(QredoVaultItemOrigin)origin
                     completionHandler:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,NSError *error))completionHandler;

@end
