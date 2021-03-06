/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/



//  Within General Qredo Code, only Key References are passed, the actual mapping of *All* Refs->KeyData takes place here
//  Actually raw Key data is only used within the Crypto Sub Group of source files (QredoCryptoImpl, QredoCryptoRaw)


@class QredoKey;
@class QredoKeyRef;
@class QredoKeyRefPair;
@class QredoQUID;
@class QredoDhPrivateKey;
@class QredoDhPublicKey;
@class QLFKeyPairLF;
@class QLFVaultKeyPair;
@class QredoED25519Signer;

#import <Foundation/Foundation.h>
#import "QredoClient.h"

@interface QredoCryptoKeychain : NSObject

#pragma Initialization
+(instancetype)standardQredoCryptoKeychain;


#pragma Encryption
-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext;
-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext iv:(NSData*)iv;
-(NSData *)decryptBulk:(QredoKeyRef *)secretKeyRef  ciphertext:(NSData *)ciphertext;
-(NSData *)authenticate:(QredoKeyRef *)secretKeyRef data:(NSData *)data;
-(BOOL)verify:(QredoKeyRef *)secretKeyRef data:(NSData *)data signature:(NSData *)signature;


#pragma Key Derive/Generation
-(QredoKeyRef *)deriveKeyRef:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info;
-(QredoKeyRef *)derivePasswordKey:(NSData *)password salt:(NSData *)salt;

-(QredoKeyRefPair *)generateDHKeyPair;
-(QredoKeyRefPair *)ownershipKeyPairDeriveRef:(QredoKeyRef *)ikmRef;
-(QredoQUID*)keyRefToQUID:(QredoKeyRef*)keyRef;
-(NSData*)publicKeyDataFor:(QredoKeyRefPair *)keyPair;
-(NSString*)sha256FingerprintKeyRef:(QredoKeyRef*)keyRef;
-(QredoKeyRef *)generateDiffieHellmanMasterKeyWithMyPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef yourPublicKeyRef:(QredoKeyRef *)yourPublicKey;
-(NSData *)generateDiffieHellmanSecretWithSalt:(NSData *)salt myPrivateKey:(QredoDhPrivateKey *)myPrivateKey yourPublicKey:(QredoDhPublicKey *)yourPublicKey;


#pragma User/Master Key Generation
-(QredoKeyRef *)deriveUserUnlockKeyRef:(NSData *)ikm;
-(QredoKeyRef *)deriveMasterKeyRef:(QredoKeyRef *)userUnlockKeyRef;


#pragma Qredo Lingua Franca
-(QredoED25519Signer *)qredoED25519SignerWithKeyRef:(QredoKeyRef*)keyref;
-(QLFKeyPairLF *)newRequesterKeyPair;
-(QLFKeyPairLF *)keyPairLFWithPubKeyRef:(QredoKeyRef *)pubKeyRef privateKeyRef:(QredoKeyRef *)privateKeyRef;
-(QLFVaultKeyPair *)vaultKeyPairWithEncryptionKey:(QredoKeyRef *)encryptionKeyRef privateKeyRef:(QredoKeyRef *)authenticationKeyRef;
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


#pragma Keychain
-(QredoKeyRef*)createKeyRef:(QredoKey*)key;
-(void)addItem:(NSData*)keyData forRef:(NSData*)ref;
-(NSData*)retrieveWithRef:(QredoKeyRef *)ref;


#pragma Keychain comparison (used in testing)
-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToKeyRef:(QredoKeyRef*)keyRef2;
-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToData:(NSData*)data;









@end
