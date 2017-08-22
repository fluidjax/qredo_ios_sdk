//
//  QredoCryptoKeychain.h
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//  Within General Qredo Code, only Key Refrences are passed, the actual mapping of Refs->KeyData takes place here
//

@class QredoKey;
@class QredoKeyRef;
@class QredoKeyRefPair;
@class QredoQUID;
@class QredoDhPrivateKey;
@class QredoDhPublicKey;
@class QLFKeyPairLF;
@class QredoED25519Singer;

#import <Foundation/Foundation.h>


@interface QredoCryptoKeychain : NSObject

+(instancetype)sharedQredoCryptoKeychain;
-(QredoKeyRef*)createKeyRef:(QredoKey*)key;
//-(NSData*)makeRefForData:(NSData*)keydata;
-(NSData*)retrieveWithRef:(QredoKeyRef *)ref;
-(void)addItem:(NSData*)keyData forRef:(NSData*)ref;
-(NSData*)publicKeyDataFor:(QredoKeyRefPair *)keyPair;

//-(QredoKeyRef*)makeKeyRef;
//-(void)store:(QredoKey *)data withRef:(QredoKeyRef *)ref;




-(QLFKeyPairLF *)keyPairLFWithPubKeyRef:(QredoKeyRef *)pubKeyRef privateKeyRef:(QredoKeyRef *)privateKeyRef;


-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext;
-(NSData *)encryptBulk:(QredoKeyRef *)secretKeyRef plaintext:(NSData *)plaintext iv:(NSData*)iv;
-(NSData *)decryptBulk:(QredoKeyRef *)secretKeyRef  ciphertext:(NSData *)ciphertext;
-(NSData *)authenticate:(QredoKeyRef *)secretKeyRef data:(NSData *)data;
-(BOOL)verify:(QredoKeyRef *)secretKeyRef data:(NSData *)data signature:(NSData *)signature;
-(QredoKeyRef *)deriveKeyRef:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info;
-(NSData *)deriveKey:(QredoKeyRef *)keyRef salt:(NSData *)salt info:(NSData *)info;
    
-(QredoKeyRef *)derivePasswordKey:(NSData *)password salt:(NSData *)salt;
-(QredoKeyRefPair *)derivePasswordKeyPair:(NSData *)password salt:(NSData *)salt;
-(QredoKeyRefPair *)ownershipKeyPairDerive:(NSData *)ikm;
-(NSData *)ownershipSign:(QredoKeyRefPair *)keyPairRef data:(NSData *)data;

-(QredoQUID*)keyRefToQUID:(QredoKeyRef*)keyRef;


-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToKeyRef:(QredoKeyRef*)keyRef2;
-(BOOL)keyRef:(QredoKeyRef*)keyRef1 isEqualToData:(NSData*)data;


-(QredoKeyRefPair *)generateDHKeyPair;
-(QredoKeyRef *)getDiffieHellmanMasterKeyWithMyPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef
                                            yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

-(NSData *)getDiffieHellmanSecretWithSalt:(NSData *)salt
                             myPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                            yourPublicKey:(QredoDhPublicKey *)yourPublicKey;


-(QredoED25519Singer *)qredoED25519SingerWithKeyRef:(QredoKeyRef*)keyref;


@end
