/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoSecKeyRefPair.h"

typedef NS_ENUM (uint8_t,QredoPadding) {
    QredoPaddingNotSet = 0,
    QredoPaddingNone,
    QredoPaddingOaep,
    QredoPaddingPkcs1
};


#define RSA_OAEP_MIN_PADDING_LENGTH  42
#define RSA_PKCS1_MIN_PADDING_LENGTH 11

@interface QredoCrypto :NSObject

+(NSData *)decryptData:(NSData *)data with256bitAesKey:(NSData *)key iv:(NSData *)iv;
+(NSData *)encryptData:(NSData *)data with256bitAesKey:(NSData *)key iv:(NSData *)iv;
+(NSData *)hkdfExtractSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm;
+(NSData *)hkdfExpandSha256WithKey:(NSData *)key info:(NSData *)info outputLength:(NSUInteger)outputLength;
+(NSData *)hkdfSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm info:(NSData *)info;
+(NSData *)hkdfSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm info:(NSData *)info outputLength:(NSUInteger)outputLength;
+(NSData *)pbkdf2Sha256WithSalt:(NSData *)salt passwordData:(NSData *)passwordData requiredKeyLengthBytes:(NSUInteger)requiredKeyLengthBytes iterations:(NSUInteger)iterations;
+(NSData *)generateHmacSha256ForData:(NSData *)data length:(NSUInteger)length key:(NSData *)key;
+(NSData *)sha256:(NSData *)data;
+(NSData *)secureRandomWithSize:(NSUInteger)size;
+(BOOL)equalsConstantTime:(NSData *)left right:(NSData *)right;

+(QredoSecKeyRefPair *)generateRsaKeyPairOfLength:(NSInteger)lengthBits publicKeyIdentifier:(NSString *)publicKeyIdentifier privateKeyIdentifier:(NSString *)privateKeyIdentifier persistInAppleKeychain:(BOOL)persistKeys;
+(NSData *)rsaPssSignMessage:(NSData *)message saltLength:(NSUInteger)saltLength keyRef:(SecKeyRef)keyRef;
+(SecKeyRef)getPublicKeyRefFromEvaluatedTrustRef:(SecTrustRef)trustRef;
+(SecKeyRef)getRsaSecKeyReferenceForIdentifier:(NSString *)keyIdentifier;
+(NSData *)getKeyDataForIdentifier:(NSString *)keyIdentifier;
OSStatus fixedSecItemCopyMatching(CFDictionaryRef query,CFTypeRef *result);




@end
