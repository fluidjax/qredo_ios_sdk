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
    NSString *pemCertificate = TestCertJavaSdkClient4096Pem;
    
    BOOL expectedValidationResult = NO;
    
    NSError *error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateSelfSignedCertificate:pemCertificate
                                                                                  error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateSelfSignedCertificate_Invalid_IntermediateCertificate
{
    NSString *pemCertificate = TestCertJavaSdkIntermediatePem;
    
    BOOL expectedValidationResult = NO;
    
    NSError *error = nil;
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateSelfSignedCertificate:pemCertificate
                                                                                  error:&error];
    XCTAssertNil(error);
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
    NSString *pemCertificate = TestCertJavaSdkClient4096Pem;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertJavaSdkRootPem, nil];
    
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
    NSString *pemCertificate = TestCertJavaSdkClient4096Pem;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem,
                                    TestCertJavaSdkRootPem,
                                    nil];
    
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
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNil(error);
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
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNil(error);
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
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNil(error);
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
    
    BOOL validationResult = [QredoOpenSSLCertificateUtils validateCertificate:pemCertificate
                                                         skipRevocationChecks:NO
                                                         chainPemCertificates:pemIntermediateCertificates
                                                          rootPemCertificates:pemRootCertificates
                                                                      pemCrls:crls
                                                                        error:&error];
    
    XCTAssertNil(error);
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
    
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_NoChainNoRoot
{
    NSString *pemCertificate = TestCertJavaSdkClient4096Pem;
    NSArray *pemIntermediateCertificates = [NSArray array];
    NSArray *pemRootCertificates = [NSArray array];
    
    BOOL expectedValidationResult = NO;
    
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
    NSString *pemCertificate = TestCertDHTestingLocalhostClientPem;
    NSArray *pemIntermediateCertificates = [NSArray array];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem, nil];
    
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

- (void)testValidateCertificate_Valid_JavaSdkChain4096
{
    NSString *pemCertificate = TestCertJavaSdkClient4096Pem;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertJavaSdkRootPem, nil];
    
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

- (void)testValidateCertificate_Valid_JavaSdkChain2048
{
    NSString *pemCertificate = TestCertJavaSdkClient2048Pem;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertJavaSdkRootPem, nil];
    
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

- (void)testValidateCertificate_Invalid_JavaSdkChain4096_MissingIntermediate
{
    NSString *pemCertificate = TestCertJavaSdkClient4096Pem;
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
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_JavaSdkChain2048_WrongIntermediate
{
    NSString *pemCertificate = TestCertJavaSdkClient2048Pem;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertJavaSdkRootPem, nil];
    
    BOOL expectedValidationResult = NO;
    
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

- (void)testValidateCertificate_Invalid_JavaSdkChain2048_IncorrectRoot
{
    NSString *pemCertificate = TestCertJavaSdkClient2048Pem;
    NSArray *pemIntermediateCertificates = [NSArray arrayWithObjects:TestCertJavaSdkIntermediatePem, nil];
    NSArray *pemRootCertificates = [NSArray arrayWithObjects:TestCertDHTestingLocalhostRootPem, nil];
    
    BOOL expectedValidationResult = NO;
    
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
    
    XCTAssertNil(error);
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
    XCTAssertNil(error);
    XCTAssertEqual(validationResult, expectedValidationResult);
}

- (void)testValidateCertificate_Invalid_CertIsRoot_NoRootsProvided
{
    NSString *pemCertificate = TestCertDHTestingLocalhostRootPem;
    NSArray *pemIntermediateCertificates = [NSArray array];
    NSArray *pemRootCertificates = [NSArray array];
    
    BOOL expectedValidationResult = NO;
    
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
    XCTAssertNil(error);
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
    XCTAssertNil(error);
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
    NSString *pemCertificate = TestCertJavaSdkClient1024Pem;
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
    XCTAssertNil(error);
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
