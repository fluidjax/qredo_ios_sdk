/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoSecKeyRefPair.h"

typedef NS_ENUM(uint8_t, QredoPadding) {
    QredoPaddingNotSet = 0,
    QredoPaddingNone,
    QredoPaddingOaep,
    QredoPaddingPkcs1
};

@interface QredoCrypto : NSObject

+ (NSData *)decryptData:(NSData *)data withAesKey:(NSData *)key iv:(NSData *)iv;
+ (NSData *)encryptData:(NSData *)data withAesKey:(NSData *)key iv:(NSData *)iv;
+ (NSData *)hkdfExtractSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm;
+ (NSData *)hkdfExpandSha256WithKey:(NSData *)key info:(NSData *)info outputLength:(NSUInteger)outputLength;
+ (NSData *)hkdfSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm info:(NSData *)info;
+ (NSData *)hkdfSha256WithSalt:(NSData *)salt initialKeyMaterial:(NSData *)ikm info:(NSData *)info outputLength:(NSUInteger)outputLength;
+ (NSData *)pbkdf2Sha256WithSalt:(NSData *)salt bypassSaltLengthCheck:(BOOL)bypassSaltLengthCheck passwordData:(NSData *)passwordData requiredKeyLengthBytes:(NSUInteger)requiredKeyLengthBytes iterations:(NSUInteger)iterations;
+ (NSData *)generateHmacSha256ForData:(NSData *)data length:(NSUInteger)length key:(NSData *)key;
+ (NSData *)sha256:(NSData *)data;
+ (NSData *)secureRandomWithSize:(NSUInteger)size;
+ (BOOL)equalsConstantTime:(NSData *)left right:(NSData *)right;

+ (SecKeyRef)importPkcs1KeyData:(NSData*)keyData keyLengthBits:(NSUInteger)keyLengthBits keyIdentifier:(NSString*)keyIdentifier isPrivate:(BOOL)isPrivate;
+ (QredoSecKeyRefPair *)generateRsaKeyPairOfLength:(NSInteger)lengthBits publicKeyIdentifier:(NSString*)publicKeyIdentifier privateKeyIdentifier:(NSString*)privateKeyIdentifier persistInAppleKeychain:(BOOL)persistKeys;
+ (SecCertificateRef)getCertificateRefFromIdentityRef:(SecIdentityRef)identityRef;
+ (SecKeyRef)getPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef;
+ (SecKeyRef)getPublicKeyRefFromIdentityRef:(SecIdentityRef)identityRef;
+ (SecKeyRef)getPublicKeyRefFromEvaluatedTrustRef:(SecTrustRef)trustRef;
+ (SecKeyRef)getRsaSecKeyReferenceForIdentifier:(NSString*)keyIdentifier;
+ (NSData*)getKeyDataForIdentifier:(NSString*)keyIdentifier;

+ (NSData *)rsaEncryptPlainTextData:(NSData*)plainTextData padding:(QredoPadding)padding keyRef:(SecKeyRef)keyRef;
+ (NSData *)rsaDecryptCipherTextData:(NSData*)cipherTextData padding:(QredoPadding)padding keyRef:(SecKeyRef)keyRef;

+ (NSData *)rsaPssSignMessage:(NSData*)message saltLength:(NSUInteger)saltLength keyRef:(SecKeyRef)keyRef;
+ (BOOL)rsaPssVerifySignature:(NSData*)signature forMessage:(NSData*)message saltLength:(NSUInteger)saltLength keyRef:(SecKeyRef)keyRef;

+ (BOOL)deleteAllKeysInAppleKeychain;
+ (BOOL)deleteKeyInAppleKeychainWithIdentifier:(NSString*)keyIdentifier;

OSStatus fixedSecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result);

@end
