#import <CommonCrypto/CommonDigest.h>
#import "QredoRendezvousCrypto.h"
#import "CryptoImplV1.h"
#import "QredoRawCrypto.h"
#import "QredoRendezvousHelpers.h"
#import "QredoLoggerPrivate.h"
#import "QredoErrorCodes.h"

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




-(QLFKeyPairLF *)newECAccessControlKeyPairWithSeed:(NSData *)seed {
    QredoED25519SigningKey *signKey = [[CryptoImplV1 sharedInstance] qredoED25519SigningKeyWithSeed:seed];
    QredoPublicKey  *pubKey     = signKey.verifyKey;
    QredoPrivateKey *privKey    = signKey;
    QLFKeyLF *publicKeyLF  = [QLFKeyLF keyLFWithBytes:[pubKey serialize]];
    QLFKeyLF *privateKeyLF = [QLFKeyLF keyLFWithBytes:[privKey serialize]];
    return [QLFKeyPairLF keyPairLFWithPubKey:publicKeyLF  privKey:privateKeyLF];
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
                                                  myPrivateKey:(QredoDhPrivateKey *)keyPair.privateKey
                                                 yourPublicKey:(QredoDhPublicKey *)keyPair.publicKey];
    
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
                                error:(NSError **)error {
    QLFRendezvousAuthType *authenticationType = encryptedResponderInfo.authenticationType;
    QLFAuthenticationCode *authenticationCode = encryptedResponderInfo.authenticationCode;
    NSData *encryptedResponderData = encryptedResponderInfo.value;
    
    id<QredoRendezvousRespondHelper> rendezvousHelper = [self rendezvousHelperForAuthType:authenticationType
                                                                                  fullTag:tag
                                                                                    error:error];
    
    NSData *calculatedAuthenticationCode
    = [self authenticationCodeWithHashedTag:hashedTag
                          authenticationKey:authenticationKey
                     encryptedResponderData:encryptedResponderData];
    
    BOOL isValidAuthCode = [QredoRawCrypto constantEquals:calculatedAuthenticationCode rhs:authenticationCode];
    
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
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error {
    return [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:authenticationType
                                                                 fullTag:tag
                                                                  crypto:_crypto
                                                          signingHandler:signingHandler
                                                                   error:error];
}


-(id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthType:(QLFRendezvousAuthType *)authType
                                                       fullTag:(NSString *)tag
                                                         error:(NSError **)error {
    __block id<QredoRendezvousRespondHelper> rendezvousHelper = nil;
    
    
    if (authType == QredoRendezvousAuthenticationTypeAnonymous){
        rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                                                 fullTag:tag
                                                                                  crypto:_crypto
                                                                                   error:error];
    }
    
    return rendezvousHelper;
}


-(NSData *)masterKeyWithTag:(NSString *)tag appId:(NSString *)appId {
    NSAssert(appId,@"AppID should not be nil");
    NSString *compositeTag = [NSString stringWithFormat:@"%@%@",appId,tag];
    NSData *tagData = [compositeTag dataUsingEncoding:NSUTF8StringEncoding];

    return [QredoRawCrypto pbkdf2Sha256:tagData salt:QREDO_RENDEZVOUS_MASTER_KEY_SALT outputLength:32 iterations:10000];
}


-(QLFRendezvousHashedTag *)hashedTagWithMasterKey:(NSData *)masterKey {
    NSAssert(masterKey,@"Master key should not be nil");
    NSAssert(masterKey.length == QredoRendezvousMasterKeyLength,@"Wrong length of master key");

    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:QREDO_RENDEZVOUS_HASHED_TAG_SALT];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    NSData *hashedTagData = okm;
    
    return [[QredoQUID alloc] initWithQUIDData:hashedTagData];
}


-(NSData *)encryptionKeyWithMasterKey:(NSData *)masterKey {
    NSAssert(masterKey,@"Master key should not be nil");
    NSAssert(masterKey.length == QredoRendezvousMasterKeyLength,@"Wrong length of master key");

    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:QREDO_RENDEZVOUS_ENC_SALT];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


-(NSData *)authenticationKeyWithMasterKey:(NSData *)masterKey {
    NSAssert(masterKey,@"Master key should not be nil");
    NSAssert(masterKey.length == QredoRendezvousMasterKeyLength,@"Wrong length of master key");

    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:QREDO_RENDEZVOUS_AUTH_SALT];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
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
    NSData *iv = [QredoRawCrypto randomNonceAndZeroCounter];
    
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
