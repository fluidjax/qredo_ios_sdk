/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/




#import "QredoCryptoKeychain.h"
#import "QredoKey.h"
#import "Qredo.h"
#import "QredoBulkEncKey.h"
#import "QredoKeyRef.h"
#import "QredoKeyRefPair.h"
#import "UICKeyChainStore.h"
#import "QredoCryptoImplV1.h"
#import "QredoCryptoRaw.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"
#import "NSData+HexTools.h"
#import "QredoClient.h"
#import "QredoSigner.h"
#import "QLFOwnershipSignature+FactoryMethods.h"



@interface QredoCryptoKeychain()
//@property (strong) UICKeyChainStore *keychainWrapper;
@property (strong) QredoCryptoImplV1 *cryptoImplementation;
@property (strong) NSMutableDictionary *keyDictionary;
@end

@implementation QredoCryptoKeychain


#pragma Initialization

+(instancetype)standardQredoCryptoKeychain{
    static id standardQredoCryptoKeychainInstance = nil;
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        standardQredoCryptoKeychainInstance = [[self alloc] init];
    });
    return standardQredoCryptoKeychainInstance;
}


- (instancetype)init{
    self = [super init];
    if (self) {
        //_keychainWrapper = [UICKeyChainStore keyChainStoreWithService:@"Qredo.Crypto"];
        _cryptoImplementation = [QredoCryptoImplV1 sharedInstance];
        _keyDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma Encryption


-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext{
    QredoBulkEncKey *secretKey = [QredoBulkEncKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation encryptBulk:secretKey plaintext:plaintext];
}


-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext iv:(NSData*)iv{
    QredoBulkEncKey *secretKey = [QredoBulkEncKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation encryptBulk:secretKey plaintext:plaintext iv:iv];
}


-(NSData *)decryptBulk:(QredoKeyRef *)secretKeyRef  ciphertext:(NSData *)ciphertext{
    QredoBulkEncKey *secretKey = [QredoBulkEncKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation decryptBulk:secretKey ciphertext:ciphertext];
}


-(NSData *)authenticate:(QredoKeyRef *)secretKeyRef data:(NSData *)data{
    QredoKey *secretKey = [QredoKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation getAuthCodeWithKey:secretKey data:data];
}


-(BOOL)verify:(QredoKeyRef *)secretKeyRef data:(NSData *)data signature:(NSData *)signature{
    QredoKey *secretKey = [QredoKey keyWithData:[self retrieveWithRef:secretKeyRef]];
    return [self.cryptoImplementation verifyAuthCodeWithKey:secretKey data:data mac:signature];
}


#pragma User/Master Key Generation

-(QredoKeyRef *)deriveUserUnlockKeyRef:(NSData *)ikm{
    NSAssert(ikm,@"DeriveKey key should not be nil");
    QredoKey *derivedKey = [self.cryptoImplementation deriveSlow:ikm
                                                            salt:SALT_USER_UNLOCK
                                                      iterations:PBKDF2_USERUNLOCK_KEY_ITERATIONS];
    return [self createKeyRef:derivedKey];
}


-(QredoKeyRef *)deriveMasterKeyRef:(QredoKeyRef *)userUnlockKeyRef{
    
    NSData *ikm = [self retrieveWithRef:userUnlockKeyRef];
    NSAssert(ikm,@"DeriveKey key should not be nil");
    
    QredoKey *derivedKey = [self.cryptoImplementation deriveFast:ikm
                                                            salt:SALT_USER_MASTER
                                                            info:INFO_USER_MASTER
                                                    outputLength:MASTER_KEY_SIZE];
    return [self createKeyRef:derivedKey];
}



#pragma Key Derive/Generation


-(QredoKeyRef *)deriveKeyRef:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info{
    //derive_fast HKDF
    NSData *ikm = [self retrieveWithRef:keyRef];
    NSAssert(ikm,@"DeriveKey key should not be nil");
    NSAssert(salt,@"Salt should not be nil");
    QredoKey *derivedKey = [self.cryptoImplementation deriveFast:ikm salt:salt info:info outputLength:SHA256_DIGEST_SIZE];
    return [self createKeyRef:derivedKey];
}




-(QredoKeyRef *)derivePasswordKey:(NSData *)password salt:(NSData *)salt{
    //derive_slow PBKDF
    QredoKey *derivedKey = [self.cryptoImplementation deriveSlow:password  salt:salt iterations:10000];
    return [self createKeyRef:derivedKey];
}


-(QredoKeyRefPair *)generateDHKeyPair{
    QredoKeyPair *keyPair = [self.cryptoImplementation generateDHKeyPair];
    QredoKey *private = [QredoKey keyWithData:keyPair.privateKey.bytes];
    QredoKey *public  = [QredoKey keyWithData:keyPair.publicKey.bytes];
    QredoKeyRefPair *keyRefPair = [QredoKeyRefPair keyPairWithPublic:public private:private];
    return keyRefPair;
}


-(QredoKeyRefPair *)ownershipKeyPairDeriveRef:(QredoKeyRef *)ikmRef{
    //ed25519_sha512_derive
    NSData *ikm = [self retrieveWithRef:ikmRef];
    QredoED25519SigningKey *signKey = [self.cryptoImplementation qredoED25519SigningKeyWithSeed:ikm];
    QredoKey *private = [QredoKey keyWithData:signKey.data];
    QredoKey *public  = [QredoKey keyWithData:signKey.verifyKey.data];
    QredoKeyRefPair *keyRefPair =  [QredoKeyRefPair keyPairWithPublic:public private:private];
    return keyRefPair;
}


-(QredoQUID*)keyRefToQUID:(QredoKeyRef*)keyRef{
    NSData *keyData = [self retrieveWithRef:keyRef];
    return [QredoQUID QUIDWithData:keyData];
}


-(NSData*)publicKeyDataFor:(QredoKeyRefPair *)keyPair{
    //Return public key data in a KeyPair
    QredoKeyRef *publicKeyRef = keyPair.publicKeyRef;
    return [self retrieveWithRef:publicKeyRef];
}


-(NSString*)sha256FingerprintKeyRef:(QredoKeyRef*)keyRef{
    NSData *keyData = [self retrieveWithRef:keyRef];
    NSData *fp = [QredoCryptoRaw sha256:keyData];
    return [QredoUtils dataToHexString:fp];
}



-(QredoKeyRef *)generateDiffieHellmanMasterKeyWithMyPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef
                                                 yourPublicKeyRef:(QredoKeyRef *)yourPublicKeyRef{
    QredoKey *myPrivateKey = [QredoKey keyWithData:[self retrieveWithRef:myPrivateKeyRef]];
    QredoKey *yourPublicKey  = [QredoKey keyWithData:[self retrieveWithRef:yourPublicKeyRef]];
    QredoKey *diffieHellmanMaster = [self.cryptoImplementation generateDiffieHellmanMasterKeyWithMyPrivateKey:myPrivateKey
                                                                                                yourPublicKey:yourPublicKey];
    QredoKeyRef *keyRef = [self createKeyRef:diffieHellmanMaster];
    return keyRef;
}


-(NSData *)generateDiffieHellmanSecretWithSalt:(NSData *)salt
                                  myPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                 yourPublicKey:(QredoDhPublicKey *)yourPublicKey{
    NSData *diffieHellmanSecret = [self.cryptoImplementation generateDiffieHellmanSecretWithSalt:salt
                                                                                    myPrivateKey:myPrivateKey
                                                                                   yourPublicKey:yourPublicKey];
    return diffieHellmanSecret;
}


#pragma Qredo Lingua Franca

-(QredoED25519Signer *)qredoED25519SignerWithKeyRef:(QredoKeyRef*)keyref{
    NSData *keyData = [self retrieveWithRef:keyref];
    if (!keyData)return nil;
    QredoED25519SigningKey *key = [QredoED25519SigningKey keyWithData:keyData];
    return [[QredoED25519Signer alloc] initWithSigningKey:key];
}

-(QLFKeyPairLF *)newRequesterKeyPair {
    QredoKeyPair *keyPair = [self.cryptoImplementation generateDHKeyPair];
    QLFKeyLF *publicKeyLF  = [QLFKeyLF keyLFWithBytes:[(QredoDhPublicKey *)[keyPair publicKey]  data]];
    QLFKeyLF *privateKeyLF = [QLFKeyLF keyLFWithBytes:[(QredoDhPrivateKey *)[keyPair privateKey] data]];
    return [QLFKeyPairLF keyPairLFWithPubKey:publicKeyLF privKey:privateKeyLF];
}


-(QLFKeyPairLF *)keyPairLFWithPubKeyRef:(QredoKeyRef *)pubKeyRef privateKeyRef:(QredoKeyRef *)privateKeyRef{
    NSData *pubKeyData = [self retrieveWithRef:pubKeyRef];
    NSData *privKeyData = [self retrieveWithRef:privateKeyRef];
    return  [QLFKeyPairLF keyPairLFWithPubKey:[QLFKeyLF keyLFWithBytes:pubKeyData]
                                      privKey:[QLFKeyLF keyLFWithBytes:privKeyData]];
}


-(QLFVaultKeyPair *)vaultKeyPairWithEncryptionKey:(QredoKeyRef *)encryptionKeyRef privateKeyRef:(QredoKeyRef *)authenticationKeyRef{
    NSData *encData = [self retrieveWithRef:encryptionKeyRef];
    NSData *authData = [self retrieveWithRef:authenticationKeyRef];
    return  [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:encData authenticationKey:authData];
}


-(QLFRendezvousDescriptor *)rendezvousDescriptorWithTag:(NSString *)tag
                                              hashedTag:(QLFRendezvousHashedTag *)hashedTag
                                       conversationType:(NSString *)conversationType
                                     authenticationType:(QLFRendezvousAuthType *)authenticationType
                                        durationSeconds:(NSSet *)durationSeconds
                                              expiresAt:(NSSet *)expiresAt
                                     responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit
                                       requesterKeyPair:(QredoKeyRefPair *)requesterKeyPair
                                       ownershipKeyPair:(QredoKeyRefPair *)ownershipKeyPair{
    
    QLFKeyPairLF * requesterKeyPairQL = [self keyPairLFWithPubKeyRef:requesterKeyPair.publicKeyRef privateKeyRef:requesterKeyPair.privateKeyRef];
    QLFKeyPairLF * ownershipKeyPairQL = [self keyPairLFWithPubKeyRef:ownershipKeyPair.publicKeyRef privateKeyRef:ownershipKeyPair.privateKeyRef];
    
    return [QLFRendezvousDescriptor            rendezvousDescriptorWithTag:tag
                                                                 hashedTag:hashedTag
                                                          conversationType:conversationType
                                                        authenticationType:authenticationType
                                                           durationSeconds:durationSeconds
                                                                 expiresAt:expiresAt
                                                        responseCountLimit:responseCountLimit
                                                          requesterKeyPair:requesterKeyPairQL
                                                          ownershipKeyPair:ownershipKeyPairQL];
}


-(QLFConversationDescriptor *)conversationDescriptorWithRendezvousTag:(NSString *)rendezvousTag
                                                      rendezvousOwner:(BOOL)rendezvousOwner
                                                       conversationId:(QLFConversationId *)conversationId
                                                     conversationType:(NSString *)conversationType
                                                   authenticationType:(QLFRendezvousAuthType *)authenticationType
                                                       myPublicKeyRef:(QredoKeyRef *)myPublicKeyRef
                                                      myPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef
                                                     yourPublicKeyRef:(QredoKeyRef *)yourPublicKey
                                                  myPublicKeyVerified:(BOOL)myPublicKeyVerified
                                                yourPublicKeyVerified:(BOOL)yourPublicKeyVerified{
    
    QLFKeyPairLF *myKey = [self keyPairLFWithPubKeyRef:myPublicKeyRef privateKeyRef:myPrivateKeyRef];
    QLFKeyLF *publicLFKey = [QLFKeyLF keyLFWithBytes:[self retrieveWithRef:yourPublicKey]];
    
    QLFConversationDescriptor *descriptor =
    [QLFConversationDescriptor conversationDescriptorWithRendezvousTag:rendezvousTag
                                                       rendezvousOwner:rendezvousOwner                                                                            conversationId:conversationId
                                                      conversationType:conversationType
                                                    authenticationType:authenticationType
                                                                 myKey:myKey
                                                         yourPublicKey:publicLFKey
                                                   myPublicKeyVerified:myPublicKeyVerified
                                                 yourPublicKeyVerified:yourPublicKeyVerified];
    return descriptor;
}



#pragma Keychain

-(QredoKeyRef*)createKeyRef:(QredoKey*)key{
    if (![key data])return nil;
    return [QredoKeyRef keyRefWithKeyData:[key data]];
}


-(void)addItem:(NSData*)keyData forRef:(NSData*)ref{
    @synchronized (self) {
        if (![self.keyDictionary objectForKey:ref]){
            [self.keyDictionary setObject:keyData forKey:ref];
        }
    }
    //Alternative (1/2) to store in the iOS Keychain instead of dictionary (significantly slower)
    //[self.keychainWrapper setData:keyData forKey:[ref hexadecimalString]];
}
    
-(NSData*)retrieveWithRef:(QredoKeyRef*)ref{
    @synchronized (self) {
        return [self.keyDictionary objectForKey:ref.ref];
    }
    //Alternative (2/2) to retriebe from iOS Keychain instead of dictionary (significantly slower)
    //return [self.keychainWrapper dataForKey:[ref hexadecimalString]];
}




#pragma Keychain comparison (used in testing)

-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToKeyRef:(QredoKeyRef*)keyRef2{
    NSData *key1 = [self retrieveWithRef:keyRef1];
    NSData *key2 = [self retrieveWithRef:keyRef2];
    return [key1 isEqual:key2];
}


-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToData:(NSData*)data{
    NSData *key1 = [self retrieveWithRef:keyRef1];
    return [key1 isEqual:data];
}

@end

