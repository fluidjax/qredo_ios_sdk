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
#import "QredoLogging.h"
#import "QredoAuthenticatedRendezvousTag.h"
#import "QredoErrorCodes.h"


#define QREDO_RENDEZVOUS_AUTH_KEY [@"Authenticate" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_SALT [@"Rendezvous" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_ID [@"ConversationID" dataUsingEncoding:NSUTF8StringEncoding]

#define QREDO_RENDEZVOUS_MASTER_KEY_SALT [@"8YhZWIxieGYyW07D" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_HASHED_TAG_SALT [@"tAMJb4bJd60ufzHS" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_ENC_SALT        [@"QoR0rwQOu3PMCieK" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_AUTH_SALT       [@"FZHoqke4BfkIOfkH" dataUsingEncoding:NSUTF8StringEncoding]

static const int QredoRendezvousMasterKeyLength = 32;

@implementation QredoRendezvousCrypto {
    id<CryptoImpl> _crypto;
}

+ (QredoRendezvousCrypto *)instance {
    static QredoRendezvousCrypto *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _crypto = [CryptoImplV1 new];
    }
    return self;
}

- (QLFAuthenticationCode *)authenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                         authenticationKey:(NSData *)authenticationKey
                                    encryptedResponderData:(NSData *)encryptedResponderData
{
    NSMutableData *payload = [NSMutableData dataWithData:[hashedTag data]];
    [payload appendData:encryptedResponderData];
    
    return [_crypto getAuthCodeWithKey:authenticationKey data:payload];
    }
    
- (QLFAuthenticationCode *)responderAuthenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                                  authenticationKey:(NSData *)authenticationKey
                                                 responderPublicKey:(NSData *)responderPublicKey
{
    NSMutableData *payload = [NSMutableData dataWithData:[hashedTag data]];
    [payload appendData:responderPublicKey];

    return [_crypto getAuthCodeWithKey:authenticationKey data:payload];
}

- (SecKeyRef)accessControlPublicKeyWithTag:(NSString*)tag
{
    NSString *publicKeyId = [tag stringByAppendingString:@".public"];

    SecKeyRef keyReference = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyId];
    if (!keyReference) {
        LogError(@"Nil SecKeyRef returned for public key ID: %@", publicKeyId);
    }
    
    return keyReference;
}

- (SecKeyRef)accessControlPrivateKeyWithTag:(NSString*)tag
{
    NSString *privateKeyId = [tag stringByAppendingString:@".private"];
    
    SecKeyRef keyReference = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyId];
    if (!keyReference) {
        LogError(@"Nil SecKeyRef returned for private key ID: '%@'", privateKeyId);
    }

    return keyReference;
}

- (QLFKeyPairLF *)newAccessControlKeyPairWithId:(NSString*)keyId {
    NSString *publicKeyId = [keyId stringByAppendingString:@".public"];
    NSString *privateKeyId = [keyId stringByAppendingString:@".private"];
    
    LogDebug(@"Attempting to generate keypair for identifiers: '%@' and '%@'", publicKeyId, privateKeyId);

    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:2048
                                                         publicKeyIdentifier:publicKeyId
                                                        privateKeyIdentifier:privateKeyId
                                                      persistInAppleKeychain:YES];
    if (!keyPairRef) {
        // TODO: What should happen if keypair generation failed? More than just log it
        LogError(@"Failed to generate keypair for identifiers: '%@' and '%@'", publicKeyId, privateKeyId);
    }
    
    QredoRsaPublicKey *rsaPublicKey = [[QredoRsaPublicKey alloc] initWithPkcs1KeyData:[QredoCrypto getKeyDataForIdentifier:publicKeyId]];
    
    uint8_t *pubKeyBytes = (uint8_t*)(rsaPublicKey.modulus.bytes);
    // stripping the leading zero
    ++pubKeyBytes;
    
    
    NSData *publicKeyBytes  = [NSData dataWithBytes:pubKeyBytes length:256];
    
    NSData *privateKeyBytes = [QredoCrypto getKeyDataForIdentifier:privateKeyId];
    
    QLFKeyLF *publicKeyLF  = [QLFKeyLF keyLFWithBytes:publicKeyBytes];
    QLFKeyLF *privateKeyLF = [QLFKeyLF keyLFWithBytes:privateKeyBytes];

    return [QLFKeyPairLF keyPairLFWithPubKey:publicKeyLF
                                     privKey:privateKeyLF];
}

- (QLFKeyPairLF *)newRequesterKeyPair {
    QredoKeyPair *keyPair = [_crypto generateDHKeyPair];

    QLFKeyLF *publicKeyLF  = [QLFKeyLF keyLFWithBytes:[(QredoDhPublicKey*)[keyPair publicKey]  data]];
    QLFKeyLF *privateKeyLF = [QLFKeyLF keyLFWithBytes:[(QredoDhPrivateKey*)[keyPair privateKey] data]];

    return [QLFKeyPairLF keyPairLFWithPubKey:publicKeyLF
                                       privKey:privateKeyLF];
}

- (QredoQUID *)hashWithKeyPair:(QredoKeyPair *)keyPair salt:(NSData *)salt {
    NSData *quidData = [_crypto getDiffieHellmanSecretWithSalt:salt
                                                 myPrivateKey:keyPair.privateKey
                                                yourPublicKey:keyPair.publicKey];
    
    return [[QredoQUID alloc] initWithQUIDData:quidData];
}

- (QredoQUID *)conversationIdWithKeyPair:(QredoKeyPair *)keyPair {
    return [self hashWithKeyPair:keyPair salt:SALT_CONVERSATION_ID];
}

- (NSData *)signChallenge:(NSData*)challenge hashtag:(QLFRendezvousHashedTag*)hashtag nonce:(QLFNonce*)nonce privateKey:(QredoPrivateKey*)privateKey
{
    return nil;
}


- (BOOL)validateEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo
                     authenticationKey:(NSData *)authenticationKey
                                   tag:(NSString *)tag
                             hashedTag:(QLFRendezvousHashedTag *)hashedTag
                       trustedRootPems:(NSArray *)trustedRootPems
                                 error:(NSError **)error
{
    QLFRendezvousAuthType *authenticationType = encryptedResponderInfo.authenticationType;
    QLFAuthenticationCode *authenticationCode = encryptedResponderInfo.authenticationCode;
    NSData *encryptedResponderData = encryptedResponderInfo.value;
    
    id<QredoRendezvousRespondHelper> rendezvousHelper = [self rendezvousHelperForAuthType:authenticationType
                                                                                  fullTag:tag
                                                                          trustedRootPems:trustedRootPems
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
    } ifRendezvousTrusted:^(QLFRendezvousAuthSignature *signature) {
        if (rendezvousHelper == nil) {
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

- (id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                 fullTag:(NSString *)tag
                                                         trustedRootPems:trustedRootPems
                                                          signingHandler:(signDataBlock)signingHandler
                                                                   error:(NSError **)error
{
    return [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:authenticationType
                                                                 fullTag:tag
                                                                  crypto:_crypto
                                                         trustedRootPems:trustedRootPems
                                                          signingHandler:signingHandler
                                                                   error:error];
}

- (id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthType:(QLFRendezvousAuthType *)authType
                                                        fullTag:(NSString *)tag
                                                trustedRootPems:(NSArray *)trustedRootPems
                                                          error:(NSError **)error
{
    __block id<QredoRendezvousRespondHelper> rendezvousHelper = nil;

    [authType ifRendezvousAnonymous:^{
        rendezvousHelper
        = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                                fullTag:tag
                                                                 crypto:_crypto
                                                        trustedRootPems:trustedRootPems
                                                                  error:error];

    } ifRendezvousTrusted:^(QLFRendezvousAuthSignature *signature) {
        [signature ifRendezvousAuthX509_PEM:^(NSData *signature) {
            rendezvousHelper
            = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                                    fullTag:tag
                                                                     crypto:_crypto
                                                            trustedRootPems:trustedRootPems
                                                                      error:error];

        } ifRendezvousAuthX509_PEM_SELFSIGNED:^(NSData *signature) {
            rendezvousHelper
            = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509PemSelfsigned
                                                                    fullTag:tag
                                                                     crypto:_crypto
                                                            trustedRootPems:trustedRootPems
                                                                      error:error];

        } ifRendezvousAuthED25519:^(NSData *signature) {
            rendezvousHelper
            = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                                    fullTag:tag
                                                                     crypto:_crypto
                                                            trustedRootPems:trustedRootPems
                                                                      error:error];

        } ifRendezvousAuthRSA2048_PEM:^(NSData *signature) {
            rendezvousHelper
            = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
                                                                    fullTag:tag
                                                                     crypto:_crypto
                                                            trustedRootPems:trustedRootPems
                                                                      error:error];

        } ifRendezvousAuthRSA4096_PEM:^(NSData *signature) {
            rendezvousHelper
            = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                                    fullTag:tag
                                                                     crypto:_crypto
                                                            trustedRootPems:trustedRootPems
                                                                      error:error];

        }];
    }];
    
    return rendezvousHelper;
}

- (NSData *)masterKeyWithTag:(NSString *)tag
{
    NSData *tagData = [tag dataUsingEncoding:NSUTF8StringEncoding];
    if ([QredoAuthenticatedRendezvousTag isAuthenticatedTag:tag]) {
        return [QredoCrypto hkdfSha256WithSalt:QREDO_RENDEZVOUS_MASTER_KEY_SALT
                            initialKeyMaterial:tagData
                                          info:nil];
    }

    return [QredoCrypto pbkdf2Sha256WithSalt:QREDO_RENDEZVOUS_MASTER_KEY_SALT
                       bypassSaltLengthCheck:NO
                                passwordData:tagData
                      requiredKeyLengthBytes:32
                                  iterations:10000];

}

- (QLFRendezvousHashedTag *)hashedTagWithMasterKey:(NSData *)masterKey
{
    NSAssert(masterKey, @"Master key should not be nil");
    NSAssert(masterKey.length == QredoRendezvousMasterKeyLength, @"Wrong length of master key");

    NSData *hashedTagData = [QredoCrypto hkdfSha256WithSalt:QREDO_RENDEZVOUS_HASHED_TAG_SALT
                                         initialKeyMaterial:masterKey
                                                       info:nil];

    return [[QredoQUID alloc] initWithQUIDData:hashedTagData];
}

- (NSData *)encryptionKeyWithMasterKey:(NSData *)masterKey
{
    NSAssert(masterKey, @"Master key should not be nil");
    NSAssert(masterKey.length == QredoRendezvousMasterKeyLength, @"Wrong length of master key");

    return [QredoCrypto hkdfSha256WithSalt:QREDO_RENDEZVOUS_ENC_SALT initialKeyMaterial:masterKey info:nil];
}

- (NSData *)authenticationKeyWithMasterKey:(NSData *)masterKey
{
    NSAssert(masterKey, @"Master key should not be nil");
    NSAssert(masterKey.length == QredoRendezvousMasterKeyLength, @"Wrong length of master key");
    
    return [QredoCrypto hkdfSha256WithSalt:QREDO_RENDEZVOUS_AUTH_SALT initialKeyMaterial:masterKey info:nil];
}

- (QLFRendezvousResponderInfo *)decryptResponderInfoWithData:(NSData *)encryptedResponderData
                                               encryptionKey:(NSData *)encryptionKey
                                                       error:(NSError **)error
{
    const int ivLength = 16;
    if (encryptedResponderData.length < ivLength) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:@{
                                                NSLocalizedDescriptionKey: @"Invalid responder data"
                                                }];
            return nil;
        }
    }
    NSData *iv = [NSData dataWithBytes:encryptedResponderData.bytes length:ivLength];
    NSData *encryptedData = [NSData dataWithBytes:(encryptedResponderData.bytes + ivLength)
                                           length:encryptedResponderData.length - ivLength];

    NSData *decryptedData = [QredoCrypto decryptData:encryptedData withAesKey:encryptionKey iv:iv];

    if (!decryptedData) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:@{
                                                NSLocalizedDescriptionKey: @"Failed to decrypt responder info"
                                                }];
        }
        return nil;
    }

    @try {
        QLFRendezvousResponderInfo *responderInfo =
        [QredoPrimitiveMarshallers unmarshalObject:decryptedData
                                      unmarshaller:[QLFRendezvousResponderInfo unmarshaller]];
        return responderInfo;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:@{
                                                NSLocalizedDescriptionKey: @"Failed to unmarshal decrypted data"
                                                }];
        }

        return nil;
    }
}

- (NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                   encryptionKey:(NSData *)encryptionKey
{
    NSData *iv = [NSData dataWithRandomBytesOfLength:16];
    return [self encryptResponderInfo:responderInfo encryptionKey:encryptionKey iv:iv];
}

- (NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                   encryptionKey:(NSData *)encryptionKey
                              iv:(NSData *)iv
{

    NSData *serializedResponderInfo = [QredoPrimitiveMarshallers marshalObject:responderInfo];

    NSData *encryptedResponderInfo = [QredoCrypto encryptData:serializedResponderInfo
                                                   withAesKey:encryptionKey
                                                           iv:iv];

    NSMutableData *encryptedResponderInfoWithIV = [NSMutableData dataWithData:iv];
    [encryptedResponderInfoWithIV appendData:encryptedResponderInfo];
    
    return [encryptedResponderInfoWithIV copy];
}

@end