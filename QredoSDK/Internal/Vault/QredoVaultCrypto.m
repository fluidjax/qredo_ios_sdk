#import <CommonCrypto/CommonDigest.h>
#import "QredoVaultCrypto.h"
#import "QredoRawCrypto.h"
#import "QredoCryptoImplV1.h"
#import "QredoErrorCodes.h"
#import "NSDictionary+IndexableSet.h"
#import "QredoKeyRef.h"
#import "QredoCryptoKeychain.h"

#define QREDO_VAULT_MASTER_SALT  [@"U7TIOyVRqCKuFFNa" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_VAULT_SUBTYPE_SALT [@"rf3cxEQ8B9Nc8uFj" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_VAULT_LEAF_SALT    [@"pCN6lt8gryL3d0BN" dataUsingEncoding:NSUTF8StringEncoding]

#define QREDO_VAULT_SYSTEM_INFO  @"System Vault"
#define QREDO_VAULT_USER_INFO    @"User Vault"



@implementation QredoVaultKeys

-(instancetype)initWithVaultKey:(NSData *)vaultKey {
    self = [super init];
    if (self){
        QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
        QredoKeyRefPair *ownershipKeyPairRef = [keychain ownershipKeyPairDerive:vaultKey];
       
        QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKey:vaultKey];
        QredoQUID *vaultID = [[QredoQUID alloc] initWithQUIDData:[keychain publicKeyDataFor:ownershipKeyPairRef]];
        _vaultKey = vaultKey;
        _ownershipKeyPairRef = ownershipKeyPairRef;
        _encryptionKey = [[QredoKeyRef alloc] initWithKeyData:encryptionAndAuthKeys.encryptionKey];
        _authenticationKey = [[QredoKeyRef alloc] initWithKeyData:encryptionAndAuthKeys.authenticationKey];
        _vaultId = vaultID;
    }
    return self;
}


@end




@interface QredoVaultCrypto()
@property (readwrite) QredoKeyRef *bulkKey;
@property (readwrite) QredoKeyRef *authenticationKey;
@end


@implementation QredoVaultCrypto

///////////////////////////////////////////////////////////////////////////////
//Encryption Helpers
///////////////////////////////////////////////////////////////////////////////

+(instancetype)vaultCryptoWithBulkKey:(QredoKeyRef *)bulkKey
                    authenticationKey:(QredoKeyRef *)authenticationKey {
    return [[self alloc] initWithBulkKey:bulkKey
                      authenticationKey :authenticationKey];
}


-(instancetype)initWithBulkKey:(QredoKeyRef *)bulkKey
             authenticationKey:(QredoKeyRef *)authenticationKey {
    self = [super init];
    if (self){
        _bulkKey           = bulkKey;
        _authenticationKey = authenticationKey;
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////
//QredoVaultCrypto Interface
///////////////////////////////////////////////////////////////////////////////

+(NSData *)systemVaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey {
    return [self vaultKeyWithVaultMasterKey:vaultMasterKey info:QREDO_VAULT_SYSTEM_INFO];
}


+(NSData *)userVaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey {
    return [self vaultKeyWithVaultMasterKey:vaultMasterKey info:QREDO_VAULT_USER_INFO];
}


+(NSData *)vaultMasterKeyWithUserMasterKey:(NSData *)userMasterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:userMasterKey
                                            salt:QREDO_VAULT_MASTER_SALT];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


+(NSData *)vaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey infoData:(NSData *)infoData {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:vaultMasterKey
                                            salt:QREDO_VAULT_SUBTYPE_SALT];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:infoData
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


+(NSData *)vaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey info:(NSString *)info {
    return [self vaultKeyWithVaultMasterKey:vaultMasterKey infoData:[info dataUsingEncoding:NSUTF8StringEncoding]];
}


+(QredoED25519SigningKey *)ownershipSigningKeyWithVaultKey:(NSData *)vaultKey {
    return [[QredoCryptoImplV1 sharedInstance] qredoED25519SigningKeyWithSeed:vaultKey];
}


+(QLFVaultKeyPair *)vaultKeyPairWithVaultKey:(NSData *)vaultKey {
    NSData *info = [@"Encryption" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:vaultKey
                                            salt:QREDO_VAULT_LEAF_SALT];
    NSData *encryptionKey = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:info
                                   outputLength:CC_SHA256_DIGEST_LENGTH];

    NSData *info1 = [@"Authentication" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *prk1 = [QredoRawCrypto hkdfSha256Extract:vaultKey
                                             salt:QREDO_VAULT_LEAF_SALT];
    NSData *authentication = [QredoRawCrypto hkdfSha256Expand:prk1
                                            info:info1
                                    outputLength:CC_SHA256_DIGEST_LENGTH];

    return [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:encryptionKey authenticationKey:authentication];
}


-(NSData *)encryptMetadata:(QLFVaultItemMetadata *)metadata iv:(NSData*)iv{
    NSData *serializedMetadata = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:NO];
    
    return [self encryptIncludingMessageHeaderWithData:serializedMetadata iv:iv];
}


-(NSData *)encryptIncludingMessageHeaderWithData:(NSData *)data  iv:(NSData*)iv{
    if (!data)data = [NSData data];
    
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
    NSData *encryptedMetadata = [keychain encryptBulk:self.bulkKey plaintext:data iv:iv];
    
    NSData *encryptedMetadataWithMessageHeader =
    [QredoPrimitiveMarshallers marshalObject:encryptedMetadata
                                  marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]
                               includeHeader:YES];
    
    return encryptedMetadataWithMessageHeader;
}


-(NSData *)authenticationCodeWithData:(NSData *)data vaultItemRef:(QLFVaultItemRef *)vaultItemRef {
    NSData *serializedItemRef = [QredoPrimitiveMarshallers marshalObject:vaultItemRef includeHeader:NO];
    NSMutableData *authCodeData = [NSMutableData dataWithData:data];
    
    [authCodeData appendData:serializedItemRef];
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
    return [keychain authenticate:self.authenticationKey data:authCodeData];
}


-(QLFEncryptedVaultItemHeader *)encryptVaultItemHeaderWithItemRef:(QLFVaultItemRef *)vaultItemRef
                                                         metadata:(QLFVaultItemMetadata *)metadata
                                                               iv:(NSData*)iv{
    NSData *encryptedMetadata = [self encryptMetadata:metadata iv:iv];
    NSData *authCode = [self authenticationCodeWithData:encryptedMetadata vaultItemRef:vaultItemRef];
    
    return [QLFEncryptedVaultItemHeader encryptedVaultItemHeaderWithRef:vaultItemRef
                                                      encryptedMetadata:encryptedMetadata
                                                               authCode:authCode];
}


-(QLFEncryptedVaultItem *)encryptVaultItemWithBody:(NSData *)body
                          encryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                                                iv:(NSData*)iv{
    NSData *encryptedBody = [self encryptIncludingMessageHeaderWithData:body iv:iv];
    NSData *authCode = [self authenticationCodeWithData:encryptedBody vaultItemRef:encryptedVaultItemHeader.ref];
    
    return [QLFEncryptedVaultItem encryptedVaultItemWithHeader:encryptedVaultItemHeader
                                                 encryptedBody:encryptedBody
                                                      authCode:authCode];
}


-(QLFVaultItem *)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem
                                     error:(NSError **)error {
    QLFVaultItemMetadata *vaultItemMetaDataLF = [self decryptEncryptedVaultItemHeader:[encryptedVaultItem header] error:error];
    
    if (!vaultItemMetaDataLF)return nil;
    
    NSData *authenticationCode = [self authenticationCodeWithData:encryptedVaultItem.encryptedBody
                                                     vaultItemRef:encryptedVaultItem.header.ref];
    
    if (![authenticationCode isEqualToData:encryptedVaultItem.authCode]){
        if (error){
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeMalformedOrTamperedData
                                     userInfo:nil];
        }
        
        return nil;
    }
    
    NSData *encryptedBodyRaw    = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItem.encryptedBody
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];
    
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
    NSData *value = [keychain decryptBulk:self.bulkKey ciphertext:encryptedBodyRaw];
    
    return [QLFVaultItem vaultItemWithRef:encryptedVaultItem.header.ref metadata:vaultItemMetaDataLF body:value];
}


-(QLFVaultItemMetadata *)decryptEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                                                   error:(NSError **)error {
    NSData *authenticationCode = [self authenticationCodeWithData:encryptedVaultItemHeader.encryptedMetadata
                                                     vaultItemRef:encryptedVaultItemHeader.ref];
    
    if (![authenticationCode isEqualToData:encryptedVaultItemHeader.authCode]){
        if (error){
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
    
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
    NSData *decryptedHeaders = [keychain decryptBulk:self.bulkKey ciphertext:encyrptedHeadersRaw];
    
    return [QredoPrimitiveMarshallers unmarshalObject:decryptedHeaders
                                         unmarshaller:[QLFVaultItemMetadata unmarshaller]
                                          parseHeader:NO];
}


-(NSData *)encryptVaultItemValue:(NSData *)data {
    if (!data)data = [NSData data];
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];

    return [keychain encryptBulk:self.bulkKey plaintext:data];
}


-(void)decryptEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem
                          origin:(QredoVaultItemOrigin)origin
               completionHandler:(void (^)(QredoVaultItem *vaultItem,NSError *error))completionHandler {
    NSError *error = nil;
    
    NSError *decryptionError = nil;
    QLFVaultItem *vaultItemLF = [self decryptEncryptedVaultItem:encryptedVaultItem
                                                          error:&decryptionError];
    
    if (!vaultItemLF){
        if (!decryptionError){
            decryptionError = [NSError errorWithDomain:QredoErrorDomain
                                                  code:QredoErrorCodeMalformedOrTamperedData
                                              userInfo:nil];
        }
        
        if (completionHandler)completionHandler(nil,decryptionError);
        
        return;
    }
    
    NSDictionary *summaryValues = [vaultItemLF.metadata.values dictionaryFromIndexableSet];
    
    QredoVaultItemDescriptor *descriptor
    = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:encryptedVaultItem.header.ref.sequenceId
                                                    sequenceValue:encryptedVaultItem.header.ref.sequenceValue
                                                           itemId:encryptedVaultItem.header.ref.itemId];
    
    QredoVaultItemMetadata *metadata
    = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                     dataType:vaultItemLF.metadata.dataType
                                                      created:vaultItemLF.metadata.created.asDate
                                                summaryValues:summaryValues];
    
    metadata.origin = origin;
    
    if ([metadata.dataType isEqualToString:QredoVaultItemMetadataItemTypeTombstone]){
        error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeVaultItemHasBeenDeleted userInfo:nil];
        
        if (completionHandler)completionHandler(nil,error);
    } else {
        QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:vaultItemLF.body];
        
        if (completionHandler)completionHandler(vaultItem,nil);
    }
}


-(void)decryptEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                                origin:(QredoVaultItemOrigin)origin
                     completionHandler:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,NSError *error))completionHandler {
    NSError *error = nil;
    NSError *decryptionError = nil;
    QLFVaultItemMetadata *vaultItemMetadataLF
    = [self decryptEncryptedVaultItemHeader:encryptedVaultItemHeader
                                      error:&decryptionError];
    
    if (!vaultItemMetadataLF){
        if (!decryptionError){
            decryptionError = [NSError errorWithDomain:QredoErrorDomain
                                                  code:QredoErrorCodeMalformedOrTamperedData
                                              userInfo:nil];
        }
        
        if (completionHandler)completionHandler(nil,decryptionError);
        
        return;
    }
    
    NSDictionary *summaryValues = [vaultItemMetadataLF.values dictionaryFromIndexableSet];
    
    QredoVaultItemDescriptor *descriptor
    = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:encryptedVaultItemHeader.ref.sequenceId
                                                    sequenceValue:encryptedVaultItemHeader.ref.sequenceValue
                                                           itemId:encryptedVaultItemHeader.ref.itemId];
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                                                      dataType:vaultItemMetadataLF.dataType
                                                                                       created:vaultItemMetadataLF.created.asDate
                                                                                 summaryValues:summaryValues];
    
    metadata.origin = origin;
    
    if ([metadata.dataType isEqualToString:QredoVaultItemMetadataItemTypeTombstone]){
        error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeVaultItemHasBeenDeleted userInfo:nil];
        
        if (completionHandler)completionHandler(nil,error);
    } else {
        if (completionHandler)completionHandler(metadata,nil);
    }
}


@end
