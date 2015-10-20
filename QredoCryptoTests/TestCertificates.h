/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface TestCertificates : NSObject

extern NSString *const TestCertJavaSdkRootPem;
extern NSString *const TestCertJavaSdkIntermediatePem;
extern NSString *const TestCertJavaSdkClient1024Pem;
extern NSString *const TestCertJavaSdkClient2048Pem;
extern NSString *const TestCertJavaSdkClient2048DsaPem;
extern NSString *const TestCertJavaSdkClient4096Pem;
extern NSString *const TestCertDHTestingLocalhostRootPem;
extern NSString *const TestCertDHTestingLocalhostClientPem;
extern NSString *const RsaSecurityIncRootCertPem;
extern NSString *const TestKeyJavaSdkClient2048PemX509;
extern NSString *const TestKeyJavaSdkClient4096PemX509;
extern NSString *const TestKeyJavaSdkClient4096PemPkcs1;

extern unsigned char TestCertDHTestingLocalhostClientPkcs12Array[3205];
extern unsigned char TestCertDHTestingLocalhostClientDerArray[869];
extern unsigned char TestCertJavaSdkClient2048WithIntermediatePkcs12Array[4205];
extern unsigned char TestPubKeyJavaSdkClient2048X509DerArray[294];
extern unsigned char TestPrivKeyJavaSdkClient2048Pkcs1DerArray[1192];
extern unsigned char TestPubKeyJavaSdkClient4096X509DerArray[550];
extern unsigned char TestPrivKeyJavaSdkClient4096Pkcs1DerArray[2349];
extern unsigned char TestPubKeyJavaSdkClient4096Pkcs1DerArray[526];

+ (NSString *)fetchStringResource:(NSString *)resource ofType:(NSString *)type error:(NSError **)error;
+ (NSData *)fetchDataResource:(NSString *)resource ofType:(NSString *)type error:(NSError **)error;
+ (NSString *)fetchPemCertificateFromResource:(NSString *)pemResource error:(NSError **)error;
+ (NSString *)fetchPemForResource:(NSString *)pemResource error:(NSError **)error;
+ (NSData *)fetchPfxForResource:(NSString *)pfxResource error:(NSError **)error;

@end
