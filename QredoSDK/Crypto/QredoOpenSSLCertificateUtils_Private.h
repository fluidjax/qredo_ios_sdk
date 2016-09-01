/* HEADER GOES HERE */
#import "QredoOpenSSLCertificateUtils.h"
#import <openssl/pem.h>

@interface QredoOpenSSLCertificateUtils (Private)

+ (STACK_OF(X509) *)createStackFromPemCertificates:(NSArray *)pemCertificates error:(NSError **)error;
+ (STACK_OF(X509_CRL) *)createStackFromPemOrDerCrls:(NSArray *)derCrls error:(NSError **)error;

@end