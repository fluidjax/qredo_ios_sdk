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

- (QredoAuthenticationCode *)authenticationCodeWithRendezvousHelper:(id<QredoRendezvousHelper>)rendezvousHelper
                                                          hashedTag:(QredoRendezvousHashedTag *)hashedTag
                                                   conversationType:(NSString *)conversationType
                                                    durationSeconds:(NSSet *)durationSeconds
                                                   maxResponseCount:(NSSet *)maxResponseCount
                                                           transCap:(NSSet *)transCap
                                                 requesterPublicKey:(QredoRequesterPublicKey *)requesterPublicKey
                                             accessControlPublicKey:(QredoAccessControlPublicKey *)accessControlPublicKey
                                                  authenticationKey:(QredoAuthenticationCode *)authenticationKey
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
                                                          authenticationCode:[NSMutableData dataWithLength:32]];

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
    return [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyId];
}

- (SecKeyRef)accessControlPrivateKeyWithTag:(NSString*)tag
{
    NSString *privateKeyId = [tag stringByAppendingString:@".private"];
    return [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyId];
}


- (QredoKeyPairLF *)newAccessControlKeyPairWithId:(NSString*)keyId {
    NSString *publicKeyId = [keyId stringByAppendingString:@".public"];
    NSString *privateKeyId = [keyId stringByAppendingString:@".private"];
    
    /*BOOL success = */[QredoCrypto generateRsaKeyPairOfLength:2048
                        publicKeyIdentifier:publicKeyId
                       privateKeyIdentifier:privateKeyId persistInAppleKeychain:YES];
    // TODO: What should happen if keypair generation failed?
    
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


- (BOOL)validateCreationInfo:(QredoRendezvousCreationInfo *)creationInfo tag:(NSString *)tag
{
    QredoRendezvousAuthType *authType = creationInfo.authenticationType;
    id<QredoRendezvousHelper> rendezvousHelper = [self rendezvousHelperForAuthType:authType tag:tag];
    
    NSData *authKey = [self authKey:tag];
    
    NSData *authCode
    = [self
       authenticationCodeWithRendezvousHelper:rendezvousHelper
       hashedTag:creationInfo.hashedTag
       conversationType:creationInfo.conversationType
       durationSeconds:creationInfo.durationSeconds
       maxResponseCount:creationInfo.maxResponseCount
       transCap:creationInfo.transCap
       requesterPublicKey:creationInfo.requesterPublicKey
       accessControlPublicKey:creationInfo.accessControlPublicKey
       authenticationKey:authKey];
    
    BOOL ok1 = [QredoCrypto equalsConstantTime:authCode right:creationInfo.authenticationCode];
    
    __block BOOL ok2 = NO;
    [authType ifAnonymous:^{
        ok2 = YES;
    } ifTrustedWithSignature:^(QredoRendezvousAuthSignature *signature) {
        if (rendezvousHelper == nil) {
            ok2 = NO;
        } else {
            NSData *rendezvousData = creationInfo.authenticationCode;
            ok2 = [rendezvousHelper isValidSignature:signature rendezvousData:rendezvousData];
        }
    }];
    
    return ok1 && ok2;
}

- (id<QredoRendezvousHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType tag:(NSString *)tag
{
    return [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:authenticationType tag:tag];
}

- (id<QredoRendezvousHelper>)rendezvousHelperForAuthType:(QredoRendezvousAuthType *)authType tag:(NSString *)tag
{
    __block id<QredoRendezvousHelper> rendezvousHelper = nil;
    
    [authType ifAnonymous:^{
        rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous tag:tag];
    } ifTrustedWithSignature:^(QredoRendezvousAuthSignature *signature) {
        [signature ifX509_PEM:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem tag:tag];
        } X509_PEM_SELFISGNED:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509PemSelfsigned tag:tag];
        } ED25519:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519 tag:tag];
        } RSA2048_PEM:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem tag:tag];
        } RSA4096_PEM:^(NSData *signature) {
            rendezvousHelper = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem tag:tag];
        } other:^{
            rendezvousHelper = nil;
        }];
    }];
    
    return rendezvousHelper;
}



@end