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

@interface QredoRendezvousX509PemHelperTests : XCTestCase
@property (nonatomic) id<CryptoImpl> cryptoImpl;
@property (nonatomic, strong) NSArray *rootCertificates;
@end

@implementation QredoRendezvousX509PemHelperTests

- (void)setUp {
    [super setUp];
    
    // Java-SDK root cert
    NSString *rootCertificatesPemString = TestCertJavaSdkRootPem;
    int expectedNumberOfRootCertificateRefs = 1;

    self.rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    XCTAssertNotNil(self.rootCertificates, @"Root certificates should not be nil.");
    XCTAssertEqual(self.rootCertificates.count, expectedNumberOfRootCertificateRefs, @"Wrong number of root certificate refs returned.");
    
    self.cryptoImpl = [[CryptoImplV1 alloc] initWithTrustedRootRefs:self.rootCertificates];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSignatureAndVerification_ExternalKeys {
    
    // Import some PKCS#12 data and then get the certificate chain refs from the identity.
    // Use SecCertificateRefs to create a PEM which is then processed (to confirm validity)
    
    
    // 1.) Create identity - Test client 2048 certificate + priv key from Java-SDK, with intermediate cert
    NSData *pkcs12Data = [NSData dataWithBytes:TestCertJavaSdkClient4096WithIntermediatePkcs12Array
                                        length:sizeof(TestCertJavaSdkClient4096WithIntermediatePkcs12Array) / sizeof(uint8_t)];
    NSString *pkcs12Password = @"password";
    int expectedNumberOfChainCertificateRefs = 2;
    
    
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data
                                                                                             password:pkcs12Password
                                                                                  rootCertificateRefs:self.rootCertificates];
    XCTAssertNotNil(identityDictionary, @"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,
                                                                      kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef, @"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");

    SecKeyRef privateKeyRef = [QredoCrypto getPrivateKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)privateKeyRef);
    
    // 2.) Create Certificate Refs from Identity Dictionary and convert to PEM string
    NSArray *certificateChainRefs = (NSArray *)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,
                                                                    kSecImportItemCertChain);
    XCTAssertNotNil(certificateChainRefs, @"Incorrect identity validation result dictionary contents. Should contain valid certificate chain array.");
    XCTAssertEqual(certificateChainRefs.count, expectedNumberOfChainCertificateRefs, @"Incorrect identity validation result dictionary contents. Should contain expected number of certificate chain refs.");
    NSString *pemCertificateChain = [QredoCertificateUtils convertCertificateRefsToPemCertificate:certificateChainRefs];
    XCTAssertNotNil(pemCertificateChain);
    
    // 3.) Actual test - Create the create helper, and then the respond helper
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = pemCertificateChain;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    NSError *error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    XCTAssert([finalFullTag hasSuffix:pemCertificateChain]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [createHelper signatureWithData:data error:&error];
    XCTAssertNotNil(signature);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:signature rendezvousData:data error:&error];
    XCTAssert(result);
    XCTAssertNil(error);
}

- (void)testCreateHelper_Invalid_InternalKeys {
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally (not valid for X509)
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), so just return the input data
        return data;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeX509Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorAuthenticationTagMissing);
    

}


@end
