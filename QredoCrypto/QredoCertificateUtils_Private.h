/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoCertificateUtils.h"

@interface QredoCertificateUtils (Private)

+ (SecCertificateRef)createCertificateWithPemCertificate:(NSString *)pemCertificate;
+ (SecCertificateRef)createCertificateWithDerData:(NSData *)certificateData;
+ (NSString *)convertCertificateRefToPemCertificate:(SecCertificateRef)certificateRef;
+ (NSData *)convertPemWrappedStringToDer:(NSString *)pemEncodedData startMarker:(NSString *)startMarker endMarker:(NSString *)endMarker;
+ (BOOL)checkIfPublicKeyDataIsPkcs1:(NSData *)pkcs1PublicKeyData;
+ (NSData *)convertX509PublicKeyToPkcs1PublicKey:(NSData *)x509PublicKeyData;
+ (NSData *)convertPemCertificateToDer:(NSString *)pemEncodedCertificate;
+ (NSArray *)splitPemCertificateChain:(NSString *)pemCertificateChain;
+ (SecKeyRef)validatePemCertificateChain:(NSString*)pemCertificateChain rootCertificateRefs:(NSArray*)rootCertificateRefs;

@end