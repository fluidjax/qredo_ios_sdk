/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoKeyPair.h"
#import "QredoED25519VerifyKey.h"
#import "QredoED25519SigningKey.h"
#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"
#import "QredoAESKey.h"


@protocol QredoCryptoImpl


-(NSData *)encryptBulk:(QredoAESKey *)secretKey  plaintext:(NSData *)plaintext;
-(NSData *)encryptBulk:(QredoAESKey *)secretKey  plaintext:(NSData *)plaintext iv:(NSData *)iv;
-(NSData *)decryptBulk:(QredoAESKey *)secretKey  ciphertext:(NSData *)ciphertext;

-(NSData *)getAuthCodeWithKey:(NSData *)authKey data:(NSData *)data;
-(NSData *)getAuthCodeWithKey:(NSData *)authKey data:(NSData *)data length:(NSUInteger)length;
-(NSData *)getAuthCodeZero;

//TODO: this function extracta appended authCode from `data`, however, in the new approach authCode is stored
//in a separate fields. The only dependency on the "old" approach of appending authCode is in the KeyStore.
//Once KeyStore is reviewed, this method should be gone
-(BOOL)verifyAuthCodeWithKey:(NSData *)authKey data:(NSData *)data;
-(BOOL)verifyAuthCodeWithKey:(NSData *)authKey data:(NSData *)data mac:(NSData *)mac;
-(NSData *)getRandomKey;
-(NSData *)getPasswordBasedKeyWithSalt:(NSData *)salt password:(NSString *)password;

-(NSData *)getDiffieHellmanMasterKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                       yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

-(NSData *)getDiffieHellmanSecretWithSalt:(NSData *)salt
                             myPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                            yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

-(QredoKeyPair *)generateDHKeyPair;

-(NSData *)qredoED25519SignMessage:(NSData *)message withKey:(QredoED25519SigningKey *)sk error:(NSError **)error;
-(QredoED25519SigningKey *)qredoED25519SigningKeyWithSeed:(NSData *)seed;


//-(NSData *)encryptBulk:(QredoKey *)secretKey  plaintext:(NSData *)plaintext;
//-(NSData *)decryptBulk:(QredoKey *)secretKey  ciphertext:(NSData *)ciphertext;
//-(NSData *)authenticate:(QredoKey *)secretKey data:(NSData *)data;
//-(NSData *)verify:(QredoKey *)secretKey data:(NSData *)data signature:(NSData *)signature;
//-(QredoKey *)deriveSlow:(NSData *)ikm salt:(NSData *)data;
//-(QredoKey *)deriveFast:(NSData *)ikm salt:(NSData *)salt info:(NSData *)info;
//-(QredoKeyPair *)ownershipKeyPairDerive:(NSData *)ikm;
//-(NSData *)ownershipSign:(QredoKeyPair *)keyPair data:(NSData *)data;
//-(NSData *)legacyHash:(NSData *)data;
//-(QredoKeyPair *)legacyOwnershipKeyPairGenerate;
//-(NSData *)legacyOwnershipSign:(QredoKeyPair *)keyPair data:(NSData *)data;


@end
