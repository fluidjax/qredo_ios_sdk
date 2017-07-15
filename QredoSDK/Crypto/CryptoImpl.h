/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoKeyPair.h"
#import "QredoED25519VerifyKey.h"
#import "QredoED25519SigningKey.h"
#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"


static NSString *const QredoCryptoImplErrorDomain = @"QredoCryptoImplErrorDomain";

typedef NS_ENUM (NSUInteger,QredoCryptoImplError) {
    QredoCryptoImplErrorMalformedData = 1,
    QredoCryptoImplErrorMalformedKeyData,
    QredoCryptoImplErrorMalformedSignatureData,
};


@protocol CryptoImpl



-(NSData *)encryptWithKey:(NSData *)secretKey data:(NSData *)data;
-(NSData *)encryptWithKey:(NSData *)secretKey data:(NSData *)data iv:(NSData *)iv;
-(NSData *)decryptWithKey:(NSData *)secretKey data:(NSData *)data;
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

-(QredoED25519SigningKey *)qredoED25519SigningKeyWithSeed:(NSData *)seed;
-(QredoED25519VerifyKey *)qredoED25519VerifyKeyWithData:(NSData *)data error:(NSError **)error;

-(NSData *)qredoED25519SignMessage:(NSData *)message withKey:(QredoED25519SigningKey *)sk error:(NSError **)error;

@end
