#import <Foundation/Foundation.h>
#import "QredoSecKeyRefPair.h"

typedef NS_ENUM (uint8_t,QredoPadding) {
    QredoPaddingNone = 1,
    QredoPaddingOaep,
    QredoPaddingPkcs1
};


#define RSA_OAEP_MIN_PADDING_LENGTH  42
#define RSA_PKCS1_MIN_PADDING_LENGTH 11

@interface QredoCrypto :NSObject

+(NSData *)aes256CtrEncrypt:(NSData *)plaintext key:(NSData *)key iv:(NSData *)iv;
+(NSData *)aes256CtrDecrypt:(NSData *)ciphertext key:(NSData *)key iv:(NSData *)iv;
+(BOOL)constantEquals:(NSData *)lhs rhs:(NSData *)rhs;
+(NSData *)hkdfSha256Extract:(NSData *)ikm salt:(NSData *)salt;
+(NSData *)hkdfSha256Expand:(NSData *)key info:(NSData *)info outputLength:(NSUInteger)outputLength;
+(NSData *)pbkdf2Sha256:(NSData *)ikm salt:(NSData *)salt outputLen:(NSUInteger)outputLen iterations:(NSUInteger)iterations;
+(NSData *)secureRandom:(NSUInteger)size;

+(NSData *)generateHmacSha256ForData:(NSData *)data length:(NSUInteger)length key:(NSData *)key;
+(NSData *)sha256:(NSData *)data;

+(QredoSecKeyRefPair *)generateRsaKeyPairOfLength:(NSInteger)lengthBits publicKeyIdentifier:(NSString *)publicKeyIdentifier privateKeyIdentifier:(NSString *)privateKeyIdentifier persistInAppleKeychain:(BOOL)persistKeys;
+(NSData *)rsaPssSignMessage:(NSData *)message saltLength:(NSUInteger)saltLength keyRef:(SecKeyRef)keyRef;
+(SecKeyRef)getPublicKeyRefFromEvaluatedTrustRef:(SecTrustRef)trustRef;
+(SecKeyRef)getRsaSecKeyReferenceForIdentifier:(NSString *)keyIdentifier;
+(NSData *)getKeyDataForIdentifier:(NSString *)keyIdentifier;
OSStatus fixedSecItemCopyMatching(CFDictionaryRef query,CFTypeRef *result);




@end
