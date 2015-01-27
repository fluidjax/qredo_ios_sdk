#import "QredoRendezvousCrypto.h"
#import "QredoClientMarshallers.h"
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

- (QredoAuthenticationCode *)authenticationCodeWithHashedTag:(QredoRendezvousHashedTag *)hashedTag
                                            conversationType:(NSString *)conversationType
                                             durationSeconds:(NSSet *)durationSeconds
                                            maxResponseCount:(NSSet *)maxResponseCount
                                                    transCap:(NSSet *)transCap
                                          requesterPublicKey:(QredoRequesterPublicKey *)requesterPublicKey
                                      accessControlPublicKey:(QredoAccessControlPublicKey *)accessControlPublicKey
                                           authenticationKey:(QredoAuthenticationCode *)authenticationKey
                                            rendezvousHelper:(id<QredoRendezvousHelper>)rendezvousHelper
{
    
    QredoRendezvousAuthType *authType = nil;
    if ([rendezvousHelper type] == QredoRendezvousAuthenticationTypeAnonymous) {
        authType = [QredoRendezvousAuthType rendezvousAnonymous];
    } else {
        QredoRendezvousAuthSignature *authSignature = [rendezvousHelper emptySignature];
        authType = [QredoRendezvousAuthType rendezvousTrustedWithSignature:authSignature];
    }
    
    QredoRendezvousCreationInfo *creationInfo =
            [QredoRendezvousCreationInfo rendezvousCreationInfoWithHashedTag:hashedTag
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
                                          marshaller:[QredoClientMarshallers rendezvousCreationInfoMarshaller]];



    return [_crypto getAuthCodeWithKey:authenticationKey
                                  data:serializedCreationInfo];

}

- (QredoAuthenticationCode *)authKey:(NSString *)tag {
    NSData *hash = [_crypto getPasswordBasedKeyWithSalt:QREDO_RENDEZVOUS_AUTH_KEY password:tag];
    return hash;
}

- (QredoRendezvousHashedTag *)hashedTag:(NSString *)tag {
    QredoAuthenticationCode *authKey = [self authKey:tag];
    return [self hashedTagWithAuthKey:authKey];
}

- (QredoRendezvousHashedTag *)hashedTagWithAuthKey:(QredoAuthenticationCode *)authKey
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

- (QredoKeyPairLF *)newAccessControlKeyPairWithId:(NSString*)keyId {
    NSString *publicKeyId = [keyId stringByAppendingString:@".public"];
    NSString *privateKeyId = [keyId stringByAppendingString:@".private"];
    
    LogDebug(@"Attempting to generate keypair for identifiers: '%@' and '%@'", publicKeyId, privateKeyId);

    BOOL success = [QredoCrypto generateRsaKeyPairOfLength:2048
                                       publicKeyIdentifier:publicKeyId
                                      privateKeyIdentifier:privateKeyId persistInAppleKeychain:YES];
    if (!success) {
        // TODO: What should happen if keypair generation failed? More than just log it
        LogError(@"Failed to generate keypair for identifiers: '%@' and '%@'", publicKeyId, privateKeyId);
    }
    
    QredoRsaPublicKey *rsaPublicKey = [[QredoRsaPublicKey alloc] initWithPkcs1KeyData:[QredoCrypto getKeyDataForIdentifier:publicKeyId]];
    
    uint8_t *pubKeyBytes = (uint8_t*)(rsaPublicKey.modulus.bytes);
    // stripping the leading zero
    ++pubKeyBytes;
    
    
    NSData *publicKeyBytes  = [NSData dataWithBytes:pubKeyBytes length:256];
    
    NSData *privateKeyBytes = [QredoCrypto getKeyDataForIdentifier:privateKeyId];
    
    QredoKeyLF *publicKeyLF  = [QredoKeyLF keyLFWithBytes:publicKeyBytes];
    QredoKeyLF *privateKeyLF = [QredoKeyLF keyLFWithBytes:privateKeyBytes];

    return [QredoKeyPairLF keyPairLFWithPubKey:publicKeyLF
                                       privKey:privateKeyLF];
}

- (QredoKeyPairLF *)newRequesterKeyPair {
    QredoKeyPair *keyPair = [_crypto generateDHKeyPair];

    QredoKeyLF *publicKeyLF  = [QredoKeyLF keyLFWithBytes:[(QredoDhPublicKey*)[keyPair publicKey]  data]];
    QredoKeyLF *privateKeyLF = [QredoKeyLF keyLFWithBytes:[(QredoDhPrivateKey*)[keyPair privateKey] data]];

    return [QredoKeyPairLF keyPairLFWithPubKey:publicKeyLF
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

- (NSData *)signChallenge:(NSData*)challenge hashtag:(QredoRendezvousHashedTag*)hashtag nonce:(QredoNonce*)nonce privateKey:(QredoPrivateKey*)privateKey
{
    return nil;
}


- (BOOL)validateCreationInfo:(QredoRendezvousCreationInfo *)creationInfo tag:(NSString *)tag error:(NSError **)error
{
    QredoRendezvousAuthType *authType = creationInfo.authenticationType;
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
    [authType ifAnonymous:^{
        isValidSignature = YES;
    } ifTrustedWithSignature:^(QredoRendezvousAuthSignature *signature) {
        if (rendezvousHelper == nil) {
            isValidSignature = NO;
        } else {
            NSData *rendezvousData = creationInfo.authenticationCode;
            isValidSignature = [rendezvousHelper isValidSignature:signature rendezvousData:rendezvousData error:error];
        }
    }];
    
    return isValidAuthCode && isValidSignature;
}

- (id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType prefix:(NSString *)tag error:(NSError **)error
{
    return [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:authenticationType prefix:tag crypto:_crypto error:error];
}

- (id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthType:(QredoRendezvousAuthType *)authType fullTag:(NSString *)tag error:(NSError **)error
{
    __block id<QredoRendezvousRespondHelper> rendezvousHelper = nil;
    
    [authType ifAnonymous:^{
        rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous fullTag:tag crypto:_crypto error:error];
    } ifTrustedWithSignature:^(QredoRendezvousAuthSignature *signature) {
        [signature ifX509_PEM:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem fullTag:tag crypto:_crypto error:error];
        } X509_PEM_SELFISGNED:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509PemSelfsigned fullTag:tag crypto:_crypto error:error];
        } ED25519:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519 fullTag:tag crypto:_crypto error:error];
        } RSA2048_PEM:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem fullTag:tag crypto:_crypto error:error];
        } RSA4096_PEM:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem fullTag:tag crypto:_crypto error:error];
        } other:^{
            rendezvousHelper = nil;
        }];
    }];
    
    return rendezvousHelper;
}



@end