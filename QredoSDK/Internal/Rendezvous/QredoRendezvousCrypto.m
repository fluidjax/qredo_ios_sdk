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
                                          authenticationType:(QredoRendezvousAuthType *)authType
                                            conversationType:(NSString *)conversationType
                                             durationSeconds:(NSSet *)durationSeconds
                                            maxResponseCount:(NSSet *)maxResponseCount
                                                    transCap:(NSSet *)transCap
                                          requesterPublicKey:(QredoRequesterPublicKey *)requesterPublicKey
                                      accessControlPublicKey:(QredoAccessControlPublicKey *)accessControlPublicKey
                                           authenticationKey:(QredoAuthenticationCode *)authenticationKey
{
    QredoRendezvousCreationInfo *creationInfo =
            [QredoRendezvousCreationInfo rendezvousCreationInfoWithHashedTag:hashedTag
                                                          authenticationType:authType
                                                            conversationType:conversationType
                                                             durationSeconds:durationSeconds
                                                            maxResponseCount:maxResponseCount
                                                                    transCap:transCap
                                                          requesterPublicKey:requesterPublicKey
                                                      accessControlPublicKey:accessControlPublicKey
                                                          authenticationCode:[NSMutableData dataWithLength:(256 / 8)]];

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

@end