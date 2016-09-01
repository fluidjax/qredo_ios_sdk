/* HEADER GOES HERE */
#import "QredoVaultCrypto.h"
#import "QredoCrypto.h"
#import "NSData+QredoRandomData.h"
#import "CryptoImplV1.h"
#import "QredoErrorCodes.h"
#import "NSDictionary+IndexableSet.h"
#import "QredoQUIDPrivate.h"


#define QREDO_VAULT_MASTER_SALT  [@"U7TIOyVRqCKuFFNa" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_VAULT_SUBTYPE_SALT [@"rf3cxEQ8B9Nc8uFj" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_VAULT_LEAF_SALT    [@"pCN6lt8gryL3d0BN" dataUsingEncoding:NSUTF8StringEncoding]

#define QREDO_VAULT_SYSTEM_INFO  @"System Vault"
#define QREDO_VAULT_USER_INFO    @"User Vault"

@implementation QredoVaultKeys

-(instancetype)initWithVaultKey:(NSData *)vaultKey {
    self = [super init];
    
    if (!self)return nil;
    
    QredoED25519SigningKey *ownershipKeyPair = [QredoVaultCrypto ownershipSigningKeyWithVaultKey:vaultKey];
    QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKey:vaultKey];
    QredoQUID *vaultID = [[QredoQUID alloc] initWithQUIDData:ownershipKeyPair.verifyKey.data];
    
    self.vaultKey = vaultKey;
    self.ownershipKeyPair = ownershipKeyPair;
    self.encryptionKey = encryptionAndAuthKeys.encryptionKey;
    self.authenticationKey = encryptionAndAuthKeys.authenticationKey;
    self.vaultId = vaultID;
    
    return self;
}

@end

@implementation QredoVaultCrypto

///////////////////////////////////////////////////////////////////////////////
//Encryption Helpers
///////////////////////////////////////////////////////////////////////////////

+(instancetype)vaultCryptoWithBulkKey:(NSData *)bulkKey
                    authenticationKey:(NSData *)authenticationKey {
    return [[self alloc] initWithBulkKey:bulkKey
                      authenticationKey :authenticationKey];
}

-(instancetype)initWithBulkKey:(NSData *)bulkKey
             authenticationKey:(NSData *)authenticationKey {
    self = [super init];
    _bulkKey           = bulkKey;
    _authenticationKey = authenticationKey;
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
    return [QredoCrypto hkdfSha256WithSalt:QREDO_VAULT_MASTER_SALT initialKeyMaterial:userMasterKey info:nil];
}

+(NSData *)vaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey infoData:(NSData *)infoData {
    return [QredoCrypto hkdfSha256WithSalt:QREDO_VAULT_SUBTYPE_SALT
                        initialKeyMaterial:vaultMasterKey
                                      info:infoData];
}

+(NSData *)vaultKeyWithVaultMasterKey:(NSData *)vaultMasterKey info:(NSString *)info {
    return [self vaultKeyWithVaultMasterKey:vaultMasterKey infoData:[info dataUsingEncoding:NSUTF8StringEncoding]];
}

+(QredoED25519SigningKey *)ownershipSigningKeyWithVaultKey:(NSData *)vaultKey {
    return [[CryptoImplV1 sharedInstance] qredoED25519SigningKeyWithSeed:vaultKey];
}

+(QLFVaultKeyPair *)vaultKeyPairWithVaultKey:(NSData *)vaultKey {
    NSData *encryptionKey = [QredoCrypto hkdfSha256WithSalt:QREDO_VAULT_LEAF_SALT
                                         initialKeyMaterial:vaultKey
                                                       info:[@"Encryption" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData *authentication = [QredoCrypto hkdfSha256WithSalt:QREDO_VAULT_LEAF_SALT
                                          initialKeyMaterial:vaultKey
                                                        info:[@"Authentication" dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:encryptionKey authenticationKey:authentication];
}

-(NSData *)encryptMetadata:(QLFVaultItemMetadata *)metadata {
    NSData *serializedMetadata = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:NO];
    
    return [self encryptIncludingMessageHeaderWithData:serializedMetadata];
}

-(NSData *)encryptIncludingMessageHeaderWithData:(NSData *)data {
    if (!data)data = [NSData data];
    
    NSData *encryptedMetadata = [[CryptoImplV1 sharedInstance] encryptWithKey:_bulkKey data:data];
    
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
    
    return [[CryptoImplV1 sharedInstance] getAuthCodeWithKey:_authenticationKey data:authCodeData];
}

-(QLFEncryptedVaultItemHeader *)encryptVaultItemHeaderWithItemRef:(QLFVaultItemRef *)vaultItemRef
                                                         metadata:(QLFVaultItemMetadata *)metadata {
    NSData *encryptedMetadata = [self encryptMetadata:metadata];
    NSData *authCode = [self authenticationCodeWithData:encryptedMetadata vaultItemRef:vaultItemRef];
    
    return [QLFEncryptedVaultItemHeader encryptedVaultItemHeaderWithRef:vaultItemRef
                                                      encryptedMetadata:encryptedMetadata
                                                               authCode:authCode];
}

-(QLFEncryptedVaultItem *)encryptVaultItemWithBody:(NSData *)body
                          encryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader {
    NSData *encryptedBody = [self encryptIncludingMessageHeaderWithData:body];
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
    
    NSData *encryptedBodyRaw
    = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItem.encryptedBody
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];
    
    NSData *value = [[CryptoImplV1 sharedInstance] decryptWithKey:_bulkKey data:encryptedBodyRaw];
    
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
    
    NSData *decryptedHeaders = [[CryptoImplV1 sharedInstance] decryptWithKey:_bulkKey data:encyrptedHeadersRaw];
    
    return [QredoPrimitiveMarshallers unmarshalObject:decryptedHeaders
                                         unmarshaller:[QLFVaultItemMetadata unmarshaller]
                                          parseHeader:NO];
}

-(NSData *)encryptVaultItemValue:(NSData *)data {
    if (!data)data = [NSData data];
    
    return [[CryptoImplV1 sharedInstance] encryptWithKey:_bulkKey data:data];
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