/* HEADER GOES HERE */
#import "QredoRendezvousCrypto.h"
#import "QredoKeyPair.h"
#import "CryptoImplV1.h"
#import "NSData+QredoRandomData.h"
#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"
#import "QredoCrypto.h"
#import "QredoRsaPublicKey.h"
#import "QredoRsaPrivateKey.h"
#import "QredoRendezvousHelpers.h"
#import "QredoLoggerPrivate.h"
#import "QredoAuthenticatedRendezvousTag.h"
#import "QredoErrorCodes.h"
#import "QredoQUIDPrivate.h"

#define QREDO_RENDEZVOUS_AUTH_KEY        [@"Authenticate" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_SALT            [@"Rendezvous" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_ID             [@"ConversationID" dataUsingEncoding:NSUTF8StringEncoding]

#define QREDO_RENDEZVOUS_MASTER_KEY_SALT [@"8YhZWIxieGYyW07D" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_HASHED_TAG_SALT [@"tAMJb4bJd60ufzHS" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_ENC_SALT        [@"QoR0rwQOu3PMCieK" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_AUTH_SALT       [@"FZHoqke4BfkIOfkH" dataUsingEncoding:NSUTF8StringEncoding]

static const int QredoRendezvousMasterKeyLength = 32;

@implementation QredoRendezvousCrypto {
    id<CryptoImpl> _crypto;
}

+(QredoRendezvousCrypto *)instance {
    static QredoRendezvousCrypto *_instance = nil;
    
    @synchronized(self) {
        if (_instance == nil){
            _instance = [[self alloc] init];
        }
    }
    
    return _instance;
}


-(id)init {
    self = [super init];
    
    if (self){
        _crypto = [CryptoImplV1 new];
    }
    
    return self;
}


-(QLFAuthenticationCode *)authenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                        authenticationKey:(NSData *)authenticationKey
                                   encryptedResponderData:(NSData *)encryptedResponderData {
    NSMutableData *payload = [NSMutableData dataWithData:[hashedTag data]];
    
    [payload appendData:encryptedResponderData];
    
    return [_crypto getAuthCodeWithKey:authenticationKey data:payload];
}


-(QLFAuthenticationCode *)responderAuthenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                                 authenticationKey:(NSData *)authenticationKey
                                                responderPublicKey:(NSData *)responderPublicKey {
    NSMutableData *payload = [NSMutableData dataWithData:[hashedTag data]];
    
    [payload appendData:responderPublicKey];
    
    return [_crypto getAuthCodeWithKey:authenticationKey data:payload];
}


-(SecKeyRef)accessControlPublicKeyWithTag:(NSString *)tag {
    NSString *publicKeyId = [tag stringByAppendingString:@".public"];
    
    SecKeyRef keyReference = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyId];
    
    return keyReference;
}


+(NSData *)transformPublicKeyToData:(SecKeyRef)key {
    NSString *const keychainTag = @"X509_KEY";
    NSData *publicKeyData;
    OSStatus putResult,delResult = noErr;
    
    //Params for putting the key first
    NSMutableDictionary *putKeyParams = [NSMutableDictionary new];
    
    putKeyParams[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    putKeyParams[(__bridge id)kSecAttrApplicationTag] = keychainTag;
    putKeyParams[(__bridge id)kSecValueRef] = (__bridge id)(key);
    putKeyParams[(__bridge id)kSecReturnData] = (__bridge id)(kCFBooleanTrue);   //Request the key's data to be returned too
    
    //Params for deleting the data
    NSMutableDictionary *delKeyParams = [[NSMutableDictionary alloc] init];
    delKeyParams[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    delKeyParams[(__bridge id)kSecAttrApplicationTag] = keychainTag;
    delKeyParams[(__bridge id)kSecReturnData] = (__bridge id)(kCFBooleanTrue);
    
    //Put the key
    putResult = SecItemAdd((__bridge CFDictionaryRef)putKeyParams,(void *)&publicKeyData);
    //Delete the key
    delResult = SecItemDelete((__bridge CFDictionaryRef)(delKeyParams));
    
    if ((putResult != errSecSuccess) || (delResult != errSecSuccess)){
        publicKeyData = nil;
    }
    
    return publicKeyData;
}


+(NSData *)transformPrivateKeyToData:(SecKeyRef)key {
    NSString *const keychainTag = @"TESTPRIVATEKEY";
    NSData *privateKeyData;
    OSStatus putResult,delResult = noErr;
    
    //Params for putting the key first
    NSMutableDictionary *putKeyParams = [NSMutableDictionary new];
    
    putKeyParams[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    putKeyParams[(__bridge id)kSecAttrApplicationTag] = keychainTag;
    putKeyParams[(__bridge id)kSecValueRef] = (__bridge id)(key);
    putKeyParams[(__bridge id)kSecReturnData] = (__bridge id)(kCFBooleanTrue);   //Request the key's data to be returned too
    
    //Params for deleting the data
    NSMutableDictionary *delKeyParams = [[NSMutableDictionary alloc] init];
    delKeyParams[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    delKeyParams[(__bridge id)kSecAttrApplicationTag] = keychainTag;
    delKeyParams[(__bridge id)kSecReturnData] = (__bridge id)(kCFBooleanTrue);
    
    //Put the key
    putResult = SecItemAdd((__bridge CFDictionaryRef)putKeyParams,(void *)&privateKeyData);
    //Delete the key
    delResult = SecItemDelete((__bridge CFDictionaryRef)(delKeyParams));
    
    if ((putResult != errSecSuccess) || (delResult != errSecSuccess)){
        privateKeyData = nil;
    }
    
    return privateKeyData;
}


-(SecKeyRef)accessControlPrivateKeyWithTag:(NSString *)tag {
    NSString *privateKeyId = [tag stringByAppendingString:@".private"];
    
    SecKeyRef keyReference = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyId];
    
    return keyReference;
}


-(QLFKeyPairLF *)newAccessControlKeyPairWithId:(NSString *)keyId {
    NSString *publicKeyId = [keyId stringByAppendingString:@".public"];
    NSString *privateKeyId = [keyId stringByAppendingString:@".private"];
    
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:2048
                                                         publicKeyIdentifier:publicKeyId
                                                        privateKeyIdentifier:privateKeyId
                                                      persistInAppleKeychain:YES];
    
    if (!keyPairRef){
        //TODO: What should happen if keypair generation failed? More than just log it
        QredoLogError(@"Failed to generate keypair for identifiers: '%@' and '%@'",publicKeyId,privateKeyId);
    }
    
    QredoRsaPublicKey *rsaPublicKey = [[QredoRsaPublicKey alloc] initWithPkcs1KeyData:[QredoCrypto getKeyDataForIdentifier:publicKeyId]];
    
    uint8_t *pubKeyBytes = (uint8_t *)(rsaPublicKey.modulus.bytes);
    //stripping the leading zero
    ++pubKeyBytes;
    
    
    NSData *publicKeyBytes  = [NSData dataWithBytes:pubKeyBytes length:256];
    
    NSData *privateKeyBytes = [QredoCrypto getKeyDataForIdentifier:privateKeyId];
    
    QLFKeyLF *publicKeyLF  = [QLFKeyLF keyLFWithBytes:publicKeyBytes];
    QLFKeyLF *privateKeyLF = [QLFKeyLF keyLFWithBytes:privateKeyBytes];
    
    return [QLFKeyPairLF keyPairLFWithPubKey:publicKeyLF
                                     privKey:privateKeyLF];
}


-(QLFKeyPairLF *)newRequesterKeyPair {
    QredoKeyPair *keyPair = [_crypto generateDHKeyPair];
    
    QLFKeyLF *publicKeyLF  = [QLFKeyLF keyLFWithBytes:[(QredoDhPublicKey *)[keyPair publicKey]  data]];
    QLFKeyLF *privateKeyLF = [QLFKeyLF keyLFWithBytes:[(QredoDhPrivateKey *)[keyPair privateKey] data]];
    
    return [QLFKeyPairLF keyPairLFWithPubKey:publicKeyLF
                                     privKey:privateKeyLF];
}


-(QredoQUID *)hashWithKeyPair:(QredoKeyPair *)keyPair salt:(NSData *)salt {
    NSData *quidData = [_crypto getDiffieHellmanSecretWithSalt:salt
                                                  myPrivateKey:keyPair.privateKey
                                                 yourPublicKey:keyPair.publicKey];
    
    return [[QredoQUID alloc] initWithQUIDData:quidData];
}


-(QredoQUID *)conversationIdWithKeyPair:(QredoKeyPair *)keyPair {
    return [self hashWithKeyPair:keyPair salt:SALT_CONVERSATION_ID];
}


-(NSData *)signChallenge:(NSData *)challenge hashtag:(QLFRendezvousHashedTag *)hashtag nonce:(QLFNonce *)nonce privateKey:(QredoPrivateKey *)privateKey {
    return nil;
}


-(BOOL)validateEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo
                    authenticationKey:(NSData *)authenticationKey
                                  tag:(NSString *)tag
                            hashedTag:(QLFRendezvousHashedTag *)hashedTag
                      trustedRootPems:(NSArray *)trustedRootPems
                              crlPems:(NSArray *)crlPems
                                error:(NSError **)error {
    QLFRendezvousAuthType *authenticationType = encryptedResponderInfo.authenticationType;
    QLFAuthenticationCode *authenticationCode = encryptedResponderInfo.authenticationCode;
    NSData *encryptedResponderData = encryptedResponderInfo.value;
    
    id<QredoRendezvousRespondHelper> rendezvousHelper = [self rendezvousHelperForAuthType:authenticationType
                                                                                  fullTag:tag
                                                                          trustedRootPems:trustedRootPems
                                                                                  crlPems:crlPems
                                                                                    error:error];
    
    NSData *calculatedAuthenticationCode
    = [self authenticationCodeWithHashedTag:hashedTag
                          authenticationKey:authenticationKey
                     encryptedResponderData:encryptedResponderData];
    
    BOOL isValidAuthCode = [QredoCrypto equalsConstantTime:calculatedAuthenticationCode
                                                     right:authenticationCode];
    
    __block BOOL isValidSignature = NO;
    [authenticationType ifRendezvousAnonymous:^{
        isValidSignature = YES;
    }
                          ifRendezvousTrusted:^(QLFRendezvousAuthSignature *signature) {
                              if (rendezvousHelper == nil){
                                  isValidSignature = NO;
                              } else {
                                  NSData *rendezvousData = authenticationCode;
                                  isValidSignature = [rendezvousHelper isValidSignature:signature
                                                                         rendezvousData:rendezvousData
                                                                                  error:error];
                              }
                          }];
    
    return isValidAuthCode && isValidSignature;
}


-(id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                fullTag:(NSString *)tag
                                                        trustedRootPems:(NSArray *)trustedRootPems
                                                                crlPems:(NSArray *)crlPems
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error {
    return [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:authenticationType
                                                                 fullTag:tag
                                                                  crypto:_crypto
                                                         trustedRootPems:trustedRootPems
                                                                 crlPems:crlPems
                                                          signingHandler:signingHandler
                                                                   error:error];
}


-(id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthType:(QLFRendezvousAuthType *)authType
                                                       fullTag:(NSString *)tag
                                               trustedRootPems:(NSArray *)trustedRootPems
                                                       crlPems:(NSArray *)crlPems
                                                         error:(NSError **)error {
    __block id<QredoRendezvousRespondHelper> rendezvousHelper = nil;
    
    
    if (authType == QredoRendezvousAuthenticationTypeAnonymous){
        rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                                                 fullTag:tag
                                                                                  crypto:_crypto
                                                                         trustedRootPems:trustedRootPems
                                                                                 crlPems:crlPems
                                                                                   error:error];
    }
    
    return rendezvousHelper;
}


-(NSData *)masterKeyWithTag:(NSString *)tag appId:(NSString *)appId {
    NSAssert(appId,@"AppID should not be nil");
    NSString *compositeTag = [NSString stringWithFormat:@"%@%@",appId,tag];
    
    NSData *tagData = [compositeTag dataUsingEncoding:NSUTF8StringEncoding];
    
    if ([QredoAuthenticatedRendezvousTag isAuthenticatedTag:tag]){
        return [QredoCrypto hkdfSha256WithSalt:QREDO_RENDEZVOUS_MASTER_KEY_SALT
                            initialKeyMaterial:tagData
                                          info:nil];
    }
    
    return [QredoCrypto pbkdf2Sha256WithSalt:QREDO_RENDEZVOUS_MASTER_KEY_SALT
                                passwordData:tagData
                      requiredKeyLengthBytes:32
                                  iterations:10000];
}


-(QLFRendezvousHashedTag *)hashedTagWithMasterKey:(NSData *)masterKey {
    NSAssert(masterKey,@"Master key should not be nil");
    NSAssert(masterKey.length == QredoRendezvousMasterKeyLength,@"Wrong length of master key");
    
    NSData *hashedTagData = [QredoCrypto hkdfSha256WithSalt:QREDO_RENDEZVOUS_HASHED_TAG_SALT
                                         initialKeyMaterial:masterKey
                                                       info:nil];
    
    return [[QredoQUID alloc] initWithQUIDData:hashedTagData];
}


-(NSData *)encryptionKeyWithMasterKey:(NSData *)masterKey {
    NSAssert(masterKey,@"Master key should not be nil");
    NSAssert(masterKey.length == QredoRendezvousMasterKeyLength,@"Wrong length of master key");
    
    return [QredoCrypto hkdfSha256WithSalt:QREDO_RENDEZVOUS_ENC_SALT initialKeyMaterial:masterKey info:nil];
}


-(NSData *)authenticationKeyWithMasterKey:(NSData *)masterKey {
    NSAssert(masterKey,@"Master key should not be nil");
    NSAssert(masterKey.length == QredoRendezvousMasterKeyLength,@"Wrong length of master key");
    
    return [QredoCrypto hkdfSha256WithSalt:QREDO_RENDEZVOUS_AUTH_SALT initialKeyMaterial:masterKey info:nil];
}


-(QLFRendezvousResponderInfo *)decryptResponderInfoWithData:(NSData *)encryptedResponderData
                                              encryptionKey:(NSData *)encryptionKey
                                                      error:(NSError **)error {
    NSData *decryptedData;
    
    @try {
        NSData *encryptedResponderDataRaw
        = [QredoPrimitiveMarshallers unmarshalObject:encryptedResponderData
                                        unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                         parseHeader:YES];
        
        decryptedData = [[CryptoImplV1 sharedInstance] decryptWithKey:encryptionKey
                                                                 data:encryptedResponderDataRaw];
    } @catch (NSException *exception){
        QredoLogError(@"Failed to decode: %@",exception);
    }
    
    if (!decryptedData){
        if (error){
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:@{
                                                NSLocalizedDescriptionKey:@"Failed to decrypt responder info"
                                                }];
        }
        
        return nil;
    }
    
    @try {
        QLFRendezvousResponderInfo *responderInfo =
        [QredoPrimitiveMarshallers unmarshalObject:decryptedData
                                      unmarshaller:[QLFRendezvousResponderInfo unmarshaller]
                                       parseHeader:NO];
        return responderInfo;
    } @catch (NSException *exception){
        if (error){
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:@{
                                                NSLocalizedDescriptionKey:@"Failed to unmarshal decrypted data"
                                                }];
        }
        
        return nil;
    }
}


-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKey:(NSData *)encryptionKey {
    NSData *iv = [QredoCrypto secureRandomWithSize:16];
    
    return [self encryptResponderInfo:responderInfo encryptionKey:encryptionKey iv:iv];
}


-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKey:(NSData *)encryptionKey
                             iv:(NSData *)iv {
    NSData *serializedResponderInfo = [QredoPrimitiveMarshallers marshalObject:responderInfo includeHeader:NO];
    
    NSData *encryptedResponderInfo =
    [[CryptoImplV1 sharedInstance] encryptWithKey:encryptionKey data:serializedResponderInfo iv:iv];
    
    return [QredoPrimitiveMarshallers marshalObject:encryptedResponderInfo
                                         marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]
                                      includeHeader:YES];
}


@end
