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

#define QREDO_RENDEZVOUS_AUTH_KEY [@"Authenticate" dataUsingEncoding:NSUTF8StringEncoding]
#define QREDO_RENDEZVOUS_SALT [@"Rendezvous" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_ID [@"ConversationID" dataUsingEncoding:NSUTF8StringEncoding]

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
                                            conversationType:(NSString *)conversationType
                                             durationSeconds:(NSSet *)durationSeconds
                                            maxResponseCount:(NSSet *)maxResponseCount
                                                    transCap:(NSSet *)transCap
                                          requesterPublicKey:(QLFRequesterPublicKey *)requesterPublicKey
                                      accessControlPublicKey:(QLFAccessControlPublicKey *)accessControlPublicKey
                                           authenticationKey:(QLFAuthenticationCode *)authenticationKey
                                            rendezvousHelper:(id<QredoRendezvousHelper>)rendezvousHelper
{
    
    QLFRendezvousAuthType *authType = nil;
    if ([rendezvousHelper type] == QredoRendezvousAuthenticationTypeAnonymous) {
        authType = [QLFRendezvousAuthType rendezvousAnonymous];
    } else {
        QLFRendezvousAuthSignature *authSignature = [rendezvousHelper emptySignature];
        authType = [QLFRendezvousAuthType rendezvousTrustedWithSignature:authSignature];
    }
    
    QLFRendezvousCreationInfo *creationInfo =
    [QLFRendezvousCreationInfo rendezvousCreationInfoWithHashedTag:hashedTag
                                                authenticationType:authType
                                                  conversationType:conversationType
                                                   durationSeconds:durationSeconds
                                                  maxResponseCount:maxResponseCount
                                                          transCap:transCap
                                                requesterPublicKey:requesterPublicKey
                                            accessControlPublicKey:accessControlPublicKey
                                                authenticationCode:[_crypto getAuthCodeZero]];

    NSData *serializedCreationInfo =
            [QredoPrimitiveMarshallers marshalObject:creationInfo
                                          marshaller:[QLFRendezvousCreationInfo marshaller]];



    return [_crypto getAuthCodeWithKey:authenticationKey
                                  data:serializedCreationInfo];

}

- (QLFAuthenticationCode *)authKey:(NSString *)tag {
    NSData *hash = [_crypto getPasswordBasedKeyWithSalt:QREDO_RENDEZVOUS_AUTH_KEY password:tag];
    return hash;
}

- (QLFRendezvousHashedTag *)hashedTag:(NSString *)tag {
    QLFAuthenticationCode *authKey = [self authKey:tag];
    return [self hashedTagWithAuthKey:authKey];
}

- (QLFRendezvousHashedTag *)hashedTagWithAuthKey:(QLFAuthenticationCode *)authKey
{
    NSMutableData *data = [NSMutableData dataWithData:QREDO_RENDEZVOUS_SALT];
    [data appendData:authKey];
    return [QredoQUID QUIDByHashingData:data];
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


- (BOOL)validateCreationInfo:(QLFRendezvousCreationInfo *)creationInfo tag:(NSString *)tag error:(NSError **)error
{
    QLFRendezvousAuthType *authType = creationInfo.authenticationType;
    id<QredoRendezvousRespondHelper> rendezvousHelper = [self rendezvousHelperForAuthType:authType fullTag:tag error:error];
    
    NSData *authKey = [self authKey:tag];
    
    NSData *authCode
    = [self authenticationCodeWithHashedTag:creationInfo.hashedTag
                           conversationType:creationInfo.conversationType
                            durationSeconds:creationInfo.durationSeconds
                           maxResponseCount:creationInfo.maxResponseCount
                                   transCap:creationInfo.transCap
                         requesterPublicKey:creationInfo.requesterPublicKey
                     accessControlPublicKey:creationInfo.accessControlPublicKey
                          authenticationKey:authKey
                           rendezvousHelper:rendezvousHelper];
    
    BOOL isValidAuthCode = [QredoCrypto equalsConstantTime:authCode right:creationInfo.authenticationCode];
    
    __block BOOL isValidSignature = NO;
    [authType ifRendezvousAnonymous:^{
        isValidSignature = YES;
    } ifRendezvousTrusted:^(QLFRendezvousAuthSignature *signature) {
        if (rendezvousHelper == nil) {
            isValidSignature = NO;
        } else {
            NSData *rendezvousData = creationInfo.authenticationCode;
            isValidSignature = [rendezvousHelper isValidSignature:signature rendezvousData:rendezvousData error:error];
        }
    }];

    return isValidAuthCode && isValidSignature;
}

- (id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType fullTag:(NSString *)tag signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    return [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:authenticationType fullTag:tag crypto:_crypto signingHandler:signingHandler error:error];
}

- (id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthType:(QLFRendezvousAuthType *)authType fullTag:(NSString *)tag error:(NSError **)error
{
    __block id<QredoRendezvousRespondHelper> rendezvousHelper = nil;

    [authType ifRendezvousAnonymous:^{
        rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous fullTag:tag crypto:_crypto error:error];

    } ifRendezvousTrusted:^(QLFRendezvousAuthSignature *signature) {
        [signature ifRendezvousAuthX509_PEM:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem fullTag:tag crypto:_crypto error:error];

        } ifRendezvousAuthX509_PEM_SELFSIGNED:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509PemSelfsigned fullTag:tag crypto:_crypto error:error];

        } ifRendezvousAuthED25519:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519 fullTag:tag crypto:_crypto error:error];

        } ifRendezvousAuthRSA2048_PEM:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem fullTag:tag crypto:_crypto error:error];

        } ifRendezvousAuthRSA4096_PEM:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem fullTag:tag crypto:_crypto error:error];

        }];
    }];
    
    return rendezvousHelper;
}



@end