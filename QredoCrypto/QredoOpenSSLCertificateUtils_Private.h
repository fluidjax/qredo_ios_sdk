/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoOpenSSLCertificateUtils.h"
#import "openssl/pem.h"

@interface QredoOpenSSLCertificateUtils (Private)

+ (STACK_OF(X509) *)createStackFromPemCertificates:(NSArray *)pemCertificates error:(NSError **)error;
+ (STACK_OF(X509_CRL) *)createStackFromPemOrDerCrls:(NSArray *)derCrls error:(NSError **)error;

@end