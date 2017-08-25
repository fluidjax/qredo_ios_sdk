//
//  QredoCryptoKeychain.h
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//  Within General Qredo Code, only Key Refrences are passed, the actual mapping of *All* Refs->KeyData takes place here
//  Actually raw Key data is only used within the Crypto Sub Group of source files (QredoCryptoImpl, QredoRawCrypto)


@class QredoKey;
@class QredoKeyRef;
@class QredoKeyRefPair;
@class QredoQUID;
@class QredoDhPrivateKey;
@class QredoDhPublicKey;
@class QLFKeyPairLF;
@class QLFVaultKeyPair;
@class QredoED25519Singer;

#import <Foundation/Foundation.h>
#import "QredoClient.h"

@interface QredoCryptoKeychain : NSObject

+(instancetype)sharedQredoCryptoKeychain;
-(QredoKeyRef*)createKeyRef:(QredoKey*)key;
-(NSData*)retrieveWithRef:(QredoKeyRef *)ref;
-(void)addItem:(NSData*)keyData forRef:(NSData*)ref;
-(NSData*)publicKeyDataFor:(QredoKeyRefPair *)keyPair;
-(QLFKeyPairLF *)keyPairLFWithPubKeyRef:(QredoKeyRef *)pubKeyRef privateKeyRef:(QredoKeyRef *)privateKeyRef;
-(NSString*)sha256FingerPrintKeyRef:(QredoKeyRef*)keyRef;

-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext;
-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext iv:(NSData*)iv;
-(NSData *)decryptBulk:(QredoKeyRef *)secretKeyRef  ciphertext:(NSData *)ciphertext;
-(NSData *)authenticate:(QredoKeyRef *)secretKeyRef data:(NSData *)data;
-(BOOL)verify:(QredoKeyRef *)secretKeyRef data:(NSData *)data signature:(NSData *)signature;

-(QredoKeyRef *)deriveKeyRef:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info;
-(NSData *)deriveKey:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info;
    
-(QredoKeyRef *)derivePasswordKey:(NSData *)password salt:(NSData *)salt;
-(QredoKeyRefPair *)derivePasswordKeyPair:(NSData *)password salt:(NSData *)salt;
-(QredoKeyRefPair *)ownershipKeyPairDeriveRef:(QredoKeyRef *)ikmRef;

-(QredoQUID*)keyRefToQUID:(QredoKeyRef*)keyRef;
-(QLFKeyPairLF *)newRequesterKeyPair;
-(QLFVaultKeyPair *)vaultKeyPairWithEncryptionKey:(QredoKeyRef *)encryptionKeyRef privateKeyRef:(QredoKeyRef *)authenticationKeyRef;
    
    
-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToKeyRef:(QredoKeyRef*)keyRef2;
-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToData:(NSData*)data;


-(QredoKeyRefPair *)generateDHKeyPair;
-(QredoKeyRef *)getDiffieHellmanMasterKeyWithMyPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef
                                            yourPublicKeyRef:(QredoKeyRef *)yourPublicKey;

-(NSData *)getDiffieHellmanSecretWithSalt:(NSData *)salt
                             myPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                            yourPublicKey:(QredoDhPublicKey *)yourPublicKey;


-(QredoED25519Singer *)qredoED25519SingerWithKeyRef:(QredoKeyRef*)keyref;


-(QLFRendezvousDescriptor *)rendezvousDescriptorWithTag:(NSString *)tag
                                              hashedTag:(QLFRendezvousHashedTag *)hashedTag
                                       conversationType:(NSString *)conversationType
                                     authenticationType:(QLFRendezvousAuthType *)authenticationType
                                        durationSeconds:(NSSet *)durationSeconds
                                              expiresAt:(NSSet *)expiresAt
                                     responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit
                                       requesterKeyPair:(QredoKeyRefPair *)requesterKeyPair
                                       ownershipKeyPair:(QredoKeyRefPair *)ownershipKeyPair;


-(QLFConversationDescriptor *)conversationDescriptorWithRendezvousTag:(NSString *)rendezvousTag
                                                      rendezvousOwner:(BOOL)rendezvousOwner
                                                       conversationId:(QLFConversationId *)conversationId
                                                     conversationType:(NSString *)conversationType
                                                   authenticationType:(QLFRendezvousAuthType *)authenticationType
                                                       myPublicKeyRef:(QredoKeyRef *)myPublicKeyRef
                                                      myPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef
                                                     yourPublicKeyRef:(QredoKeyRef *)yourPublicKey
                                                  myPublicKeyVerified:(BOOL)myPublicKeyVerified
                                                yourPublicKeyVerified:(BOOL)yourPublicKeyVerified;


@end
