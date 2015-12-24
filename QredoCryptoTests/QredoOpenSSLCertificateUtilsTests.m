/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "QredoOpenSSLCertificateUtils.h"
#import "QredoOpenSSLCertificateUtils_Private.h"
#import "TestCertificates.h"
#import "QredoCryptoError.h"
#import "QredoCrypto.h"
#import "QredoCertificateUtils.h"

@interface QredoOpenSSLCertificateUtilsTests : XCTestCase

@end

@implementation QredoOpenSSLCertificateUtilsTests

- (void)setUp {
    [super setUp];

    // Must remove any existing keys before starting
    [QredoCrypto deleteAllKeysInAppleKeychain];
}

- (void)tearDown {
    // Should remove any existing keys after finishing
    [QredoCrypto deleteAllKeysInAppleKeychain];

    [super tearDown];
}

#pragma mark - Stack creation

- (void)testCreateStackFromPemCertificates_SingleCert
{
    NSArray *pemCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    
    int expectedNumberOfCertificates = 1;
    
    NSError *error = nil;
    STACK_OF(X509) *certificateStack = [QredoOpenSSLCertificateUtils createStackFromPemCertificates:pemCertificates
                                                                                              error:&error];
    XCTAssertFalse(certificateStack == NULL);
    XCTAssertNil(error);
    
    int numberOfCertificates = sk_X509_num(certificateStack);
    XCTAssertEqual(numberOfCertificates, expectedNumberOfCertificates);
}

- (void)testCreateStackFromPemCertificates_NilCert
{
    NSArray *pemCertificates = nil;
    
    NSError *error = nil;
    XCTAssertThrowsSpecificNamed([QredoOpenSSLCertificateUtils createStackFromPemCertificates:pemCertificates
                                                                                        error:&error],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate array and exception wasn't thrown.");
}

- (void)testCreateStackFromPemCertificates_NoCert
{
    NSArray *pemCertificates = [NSArray array];
    
    int expectedNumberOfCertificates = 0;
    
    NSError *error = nil;
    STACK_OF(X509) *certificateStack = [QredoOpenSSLCertificateUtils createStackFromPemCertificates:pemCertificates
                                                                                              error:&error];
    XCTAssertFalse(certificateStack == NULL);
    XCTAssertNil(error);
    
    int numberOfCertificates = sk_X509_num(certificateStack);
    XCTAssertEqual(numberOfCertificates, expectedNumberOfCertificates);
}

- (void)testCreateStackFromPemCertificates_MultipleCert
{
    NSArray *pemCertificates = [NSArray arrayWithObjects:TestCertJavaSdkClient2048Pem,
                                TestCertJavaSdkIntermediatePem,
                                TestCertJavaSdkRootPem,
                                nil];
    
    int expectedNumberOfCertificates = 3;
    
    NSError *error = nil;
    STACK_OF(X509) *certificateStack = [QredoOpenSSLCertificateUtils createStackFromPemCertificates:pemCertificates
                                                                                              error:&error];
    XCTAssertFalse(certificateStack == NULL);
    XCTAssertNil(error);
    
    int numberOfCertificates = sk_X509_num(certificateStack);
    XCTAssertEqual(numberOfCertificates, expectedNumberOfCertificates);
}

- (void)testCreateStackFromPemCertificates_TestCertDHTestingLocalhostRootPem
{
    NSArray *pemCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem, nil];
    
    int expectedNumberOfCertificates = 1;
    
    NSError *error = nil;
    STACK_OF(X509) *certificateStack = [QredoOpenSSLCertificateUtils createStackFromPemCertificates:pemCertificates
                                                                                              error:&error];
    XCTAssertFalse(certificateStack == NULL);
    XCTAssertNil(error);
    
    int numberOfCertificates = sk_X509_num(certificateStack);
    XCTAssertEqual(numberOfCertificates, expectedNumberOfCertificates);
}

- (void)testCreateStackFromPemCertificates_TestCertDHTestingLocalhostClientPem
{
    NSArray *pemCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostClientPem, nil];
    
    int expectedNumberOfCertificates = 1;
    
    NSError *error = nil;
    STACK_OF(X509) *certificateStack = [QredoOpenSSLCertificateUtils createStackFromPemCertificates:pemCertificates
                                                                                              error:&error];
    XCTAssertFalse(certificateStack == NULL);
    XCTAssertNil(error);
    
    int numberOfCertificates = sk_X509_num(certificateStack);
    XCTAssertEqual(numberOfCertificates, expectedNumberOfCertificates);
}

- (void)testCreateStackFromPemCertificates_RsaSecurityIncRootCertPem
{
    NSArray *pemCertificates = [NSArray arrayWithObjects:RsaSecurityIncRootCertPem, nil];
    
    int expectedNumberOfCertificates = 1;
    
    NSError *error = nil;
    STACK_OF(X509) *certificateStack = [QredoOpenSSLCertificateUtils createStackFromPemCertificates:pemCertificates
                                                                                              error:&error];
    XCTAssertFalse(certificateStack == NULL);
    XCTAssertNil(error);
    
    int numberOfCertificates = sk_X509_num(certificateStack);
    XCTAssertEqual(numberOfCertificates, expectedNumberOfCertificates);
}

- (void)testCreateStackFromPemCertificates_SingleDSACert
{
    NSArray *pemCertificates = [NSArray arrayWithObjects:TestCertJavaSdkClient2048DsaPem, nil];
    
    int expectedNumberOfCertificates = 1;
    
    NSError *error = nil;
    STACK_OF(X509) *certificateStack = [QredoOpenSSLCertificateUtils createStackFromPemCertificates:pemCertificates
                                                                                              error:&error];
    XCTAssertFalse(certificateStack == NULL);
    XCTAssertNil(error);
    
    int numberOfCertificates = sk_X509_num(certificateStack);
    XCTAssertEqual(numberOfCertificates, expectedNumberOfCertificates);
}

#pragma mark - Certificate Validation

- (void)testValidateSelfSignedCertificate_ValidSelfSigned
{
    NSString *pemCertificate = TestCertJavaSdkRootPem;
    
    BOOL expectedValidationResult = YES;
    
    NSError *error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateSelfSignedCertificate:pemCertificate
                                                                                  error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateSelfSignedCertificate_ValidSelfSigned_qredoTestCA
{
    NSError *error = nil;
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(pemCertificate);
    XCTAssertNil(error);
    
    BOOL expectedValidationResult = YES;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateSelfSignedCertificate:pemCertificate
                                                                                  error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateSelfSignedCertificate_Invalid_EndCertificate
{
    NSError *error = nil;
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateSelfSignedCertificate:pemCertificate
                                                                                  error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateSelfSignedCertificate_Invalid_IntermediateCertificate
{
    NSError *error = nil;
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateSelfSignedCertificate:pemCertificate
                                                                                  error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateSelfSignedCertificate_Invalid_EmptyCertificate
{
    NSString *pemCertificate = @"";
    
    BOOL expectedValidationResult = NO;
    
    NSError *error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateSelfSignedCertificate:pemCertificate
                                                                                  error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodeOpenSslCertificateReadFailure);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateSelfSignedCertificate_Invalid_NilCertificate
{
    NSString *pemCertificate = nil;
    
    NSError *error = nil;
    XCTAssertThrowsSpecificNamed([QredoOpenSSLCertificateUtils validateSelfSignedCertificate:pemCertificate
                                                                                       error:&error],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate and exception wasn't thrown.");
}

- (void)testValidateCertificate_ValidChainWithRoot
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"interCA1cert" error:&error], nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"rootCAcert" error:&error], nil];
    
    error = nil;
    BOOL expectedValidationResult = YES;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_ValidChainWithRootAndCrls_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:rootCert, nil];
    NSArray *crls = [NSArray arrayWithObjects:rootCrl, intermediateCrl, nil];
    
    BOOL expectedValidationResult = YES;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Valid_RevokedCertButPreRevokedCrl_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert5.2048.Revoked.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crl" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:rootCert, nil];
    NSArray *crls = [NSArray arrayWithObjects:rootCrl, intermediateCrl, nil];
    
    BOOL expectedValidationResult = YES;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Valid_ValidChainWithMultipleRootsIncCorrectRoot
{
    NSError *error = nil;
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"interCA1cert" error:&error], nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem,
                                    [TestCertificates fetchPemForResource:@"rootCAcert" error:&error],
                                    nil];
    
    BOOL expectedValidationResult = YES;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Valid_ValidChainWithMultipleRootsIncCorrectRoot_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem,
                                    rootCert,
                                    TestCertJavaSdkRootPem,
                                    nil];
    
    BOOL expectedValidationResult = YES;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // Not all roots provided have CRLs available, so cannot do CRL checks
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_RevokedClientCertificate_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert5.2048.Revoked.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:rootCert, nil];
    NSArray *crls = [NSArray arrayWithObjects:rootCrl, intermediateCrl, nil];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_MissingRootCrl_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:rootCert, nil];
    NSArray *crls = [NSArray arrayWithObjects:intermediateCrl, nil];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_MissingIntermediateCrl_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:rootCert, nil];
    NSArray *crls = [NSArray arrayWithObjects:rootCrl, nil];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_MissingAllCrls_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:rootCert, nil];
    NSArray *crls = [[NSArray alloc] init];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_RevokedIntermediateCertificate_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert6.2048.IntCA2cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA2cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA2crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:rootCert, nil];
    NSArray *crls = [NSArray arrayWithObjects:rootCrl, intermediateCrl, nil];
    
    BOOL expectedValidationResult = NO;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_NoChainNoRoot
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    NSArray *pemIntermediateCertificates = [NSArray array];
    NSArray *pemRootCertificates = [NSArray array];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_NilCertificate
{
    NSString *pemCertificate = nil;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertJavaSdkRootPem, nil];
    
    NSError *error = nil;
    XCTAssertThrowsSpecificNamed([QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                              skipRevocationChecks:NO
                                                              chainPemCertificates:pemIntermediateCertificates
                                                               rootPemCertificates:pemRootCertificates
                                                                           pemCrls:nil
                                                                             error:&error],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate and exception wasn't thrown.");
}

- (void)testValidateCertificate_Invalid_NilChain
{
    NSString *pemCertificate = TestCertJavaSdkClient4096Pem;
    NSArray *pemIntermediateCertificates = nil;
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertJavaSdkRootPem, nil];
    
    NSError *error = nil;
    XCTAssertThrowsSpecificNamed([QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                              skipRevocationChecks:NO
                                                              chainPemCertificates:pemIntermediateCertificates
                                                               rootPemCertificates:pemRootCertificates
                                                                           pemCrls:nil
                                                                             error:&error],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate chain and exception wasn't thrown.");
}

- (void)testValidateCertificate_Invalid_NilRoot
{
    NSString *pemCertificate = TestCertJavaSdkClient4096Pem;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    NSArray *pemRootCertificates = nil;
    
    NSError *error = nil;
    XCTAssertThrowsSpecificNamed([QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                              skipRevocationChecks:NO
                                                              chainPemCertificates:pemIntermediateCertificates
                                                               rootPemCertificates:pemRootCertificates
                                                                           pemCrls:nil
                                                                             error:&error],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Passed nil certificate root and exception wasn't thrown.");
}

- (void)testValidateCertificate_ValidRsaAsCertAndRoot
{
    NSString *pemCertificate = RsaSecurityIncRootCertPem;
    NSArray *pemIntermediateCertificates = [NSArray array];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:RsaSecurityIncRootCertPem, nil];
    
    BOOL expectedValidationResult = YES;
    
    NSError *error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Valid_DHCertWithRoot
{
    // http://security.stackexchange.com/a/82868/94521
    
    NSString *dhCert = @"-----BEGIN CERTIFICATE-----\n"
    "MIICATCCAWoCCQD269NSkQbjtTANBgkqhkiG9w0BAQsFADBFMQswCQYDVQQGEwJB\n"
    "VTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0\n"
    "cyBQdHkgTHRkMB4XDTE1MTIxNDE0MTIxN1oXDTE2MDExMzE0MTIxN1owRTELMAkG\n"
    "A1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoMGEludGVybmV0\n"
    "IFdpZGdpdHMgUHR5IEx0ZDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA+wyD\n"
    "BlGXKto7If2kwznJUMwBFYlIq1Qfsq6m3WJoKHtRujnO9OOMqV+qZt1du04Yd+sH\n"
    "J5aJjXJf+iKlombJ9pUn3hoKVYytZemNvXcTw9BLqGoCV8bMfz1MoWbEs6e31wOU\n"
    "HEfT5Anu3Sdp4HOMViQjcHGfdyhe7jZRas0hr3ECAwEAATANBgkqhkiG9w0BAQsF\n"
    "AAOBgQAy31xkBvTUwe0LWweWr6a8H7T4oZTwMEejbGajSCjoBm1wCwFrmCQn0BfX\n"
    "m4Bf5oK3tQkRbtYqRy+F56diCFx5UCfrEFJGAQmFoA92NTfifAcjTeoAmfUgTLAL\n"
    "o7cRnuZIfdw0mp6+kuL82sk6/gQOGSPIo5BmetXH4ubpf56X7w==\n"
    "-----END CERTIFICATE-----\n"; // From StackExchange link
    
    NSString *rootCert = @"-----BEGIN CERTIFICATE-----\n"
    "MIICsDCCAhmgAwIBAgIJANcISDG0V6EwMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV\n"
    "BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX\n"
    "aWRnaXRzIFB0eSBMdGQwHhcNMTUxMjExMTUzNzM0WhcNMjUxMjA4MTUzNzM0WjBF\n"
    "MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50\n"
    "ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB\n"
    "gQC+bEnE6V1zmhTp3jxfjdANSuDHJ8au26GRhirDuQ5S4aeGxJ2M3iKawjvS4J/H\n"
    "F4Voc8qyDM12DfkuqCjk4FbQaTsOrKZPW+M61w5qvvXqsE6y7sTqRZ2QJbc9avUG\n"
    "CQgo8cHsXAdpUKJynIl65tPcQNu7Rd8FCkGPngBvidwjNwIDAQABo4GnMIGkMB0G\n"
    "A1UdDgQWBBSDWtue1RiI4cN0R2zHx4rqu82z1zB1BgNVHSMEbjBsgBSDWtue1RiI\n"
    "4cN0R2zHx4rqu82z16FJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUt\n"
    "U3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJANcISDG0\n"
    "V6EwMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAd3e0o6E4EG1/iFbu\n"
    "PlZhWE7Nw7puAfhYTB4oIqc/DBcooHYtcpUYOUyTlRYd7/dlFqjfgD5/0ppAvIEI\n"
    "iu6UD6O6J0uycPQTQnOa4u1gjrQ8EtYkN4tDFuqQjxl5Pg/iGbtg823wqGlJXrUW\n"
    "bciyRqxp5WnZOvqD6n8z0haN+LE=\n"
    "-----END CERTIFICATE-----\n"; // From test_root_ca.crt
    
    NSString *pemCertificate = TestCertDHTestingLocalhostClientPem;
    NSArray *pemIntermediateCertificates = [NSArray array];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem, nil];
    
    
    NSArray *rootCertificateRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCert];
    XCTAssertNotNil(rootCertificateRefs, @"Root certificates should not be nil.");
    
    NSArray *certificateChainRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:dhCert];
    XCTAssertNotNil(certificateChainRefs, @"Certificate chain array should not be nil.");
    
    SecKeyRef validationResult = [QredoCertificateUtils validateCertificateChain:certificateChainRefs rootCertificateRefs:rootCertificateRefs];

    XCTAssertNotNil((__bridge id)validationResult);
}

- (void)testValidateCertificate_Valid_JavaSdkChain4096
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"interCA1cert" error:&error], nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"rootCAcert" error:&error], nil];
    
    BOOL expectedValidationResult = YES;
    
    error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Valid_JavaSdkChain2048
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert2.2048.IntCA1cert" error:&error];
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"interCA1cert" error:&error], nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"rootCAcert" error:&error], nil];
    
    BOOL expectedValidationResult = YES;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_JavaSdkChain4096_MissingIntermediate
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    NSArray *pemIntermediateCertificates = [NSArray array];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"rootCAcert" error:&error], nil];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_JavaSdkChain2048_WrongIntermediate
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert2.2048.IntCA1cert" error:&error];
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"rootCAcert" error:&error], nil];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_JavaSdkChain2048_IncorrectRoot
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert2.2048.IntCA1cert" error:&error];
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"interCA1cert" error:&error], nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem, nil];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;

    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_TooShortKey_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert1.1024.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:rootCert, nil];
    NSArray *crls = [NSArray arrayWithObjects:rootCrl, intermediateCrl, nil];
    
    BOOL expectedValidationResult = NO;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_TooLongKey_qredoTestCA
{
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemForResource:@"clientCert4.8192.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemForResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    NSString *pemCertificate = cert;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:intermediateCert, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:rootCert, nil];
    NSArray *crls = [NSArray arrayWithObjects:rootCrl, intermediateCrl, nil];
    
    BOOL expectedValidationResult = NO;
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_CertIsRoot_NoRootsProvided
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert1.1024.IntCA1cert" error:&error];
    NSArray *pemIntermediateCertificates = [NSArray array];
    NSArray *pemRootCertificates = [NSArray array];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_CertIsRoot_IncorrectRootProvided
{
    NSString *pemCertificate = TestCertDHTestingLocalhostRootPem;
    NSArray *pemIntermediateCertificates = [NSArray array];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertJavaSdkRootPem, nil];
    
    BOOL expectedValidationResult = NO;
    
    NSError *error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_RootAndCertSwitched
{
    NSString *pemCertificate = TestCertJavaSdkRootPem;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertJavaSdkClient2048Pem, nil];
    
    BOOL expectedValidationResult = NO;
    
    NSError *error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_DsaCert
{
    // OpenSSL has now been built without DSA support, so rather than explicitly detecting an unsupported (non-RSA)
    // key type, the method now returns an error as OpenSSL cannot parse the DSA cert.  As long as non-RSA certs
    // cannot be used, doesn't matter - so no check on returned NSError value now - nil or not nil is fine, as long
    // as validation fails.
    NSString *pemCertificate = TestCertJavaSdkClient2048DsaPem;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertJavaSdkRootPem, nil];
    
    BOOL expectedValidationResult = NO;
    
    NSError *error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_TooShortCertificateKey
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert1.1024.IntCA1cert" error:&error];
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"interCA1cert" error:&error], nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:[TestCertificates fetchPemForResource:@"rootCAcert" error:&error], nil];
    
    BOOL expectedValidationResult = NO;
    
    error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:YES // No CRLs available for this CA chain
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:nil
                                                                        error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

#pragma mark - Certificate to SecKeyRef conversion

- (void)testGetPublicKeyRefFromPemCertificate_Valid_qredoTestCA
{
    NSError *error = nil;
    
    NSString *pemCertificate = [TestCertificates fetchPemForResource:@"clientCert3.4096.IntCA1cert" error:&error];
    XCTAssertNotNil(pemCertificate);
    XCTAssertNil(error);
    
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKeyImport1";
    
    SecKeyRef publicKeyRef = [QredoOpenSSLCertificateUtils getPublicKeyRefFromPemCertificate:pemCertificate
                                                                         publicKeyIdentifier:publicKeyIdentifier
                                                                                       error:&error];
    XCTAssertTrue((__bridge id)publicKeyRef, @"Public Key processing failed.");
    XCTAssertNil(error);

}

#pragma mark -

@end
