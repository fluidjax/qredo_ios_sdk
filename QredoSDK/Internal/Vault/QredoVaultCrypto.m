/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/



#import <CommonCrypto/CommonDigest.h>
#import "QredoVaultCrypto.h"
#import "QredoCryptoRaw.h"
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

-(instancetype)initWithVaultKeyRef:(QredoKeyRef *)vaultKeyRef {
    self = [super init];
    if (self){
        QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
        QredoKeyRefPair *ownershipKeyPairRef = [keychain ownershipKeyPairDeriveRef:vaultKeyRef];
        QLFVaultKeyPair *encryptionAndAuthKeyPairRef = [QredoVaultCrypto vaultKeyPairWithVaultKeyRef:vaultKeyRef];
        QredoQUID *vaultID = [QredoQUID QUIDWithData:[keychain publicKeyDataFor:ownershipKeyPairRef]];
        _vaultKeyRef = vaultKeyRef;
        _ownershipKeyPairRef = ownershipKeyPairRef;
        _encryptionKeyRef = [QredoKeyRef keyRefWithKeyData:encryptionAndAuthKeyPairRef.encryptionKey];
        _authenticationKeyRef = [QredoKeyRef keyRefWithKeyData:encryptionAndAuthKeyPairRef.authenticationKey];
        _vaultId = vaultID;
    }
    return self;
}


@end




@interface QredoVaultCrypto()
@property (readwrite) QredoKeyRef *bulkKeyRef;
@property (readwrite) QredoKeyRef *authenticationKeyRef;
@end


@implementation QredoVaultCrypto

///////////////////////////////////////////////////////////////////////////////
//Encryption Helpers
///////////////////////////////////////////////////////////////////////////////

+(instancetype)vaultCryptoWithBulkKeyRef:(QredoKeyRef *)bulkKeyRef
                    authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef {
   return [[self alloc] initWithBulkKeyRef:bulkKeyRef
                      authenticationKeyRef:authenticationKeyRef];
}


-(instancetype)initWithBulkKeyRef:(QredoKeyRef *)bulkKeyRef
             authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef {
    self = [super init];
    if (self){
        _bulkKeyRef           = bulkKeyRef;
        _authenticationKeyRef = authenticationKeyRef;
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////
//QredoVaultCrypto Interface
///////////////////////////////////////////////////////////////////////////////

+(QredoKeyRef *)systemVaultKeyRefWithVaultMasterKeyRef:(QredoKeyRef *)vaultMasterKeyRef {
    return [self vaultKeyRefWithVaultMasterKeyRef:vaultMasterKeyRef info:QREDO_VAULT_SYSTEM_INFO];
}


+(QredoKeyRef *)userVaultKeyRefWithVaultMasterKeyRef:(QredoKeyRef *)vaultMasterKeyRef {
    return [self vaultKeyRefWithVaultMasterKeyRef:vaultMasterKeyRef info:QREDO_VAULT_USER_INFO];
}


+(QredoKeyRef *)vaultMasterKeyRefWithUserMasterKeyRef:(QredoKeyRef *)userMasterKeyRef {
    return [[QredoCryptoKeychain standardQredoCryptoKeychain] deriveKeyRef:userMasterKeyRef salt:QREDO_VAULT_MASTER_SALT info:[NSData data]];
}


+(QredoKeyRef *)vaultKeyRefWithVaultMasterKeyRef:(QredoKeyRef *)vaultMasterKeyRef infoData:(NSData *)infoData {
    return [[QredoCryptoKeychain standardQredoCryptoKeychain] deriveKeyRef:vaultMasterKeyRef salt:QREDO_VAULT_SUBTYPE_SALT info:infoData];
}


+(QredoKeyRef *)vaultKeyRefWithVaultMasterKeyRef:(QredoKeyRef *)vaultMasterKeyRef info:(NSString *)info {
    return [self vaultKeyRefWithVaultMasterKeyRef:vaultMasterKeyRef infoData:[info dataUsingEncoding:NSUTF8StringEncoding]];
}



+(QLFVaultKeyPair *)vaultKeyPairWithVaultKeyRef:(QredoKeyRef *)vaultKeyRef {
    
    QredoKeyRef *encryptionKeyRef       =  [[QredoCryptoKeychain standardQredoCryptoKeychain] deriveKeyRef:vaultKeyRef salt:QREDO_VAULT_LEAF_SALT info:[@"Encryption" dataUsingEncoding:NSUTF8StringEncoding]];
    QredoKeyRef *authenticationKeyRef   =  [[QredoCryptoKeychain standardQredoCryptoKeychain] deriveKeyRef:vaultKeyRef salt:QREDO_VAULT_LEAF_SALT info:[@"Authentication" dataUsingEncoding:NSUTF8StringEncoding]];
    return [[QredoCryptoKeychain standardQredoCryptoKeychain] vaultKeyPairWithEncryptionKey:encryptionKeyRef privateKeyRef:authenticationKeyRef];
}


-(NSData *)encryptMetadata:(QLFVaultItemMetadata *)metadata iv:(NSData*)iv{
    NSData *serializedMetadata = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:NO];
    return [self encryptIncludingMessageHeaderWithData:serializedMetadata iv:iv];
}


-(NSData *)encryptIncludingMessageHeaderWithData:(NSData *)data  iv:(NSData*)iv{
    if (!data)data = [NSData data];
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    NSData *encryptedMetadata = [keychain encryptBulk:self.bulkKeyRef plaintext:data iv:iv];
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
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    return [keychain authenticate:self.authenticationKeyRef data:authCodeData];
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
    
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    NSData *value = [keychain decryptBulk:self.bulkKeyRef ciphertext:encryptedBodyRaw];
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
    
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    NSData *decryptedHeaders = [keychain decryptBulk:self.bulkKeyRef ciphertext:encyrptedHeadersRaw];
    
    return [QredoPrimitiveMarshallers unmarshalObject:decryptedHeaders
                                         unmarshaller:[QLFVaultItemMetadata unmarshaller]
                                          parseHeader:NO];
}


-(NSData *)encryptVaultItemValue:(NSData *)data {
    if (!data)data = [NSData data];
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];

    return [keychain encryptBulk:self.bulkKeyRef plaintext:data];
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
