#import <Foundation/Foundation.h>
#import "QredoKeyPair.h"

typedef NS_ENUM (uint8_t,QredoPadding) {
    QredoPaddingNone = 1,
    QredoPaddingOaep,
    QredoPaddingPkcs1
};


#define RSA_OAEP_MIN_PADDING_LENGTH  42
#define RSA_PKCS1_MIN_PADDING_LENGTH 11
#define kCCBlockSizeAES256 kCCBlockSizeAES128

@interface QredoRawCrypto : NSObject

NS_ASSUME_NONNULL_BEGIN

+(NSData *)aes256CtrEncrypt:(NSData *)plaintext key:(NSData *)key iv:(NSData *)iv;
+(NSData *)aes256CtrDecrypt:(NSData *)ciphertext key:(NSData *)key iv:(NSData *)iv;
+(BOOL)constantEquals:(NSData *)lhs rhs:(NSData *)rhs;
+(QredoKeyPair *)ed25519Derive:(NSData *)seed;
+(QredoKeyPair *)ed25519DeriveFromSecretKey:(NSData *)secretKey;
+(NSData *)ed25519Sha512Sign:(NSData *)payload keyPair:(QredoKeyPair *)keyPair;
+(BOOL)ed25519Sha512Verify:(NSData *)payload signature:(NSData *)signature keyPair:(QredoKeyPair *)keyPair;
+(NSData *)hmacSha256:(NSData *)data key:(NSData *)key outputLen:(NSUInteger)outputLen;
+(NSData *)hkdfSha256Extract:(NSData *)ikm salt:(NSData *)salt;
+(NSData *)hkdfSha256Expand:(NSData *)key info:(NSData *)info outputLength:(NSUInteger)outputLength;
+(NSData *)pbkdf2Sha256:(NSData *)ikm salt:(NSData *)salt outputLength:(NSUInteger)outputLength iterations:(NSUInteger)iterations;
+(NSData *)secureRandom:(NSUInteger)size;
+(NSData *)sha256:(NSData *)data;
+(NSData*)randomNonceAndZeroCounter;
OSStatus fixedSecItemCopyMatching(CFDictionaryRef query, CFTypeRef _Nonnull * _Nonnull  result);
@end


NS_ASSUME_NONNULL_END
