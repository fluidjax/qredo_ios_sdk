/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoKeyPair.h"
#import "QredoED25519VerifyKey.h"
#import "QredoED25519SigningKey.h"
#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"
#import "QredoBulkEncKey.h"


@protocol QredoCryptoImpl


-(NSData *)encryptBulk:(QredoBulkEncKey *)secretKey  plaintext:(NSData *)plaintext;
-(NSData *)encryptBulk:(QredoBulkEncKey *)secretKey  plaintext:(NSData *)plaintext iv:(NSData *)iv;
-(NSData *)decryptBulk:(QredoBulkEncKey *)secretKey  ciphertext:(NSData *)ciphertext;

-(QredoKey *)deriveSlow:(NSData *)ikm salt:(NSData *)data iterations:(int)iterations;
-(QredoKey *)deriveFast:(NSData *)ikm salt:(NSData *)salt info:(NSData *)info outputLength:(int)length;


-(NSData *)getAuthCodeWithKey:(QredoKey *)authKey data:(NSData *)data;
-(NSData *)getAuthCodeWithKey:(QredoKey *)authKey data:(NSData *)data length:(NSUInteger)length;
-(NSData *)getAuthCodeZero;

//TODO: this function extracta appended authCode from `data`, however, in the new approach authCode is stored
//in a separate fields. The only dependency on the "old" approach of appending authCode is in the KeyStore.
//Once KeyStore is reviewed, this method should be gone
-(BOOL)verifyAuthCodeWithKey:(QredoKey *)authKey data:(NSData *)data;
-(BOOL)verifyAuthCodeWithKey:(QredoKey *)authKey data:(NSData *)data mac:(NSData *)mac;
-(QredoKey *)generateRandomKey;
-(NSData *)generatePasswordBasedKeyWithSalt:(NSData *)salt password:(NSString *)password;

-(QredoKey *)generateDiffieHellmanMasterKeyWithMyPrivateKey:(QredoKey *)myPrivateKey
                                         yourPublicKey:(QredoKey *)yourPublicKey;

-(NSData *)generateDiffieHellmanSecretWithSalt:(NSData *)salt
                             myPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                            yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

-(QredoKeyPair *)generateDHKeyPair;

-(NSData *)qredoED25519SignMessage:(NSData *)message withKey:(QredoED25519SigningKey *)sk error:(NSError **)error;
-(QredoED25519SigningKey *)qredoED25519SigningKeyWithSeed:(NSData *)seed;



@end
