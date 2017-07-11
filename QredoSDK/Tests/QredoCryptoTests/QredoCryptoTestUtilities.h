//
//  QredoCryptoTestUtilities.h
//  QredoSDK
//
//  Created by Christopher Morris on 11/07/2017.
//
//  Functionality stripped from QredoCrypto which is now no longer used in SDK, but kept here
//  So tests still run and code can be re-instate if required

#import <Foundation/Foundation.h>

#import "QredoCrypto.h"

@interface QredoCryptoTestUtilities : NSObject


+(BOOL)deleteKeyInAppleKeychainWithIdentifier:(NSString *)keyIdentifier;
+(SecKeyRef)importPkcs1KeyData:(NSData *)keyData keyLengthBits:(NSUInteger)keyLengthBits keyIdentifier:(NSString *)keyIdentifier isPrivate:(BOOL)isPrivate;
+(BOOL)deleteAllKeysInAppleKeychain;
+(BOOL)rsaPssVerifySignature:(NSData *)signature forMessage:(NSData *)message saltLength:(NSUInteger)saltLength keyRef:(SecKeyRef)keyRef;


+(SecCertificateRef)getCertificateRefFromIdentityRef:(SecIdentityRef)identityRef;
+(SecKeyRef)getPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef;
+(SecKeyRef)getPublicKeyRefFromIdentityRef:(SecIdentityRef)identityRef;
+(NSData *)rsaEncryptPlainTextData:(NSData *)plainTextData padding:(QredoPadding)padding keyRef:(SecKeyRef)keyRef;
+(NSData *)rsaDecryptCipherTextData:(NSData *)cipherTextData padding:(QredoPadding)padding keyRef:(SecKeyRef)keyRef;


@end
