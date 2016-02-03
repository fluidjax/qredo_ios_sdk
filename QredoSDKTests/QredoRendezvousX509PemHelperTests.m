/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoRendezvousHelpers.h"
#import "QredoCrypto.h"
#import "CryptoImplV1.h"
#import "TestCertificates.h"
#import "QredoCertificateUtils.h"
#import "QredoClient.h"
#import "QredoAuthenticatedRendezvousTag.h"
#import "NSData+QredoRandomData.h"
#import "QredoCryptoError.h"
#import "QredoXCTestCase.h"

@interface QredoRendezvousX509PemHelperTests : QredoXCTestCase
@property (nonatomic) id<CryptoImpl> cryptoImpl;
@property (nonatomic) NSArray *trustedRootPems;
@property (nonatomic) NSArray *crlPems;
@property (nonatomic) SecKeyRef privateKeyRef;
@property (nonatomic, copy) NSString *publicKeyCertificateChainPem;
@end

@implementation QredoRendezvousX509PemHelperTests

- (void)setUp {
    [super setUp];
    
    [self setupRootCertificates];
    [self setupCrls];
    self.cryptoImpl = [[CryptoImplV1 alloc] init];
    
    // For most tests we'll use the 2048 bit key
    [self setupTestPublicCertificateAndPrivateKey_qredoTestCA_2048];
}

- (void)tearDown {
    [super tearDown];
}

- (void)setupRootCertificates
{
    NSError *error = nil;

    // Test certs root CA cert
    NSString *rootCert = [TestCertificates fetchPemCertificateFromResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    self.trustedRootPems = [NSArray arrayWithObjects:rootCert, nil];
    XCTAssertNotNil(self.trustedRootPems);
}

- (void)setupCrls
{
    NSError *error = nil;
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    self.crlPems = [NSArray arrayWithObjects:rootCrl, intermediateCrl, nil];
}

- (void)setupTestPublicCertificateAndPrivateKeyForPfxResource:(NSString *)resource
{
    // iOS only supports importing a private key in PKC#12 format, so some pain required in getting from PKCS#12 to
    // raw private RSA key, and the PEM public certificates
    
    // Import some PKCS#12 data and then get the certificate chain refs from the identity.
    // Use SecCertificateRefs to create a PEM which is then processed (to confirm validity)
    
    
    // 1.) Create identity - Test client certificate + priv key from QredoTestCA, with intermediate cert
    NSError *error = nil;
    
    NSString *pkcs12Password = @"password";
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:resource error:&error];
    XCTAssertNotNil(pkcs12Data);
    XCTAssertNil(error);
    int expectedNumberOfCertsInCertChain = 2;
    
    // QredoTestCA root
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCertificatesPemString);
    XCTAssertNil(error);
    int expectedNumberOfRootCertificateRefs = 1;
    
    // Get the SecCertificateRef array for the root cert
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    XCTAssertNotNil(rootCertificates, @"Root certificates should not be nil.");
    XCTAssertEqual(rootCertificates.count, expectedNumberOfRootCertificateRefs, @"Wrong number of root certificate refs returned.");
    
    // Create an Identity using the PKCS#12 data, validated with the root certificate ref
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data
                                                                                             password:pkcs12Password
                                                                                  rootCertificateRefs:rootCertificates];
    XCTAssertNotNil(identityDictionary, @"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    // Extract the SecTrustRef from the Identity Dictionary result to ensure trust was successful
    SecTrustRef trustRef = (SecTrustRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary, kSecImportItemTrust);
    XCTAssertNotNil((__bridge id)trustRef, @"Incorrect identity validation result dictionary contents. Should contain valid trust ref.");
    
    // Extract the certificate chain refs (client and intermediate certs) from the Identity Dictionary result to ensure chain is correct
    NSArray *certChain = (NSArray *)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary, kSecImportItemCertChain);
    XCTAssertNotNil(certChain, @"Incorrect identity validation result dictionary contents. Should contain valid cert chain array.");
    XCTAssertEqual(certChain.count, expectedNumberOfCertsInCertChain, @"Incorrect identity validation result dictionary contents. Wrong number of certificate refs in cert chain.");
    
    // Extract the SecIdentityRef from Identity Dictionary, this enables us to get the private SecKeyRef out, which is needed for RSA operations in tests
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary, kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef, @"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");
    
    // Extract the SecKeyRef from the identity
    self.privateKeyRef = [QredoCrypto getPrivateKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)self.privateKeyRef);
    
    // 2.) Create Certificate Refs from Identity Dictionary and convert to PEM string
    NSArray *certificateChainRefs = (NSArray *)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,
                                                                    kSecImportItemCertChain);
    XCTAssertNotNil(certificateChainRefs, @"Incorrect identity validation result dictionary contents. Should contain valid certificate chain array.");
    XCTAssertEqual(certificateChainRefs.count, expectedNumberOfCertsInCertChain, @"Incorrect identity validation result dictionary contents. Should contain expected number of certificate chain refs.");
    
    // The PEM certs for the full chain becomes the authentication tag in the tests.
    self.publicKeyCertificateChainPem = [QredoCertificateUtils convertCertificateRefsToPemCertificate:certificateChainRefs];
    XCTAssertNotNil(self.publicKeyCertificateChainPem);
}

- (void)setupTestPublicCertificateAndPrivateKey_qredoTestCA_2048
{
    [self setupTestPublicCertificateAndPrivateKeyForPfxResource:@"clientCert2.2048.IntCA1"];
}

- (void)testSignatureAndVerification_ExternalKeys
{
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    NSError *error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeX509Pem);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    XCTAssert([finalFullTag hasSuffix:self.publicKeyCertificateChainPem]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    XCTAssertEqual(respondHelper.type, QredoRendezvousAuthenticationTypeX509Pem);
    
    NSString *respondFullTag = [respondHelper tag];
    XCTAssertNotNil(respondFullTag);
    XCTAssert([respondFullTag isEqualToString:finalFullTag]);

    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QLFRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:signature rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerification_ExternalKeys_RootIncludedInPemCertChain
{
    // This test proves that including the Root in the PEM cert chain (should just be 'Subject->Intermediate')
    // doesn't cause the validation to fail.  There's a separate test to prove that doing so doesn't automatically
    // make the chain trusted
    
    // Concatenate the Subject (2048 bit key), Intermediate and Root certs together
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemCertificateFromResource:@"clientCert2.2048.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemCertificateFromResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemCertificateFromResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    // Concatenate the Subject (2048 bit key), Root and Intermediate certs together in an unexpected (but not invalid) order
    NSString *publicKeyCertificateChainWithRootIncluded = [NSString stringWithFormat:@"%@%@%@",
                                                           cert,
                                                           intermediateCert,
                                                           rootCert];
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = publicKeyCertificateChainWithRootIncluded;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeX509Pem);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    XCTAssert([finalFullTag hasSuffix:publicKeyCertificateChainWithRootIncluded]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    XCTAssertEqual(respondHelper.type, QredoRendezvousAuthenticationTypeX509Pem);
    
    NSString *respondFullTag = [respondHelper tag];
    XCTAssertNotNil(respondFullTag);
    XCTAssert([respondFullTag isEqualToString:finalFullTag]);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QLFRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:signature rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerification_ExternalKeys_OutOfOrderPemChain
{
    // This test proves changing the order of the PEM chain (although keeping Subject cert first) doesn't cause
    // the validation to fail.
    
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemCertificateFromResource:@"clientCert2.2048.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemCertificateFromResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemCertificateFromResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    // Concatenate the Subject (2048 bit key), Root and Intermediate certs together in an unexpected (but not invalid) order
    NSString *outOfOrderPublicKeyCertificateChain = [NSString stringWithFormat:@"%@%@%@",
                                                           cert,
                                                           rootCert,
                                                           intermediateCert];
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = outOfOrderPublicKeyCertificateChain;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeX509Pem);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    XCTAssert([finalFullTag hasSuffix:outOfOrderPublicKeyCertificateChain]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    XCTAssertEqual(respondHelper.type, QredoRendezvousAuthenticationTypeX509Pem);
    
    NSString *respondFullTag = [respondHelper tag];
    XCTAssertNotNil(respondFullTag);
    XCTAssert([respondFullTag isEqualToString:finalFullTag]);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QLFRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:signature rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerification_ExternalKeys_IncludeUnnecessaryPemCerts
{
    // This test proves that including unnecessary PEM certificates doesn't prevent the authenticated rendezvous
    // being created, and that the unnecessary certs appear in the final tag.
    
    // Concatenate the Subject (2048 bit key), repeated Root and Intermediate certs, along with unrelated certs
    // together in any old order.
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemCertificateFromResource:@"clientCert2.2048.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *unnecessaryCert1 = [TestCertificates fetchPemCertificateFromResource:@"clientCert3.4096.IntCA1cert" error:&error];
    XCTAssertNotNil(unnecessaryCert1);
    XCTAssertNil(error);

    NSString *unnecessaryCert2 = [TestCertificates fetchPemCertificateFromResource:@"clientCert6.2048.IntCA2cert" error:&error];
    XCTAssertNotNil(unnecessaryCert2);
    XCTAssertNil(error);

    NSString *unnecessaryCert3 = [TestCertificates fetchPemCertificateFromResource:@"interCA2cert" error:&error];
    XCTAssertNotNil(unnecessaryCert3);
    XCTAssertNil(error);

    NSString *intermediateCert = [TestCertificates fetchPemCertificateFromResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemCertificateFromResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    // Concatenate the Subject (2048 bit key), Root and Intermediate certs together in an unexpected (but not invalid) order
    NSString *unnecessaryPublicKeyCertificateChain = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                                                      cert,
                                                      unnecessaryCert1,
                                                      unnecessaryCert2,
                                                      intermediateCert,
                                                      unnecessaryCert3,
                                                      rootCert];
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = unnecessaryPublicKeyCertificateChain;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeX509Pem);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    XCTAssert([finalFullTag hasSuffix:unnecessaryPublicKeyCertificateChain]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    XCTAssertEqual(respondHelper.type, QredoRendezvousAuthenticationTypeX509Pem);
    
    NSString *respondFullTag = [respondHelper tag];
    XCTAssertNotNil(respondFullTag);
    XCTAssert([respondFullTag isEqualToString:finalFullTag]);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QLFRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:signature rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerification_ExternalKeys_MultiUse {
    
    // Importing the same key (even under different name) into Apple Keychain has been seen to fail at times.
    // Under the hood, for external keys, this helper imports the public key to get SecKeyRefs needed for verifying
    // signatures, before deleting it again once helper is deallocated.
    // This test will ensure multiple helpers using the same authentication tag (public key) can be created
    // simutaneously without issue. Will use same prefix, and different prefix to test this.
    
    NSString *authenticationTag = self.publicKeyCertificateChainPem;

    NSString *prefix1 = @"MyTestRendezVous";
    NSString *initialFullTag1 = [NSString stringWithFormat:@"%@@%@", prefix1, authenticationTag];
    
    NSString *prefix2 = @"MyOtherTestRendezVous";
    NSString *initialFullTag2 = [NSString stringWithFormat:@"%@@%@", prefix2, authenticationTag];

    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    NSError *error = nil;
    id<QredoRendezvousCreateHelper> createHelper1
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag1
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper1);
    XCTAssertNil(error);
    
    NSString *finalFullTag1 = [createHelper1 tag];
    XCTAssertNotNil(finalFullTag1);
    XCTAssert([finalFullTag1 hasPrefix:prefix1]);
    
    // Use 2nd time (same prefix)
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper2
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag1
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper2);
    XCTAssertNil(error);
    
    NSString *finalFullTag2 = [createHelper2 tag];
    XCTAssertNotNil(finalFullTag2);
    XCTAssert([finalFullTag2 hasPrefix:prefix1]);
    
    // Use 3rd time (different prefix)
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper3
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag2
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper3);
    XCTAssertNil(error);
    
    NSString *finalFullTag3 = [createHelper3 tag];
    XCTAssertNotNil(finalFullTag3);
    XCTAssert([finalFullTag3 hasPrefix:prefix2]);
    
    // Use 1st time
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper1
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag1
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper1);
    XCTAssertNil(error);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QLFRendezvousAuthSignature *signature1 = [createHelper1 signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature1);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper1 isValidSignature:signature1 rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    
    // Use 2nd time (same tag)
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper2
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag1
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper2);
    XCTAssertNil(error);
    
    error = nil;
    QLFRendezvousAuthSignature *signature2 = [createHelper2 signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature2);
    XCTAssertNil(error);
    
    error = nil;
    result = [respondHelper2 isValidSignature:signature2 rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    
    // Use 3rd time (different tag)
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper3
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag2
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper2);
    XCTAssertNil(error);
    
    error = nil;
    QLFRendezvousAuthSignature *signature3 = [createHelper2 signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature3);
    XCTAssertNil(error);
    
    error = nil;
    result = [respondHelper3 isValidSignature:signature3 rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerification_ExternalKeys_BadSigning
{
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    // Generate an invalid signature (use incorrect salt length)
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = 10;
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    NSError *error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    XCTAssert([finalFullTag hasSuffix:self.publicKeyCertificateChainPem]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QLFRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNil(signature);
    XCTAssertNotNil(error);
}

- (void)testEmptySignature
{
    NSUInteger expectedEmptySignatureLength = 256; // X.509 Authenticated Rendezvous always returns 256 bit empty signature, irrespective of key length

    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (we're not signing anything), we just need a valid block (so just return input)
        return data;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    // Get the empty signature from create helper
    QLFRendezvousAuthSignature *createHelperEmptySignature = [createHelper emptySignature];
    XCTAssertNotNil(createHelperEmptySignature);
    __block NSData *signatureData = nil;

    [createHelperEmptySignature ifRendezvousAuthX509_PEM:^(NSData *signature) {
        signatureData = signature;
    } ifRendezvousAuthX509_PEM_SELFSIGNED:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } ifRendezvousAuthED25519:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } ifRendezvousAuthRSA2048_PEM:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } ifRendezvousAuthRSA4096_PEM:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    }];
    
    XCTAssertNotNil(signatureData);
    XCTAssertEqual(signatureData.length, expectedEmptySignatureLength);
    
    // Get the empty signature from respond helper
    QLFRendezvousAuthSignature *respondHelperEmptySignature = [respondHelper emptySignature];
    XCTAssertNotNil(respondHelperEmptySignature);
    signatureData = nil;

    [respondHelperEmptySignature ifRendezvousAuthX509_PEM:^(NSData *signature) {
        signatureData = signature;
    } ifRendezvousAuthX509_PEM_SELFSIGNED:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } ifRendezvousAuthED25519:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } ifRendezvousAuthRSA2048_PEM:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } ifRendezvousAuthRSA4096_PEM:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    }];
    
    XCTAssertNotNil(signatureData);
    XCTAssertEqual(signatureData.length, expectedEmptySignatureLength);
    
    // Empty signatures from create and respond helpers should be equal
    NSComparisonResult comparisonResult = [createHelperEmptySignature compare:respondHelperEmptySignature];
    XCTAssertEqual(comparisonResult, NSOrderedSame);
}

- (void)testCreateHelper_Invalid_InternalKeys {
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally (not valid for X509)
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorAuthenticationTagMissing);
    

}

- (void)testCreateHelper_Invalid_MissingCrypto
{
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), we just need a valid block (so just return input)
        return data;
    };

    id<CryptoImpl> crypto = nil;
    
    error = nil;
    
    XCTAssertThrows([QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                                          fullTag:initialFullTag
                                                                           crypto:crypto
                                                                  trustedRootPems:self.trustedRootPems
                                                                          crlPems:self.crlPems
                                                                   signingHandler:signingHandler
                                                                            error:&error]);
}

- (void)testCreateHelper_Invalid_NilTag
{
    NSError *error = nil;
    NSString *initialFullTag = nil;
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testCreateHelper_Invalid_EmptyTag
{
    NSError *error = nil;
    NSString *initialFullTag = @""; // Empty tag is invalid for create (as @ and cert chain missing)
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testCreateHelper_Invalid_TooShortTag
{
    NSError *error = nil;
    NSString *initialFullTag = @"@somethingtooshort";
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorAuthenticationTagInvalid);
}

- (void)testCreateHelper_Invalid_InvalidPublicKeyCertChain
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    
    // Authentication tag needs to be at least 256 bytes to enable it to try to be imported
    NSString *authenticationTag = [[NSString alloc] initWithData:[NSData dataWithRandomBytesOfLength:256]
                                                        encoding:NSUTF8StringEncoding]; // Min length check is 256 bytes
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorAuthenticationTagInvalid);
}

- (void)testCreateHelper_Invalid_UntrustedPublicKeyCertChain
{
    // To not trust the chain, we must create an empty array
    NSArray *noTrustedRoots = [[NSArray alloc] init];

    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];

    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (we're not signing anything), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:noTrustedRoots
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodeCertificateIsNotValid);
}

- (void)testCreateHelper_Invalid_UntrustedPublicKeyCertChainWithRootInChain
{
    // This test will not have any trusted roots, but will include the root in the PEM chain.
    // This test will ensure that this scenario does not result in trust verifying.

    // Concatenate the Subject (2048-bit key), Intermediate and Root certs together
    NSError *error = nil;
    
    NSString *cert = [TestCertificates fetchPemCertificateFromResource:@"clientCert2.2048.IntCA1cert" error:&error];
    XCTAssertNotNil(cert);
    XCTAssertNil(error);
    
    NSString *intermediateCert = [TestCertificates fetchPemCertificateFromResource:@"interCA1cert" error:&error];
    XCTAssertNotNil(intermediateCert);
    XCTAssertNil(error);
    
    NSString *rootCert = [TestCertificates fetchPemCertificateFromResource:@"rootCAcert" error:&error];
    XCTAssertNotNil(rootCert);
    XCTAssertNil(error);
    
    // Concatenate the Subject (2048-bit key), Intermediate and Root certs together
    NSString *publicKeyCertificateChainWithRootIncluded = [NSString stringWithFormat:@"%@%@%@",
                                                           cert,
                                                           intermediateCert,
                                                           rootCert];
    
    // To not trust the chain, we must create an empty array
    NSArray *noTrustedRoots = [[NSArray alloc] init];
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = publicKeyCertificateChainWithRootIncluded;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (we're not signing anything), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:noTrustedRoots
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodeCertificateIsNotValid);
}

- (void)testCreateHelper_Invalid_MissingCrlForIntermediate
{
    NSError *error = nil;
    
    NSString *intermediateCrl = [TestCertificates fetchPemForResource:@"interCA1crlAfterRevoke" error:&error];
    XCTAssertNotNil(intermediateCrl);
    XCTAssertNil(error);
    
    // Only provide the Intermediate CRL
    NSArray *intermediateCrlOnly = [[NSArray alloc] initWithObjects:intermediateCrl, nil];
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (we're not signing anything), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:intermediateCrlOnly
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodeCertificateIsNotValid);
}

- (void)testCreateHelper_Invalid_NoCrls
{
    NSError *error = nil;
    
    // Don't provide any CRLs
    NSArray *noCrls = [[NSArray alloc] init];
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (we're not signing anything), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:noCrls
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodeCertificateIsNotValid);
}

- (void)testCreateHelper_Invalid_ClientCertRevoked
{
    // Switch test to use private key from revoked client cert
    [self setupTestPublicCertificateAndPrivateKeyForPfxResource:@"clientCert5.2048.Revoked.IntCA1"];

    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (we're not signing anything), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodeCertificateIsNotValid);
}

- (void)testCreateHelper_Invalid_IntermediateCertRevoked
{
    // Switch test to use private key from revoked intermediate cert (CA2 is revoked)
    [self setupTestPublicCertificateAndPrivateKeyForPfxResource:@"clientCert6.2048.IntCA2"];
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (we're not signing anything), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodeCertificateIsNotValid);
}

- (void)testCreateHelper_Invalid_MissingCrlForRoot
{
    NSError *error = nil;
    
    NSString *rootCrl = [TestCertificates fetchPemForResource:@"rootCAcrlAfterRevoke" error:&error];
    XCTAssertNotNil(rootCrl);
    XCTAssertNil(error);
    
    // Only provide the Root CRL
    NSArray *rootCrlOnly = [[NSArray alloc] initWithObjects:rootCrl, nil];
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (we're not signing anything), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:rootCrlOnly
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodeCertificateIsNotValid);
}

- (void)testCreateHelper_Invalid_MultipleAtsInTag
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendez@Vous"; // extra @ in the overall tag
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                    signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testCreateHelper_Invalid_MissingAtFromStartOfAuthenticationTag
{
    NSError *error = nil;
    NSString *initialFullTag = self.publicKeyCertificateChainPem; // No @ prior to authentication tag
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testCreateHelper_Invalid_ExternalKeysMissingSigningHandler
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem; // External keys, needs a signing handler
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    signDataBlock signingHandler = nil; // No signing handler provided
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorSignatureHandlerMissing);
}

- (void)testCreateHelper_Invalid_ClientCertificateKeyTooShort
{
    // Switch test to use private key from client cert with 1024 bit key (too short)
    [self setupTestPublicCertificateAndPrivateKeyForPfxResource:@"clientCert1.1024.IntCA1"];
    
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem; // External keys, needs a signing handler
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodePublicKeyInvalid);
}

- (void)testCreateHelperSigning_Invalid_NilDataToSign
{
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:self.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    NSError *error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    XCTAssert([finalFullTag hasSuffix:self.publicKeyCertificateChainPem]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *dataToSign = nil;
    
    error = nil;
    QLFRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNil(signature);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingDataToSign);
}

- (void)testCreateHelperSigning_Invalid_ExternalKeysSignerReturnsNil
{
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);

        // Return a nil signature
        return nil;
    };
    
    NSError *error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    XCTAssert([finalFullTag hasSuffix:self.publicKeyCertificateChainPem]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QLFRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNil(signature);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorBadSignature);
}

- (void)testRespondHelper_Invalid_MissingCrypto
{
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<CryptoImpl> crypto = nil;

    error = nil;
    
    XCTAssertThrows([QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                                          fullTag:initialFullTag
                                                                           crypto:crypto
                                                                  trustedRootPems:self.trustedRootPems
                                                                          crlPems:self.crlPems
                                                                            error:&error]);
}

- (void)testRespondHelper_Invalid_NilTag
{
    NSError *error = nil;
    NSString *initialFullTag = nil;
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testRespondHelper_Invalid_EmptyTag
{
    NSError *error = nil;
    NSString *initialFullTag = @""; // Empty tag is invalid for respond (as @ and cert chain missing)
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testRespondHelper_Invalid_TooShortTag
{
    NSError *error = nil;
    NSString *initialFullTag = @"@somethingtooshort";
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorAuthenticationTagInvalid);
}


- (void)testRespondHelper_Invalid_InvalidPublicKeyCertChain
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    
    // Authentication tag needs to be at least 256 bytes to enable it to try to be imported
    NSString *authenticationTag = [[NSString alloc] initWithData:[NSData dataWithRandomBytesOfLength:256]
                                                        encoding:NSUTF8StringEncoding]; // Min length check is 256 bytes
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorAuthenticationTagInvalid);
}

- (void)testRespondHelper_Invalid_UntrustedPublicKeyCertChain
{
    // For this test, use a trusted chain to create the full tag, but when creating the response helper, don't include trust roots
    
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];

    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (we're not signing anything), we just need a valid block (so just return input)
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    XCTAssert([finalFullTag hasSuffix:self.publicKeyCertificateChainPem]);
    
    // To not trust the chain, we must create an empty array
    NSArray *noTrustedRoots = [[NSArray alloc] init];

    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:noTrustedRoots
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoCryptoErrorDomain);
    XCTAssertEqual(error.code, QredoCryptoErrorCodeCertificateIsNotValid);
}


- (void)testRespondHelper_Invalid_MultipleAtsInTag
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendez@Vous"; // extra @ in the overall tag
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testRespondHelper_Invalid_MissingAtFromStartOfAuthenticationTag
{
    NSError *error = nil;
    NSString *initialFullTag = self.publicKeyCertificateChainPem; // No @ prior to authentication tag
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testRespondHelper_Invalid_NilSignature
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = [@"dummy data" dataUsingEncoding:NSUTF8StringEncoding];
    QLFRendezvousAuthSignature *signature = nil;
    BOOL expectedValidity = NO;
    
    error = nil;
    BOOL signatureValid = [respondHelper isValidSignature:signature
                                           rendezvousData:rendezvousData
                                                    error:&error];
    XCTAssertEqual(signatureValid, expectedValidity);
}

- (void)testRespondHelper_Invalid_EmptySignature
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = [@"dummy data" dataUsingEncoding:NSUTF8StringEncoding];
    QLFRendezvousAuthSignature *signature = [respondHelper emptySignature];
    BOOL expectedValidity = NO;
    
    error = nil;
    BOOL signatureValid = [respondHelper isValidSignature:signature
                                           rendezvousData:rendezvousData
                                                    error:&error];
    XCTAssertEqual(signatureValid, expectedValidity);
}

- (void)testRespondHelper_Invalid_EmptySignatureData
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = [@"dummy data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *signatureData = [[NSData alloc] init];
    QLFRendezvousAuthSignature *signature = [QLFRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:signatureData];
    BOOL expectedValidity = NO;
    
    error = nil;
    BOOL signatureValid = [respondHelper isValidSignature:signature
                                           rendezvousData:rendezvousData
                                                    error:&error];
    XCTAssertEqual(signatureValid, expectedValidity);
}

- (void)testRespondHelper_Invalid_NilSignatureData
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = [@"dummy data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *signatureData = nil;
    QLFRendezvousAuthSignature *signature = [QLFRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:signatureData];
    BOOL expectedValidity = NO;
    
    error = nil;
    BOOL signatureValid = [respondHelper isValidSignature:signature
                                           rendezvousData:rendezvousData
                                                    error:&error];
    XCTAssertEqual(signatureValid, expectedValidity);
}

- (void)testRespondHelper_Invalid_IncorrectSignatureType
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = [@"dummy data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *signatureData = [[NSData alloc] init];
    QLFRendezvousAuthSignature *signature = [QLFRendezvousAuthSignature rendezvousAuthRSA2048_PEMWithSignature:signatureData];
    BOOL expectedValidity = NO;
    
    error = nil;
    BOOL signatureValid = [respondHelper isValidSignature:signature
                                           rendezvousData:rendezvousData
                                                    error:&error];
    XCTAssertEqual(signatureValid, expectedValidity);
}

- (void)testRespondHelper_Invalid_NilRendezvousData
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = self.publicKeyCertificateChainPem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:self.trustedRootPems
                                                            crlPems:self.crlPems
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = nil;
    QLFRendezvousAuthSignature *signature = [respondHelper emptySignature];
    BOOL expectedValidity = NO;
    
    error = nil;
    BOOL signatureValid = [respondHelper isValidSignature:signature
                                           rendezvousData:rendezvousData
                                                    error:&error];
    XCTAssertEqual(signatureValid, expectedValidity);
}

@end
