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
#import "QredoLogging.h"
#import "QredoClient.h"
#import "QredoAuthenticatedRendezvousTag.h"

@interface QredoRendezvousRsa4096PemHelperTests : XCTestCase
@property (nonatomic) id<CryptoImpl> cryptoImpl;
@end

@implementation QredoRendezvousRsa4096PemHelperTests

- (void)setUp {
    [super setUp];

    // Must remove any existing keys before starting
    [QredoCrypto deleteAllKeysInAppleKeychain];
    
    self.cryptoImpl = [[CryptoImplV1 alloc] init];
}

- (void)tearDown {
    // Should remove any existing keys after finishing
    [QredoCrypto deleteAllKeysInAppleKeychain];

    [super tearDown];
}

// TODO: DH - see whether can make a common set of tests for RSA Authenticated Rendezvous, with key size/keys defined in child test (like HTTP/MQTT tests are?)

// TODO: DH - this method is used in other test files - move this somewhere common, to prevent duplication?
- (QredoSecKeyRefPair *)setupKeypairForPublicKeyData:(NSData *)publicKeyData privateKeyData:(NSData *)privateKeyData keySizeBits:(NSInteger)keySizeBits {
    
    // Import a known Public Key and Private Key into Keychain
    
    // NOTE: This will fail if the key has already been imported (even with different identifier)
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKeyImport1";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKeyImport1";
    
    XCTAssertNotNil(publicKeyData);
    NSLog(@"Public key (PKCS#1) data (%ld bytes): %@", publicKeyData.length, [QredoLogging hexRepresentationOfNSData:publicKeyData]);
    
    XCTAssertNotNil(privateKeyData);
    NSLog(@"Private key data (%ld bytes): %@", privateKeyData.length, [QredoLogging hexRepresentationOfNSData:privateKeyData]);
    
    SecKeyRef publicKeyRef = [QredoCrypto importPkcs1KeyData:publicKeyData
                                               keyLengthBits:keySizeBits
                                               keyIdentifier:publicKeyIdentifier
                                                   isPrivate:NO];
    XCTAssertTrue((__bridge id)publicKeyRef, @"Public Key import failed.");
    
    SecKeyRef privateKeyRef = [QredoCrypto importPkcs1KeyData:privateKeyData
                                                keyLengthBits:keySizeBits
                                                keyIdentifier:privateKeyIdentifier
                                                    isPrivate:YES];
    XCTAssertTrue((__bridge id)privateKeyRef, @"Private Key import failed.");
    
    QredoSecKeyRefPair *keyRefPair = [[QredoSecKeyRefPair alloc] initWithPublicKeyRef:publicKeyRef privateKeyRef:privateKeyRef];
    
    return keyRefPair;
}

- (void)testSignatureAndVerification_InternalKeys {
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeRsa4096Pem);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    XCTAssertEqual(respondHelper.type, QredoRendezvousAuthenticationTypeRsa4096Pem);
    
    NSString *respondFullTag = [respondHelper tag];
    XCTAssertNotNil(respondFullTag);
    XCTAssert([respondFullTag isEqualToString:finalFullTag]);

    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:signature rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerification_ExternalKeys {
    
    // Import a known Public Key and Private Key into Keychain
    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSInteger keySizeBits = 4096;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);

    NSData *publicKeyPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);

    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient4096Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);

    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeRsa4096Pem);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    XCTAssertEqual(respondHelper.type, QredoRendezvousAuthenticationTypeRsa4096Pem);
    
    NSString *respondFullTag = [respondHelper tag];
    XCTAssertNotNil(respondFullTag);
    XCTAssert([respondFullTag isEqualToString:finalFullTag]);

    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
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
    
    // Import a known Public Key and Private Key into Keychain
    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSInteger keySizeBits = 4096;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);
    
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);
    
    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient4096Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);
    
    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSError *error = nil;
    
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *prefix1 = @"MyTestRendezVous";
    NSString *initialFullTag1 = [NSString stringWithFormat:@"%@@%@", prefix1, authenticationTag];
    
    NSString *prefix2 = @"MyOtherTestRendezVous";
    NSString *initialFullTag2 = [NSString stringWithFormat:@"%@@%@", prefix2, authenticationTag];

    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    // Use 1st time
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper1
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag1
                                                             crypto:self.cryptoImpl
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
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag1
                                                             crypto:self.cryptoImpl
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
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag2
                                                             crypto:self.cryptoImpl
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
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:finalFullTag1
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper1);
    XCTAssertNil(error);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature1 = [createHelper1 signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature1);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper1 isValidSignature:signature1 rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    
    // Use 2nd time (same tag)
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper2
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:finalFullTag1
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper2);
    XCTAssertNil(error);
    
    error = nil;
    QredoRendezvousAuthSignature *signature2 = [createHelper2 signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature2);
    XCTAssertNil(error);
    
    error = nil;
    result = [respondHelper2 isValidSignature:signature2 rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    
    // Use 3rd time (different tag)
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper3
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:finalFullTag2
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper2);
    XCTAssertNil(error);
    
    error = nil;
    QredoRendezvousAuthSignature *signature3 = [createHelper2 signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature3);
    XCTAssertNil(error);
    
    error = nil;
    result = [respondHelper3 isValidSignature:signature3 rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerification_ExternalKeys_BadSigning {
    
    // Import a known Public Key and Private Key into Keychain
    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSInteger keySizeBits = 4096;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);
    
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);
    
    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient4096Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);
    
    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    // Generate an invalid signature (use incorrect salt length)
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = 10;
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeRsa4096Pem);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    XCTAssertEqual(respondHelper.type, QredoRendezvousAuthenticationTypeRsa4096Pem);
    
    NSString *respondFullTag = [respondHelper tag];
    XCTAssertNotNil(respondFullTag);
    XCTAssert([respondFullTag isEqualToString:finalFullTag]);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNil(signature);
    XCTAssertNotNil(error);
}

- (void)testEmptySignature
{
    // Import a known Public Key and Private Key into Keychain
    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSUInteger expectedEmptySignatureLength = 512; // 4048 bit keys produce 512 byte signatures
    NSInteger keySizeBits = 4096;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);
    
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);
    
    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient4096Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);
    
    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
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
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    // Get the empty signature from create helper
    QredoRendezvousAuthSignature *createHelperEmptySignature = [createHelper emptySignature];
    XCTAssertNotNil(createHelperEmptySignature);
    __block NSData *signatureData = nil;
    [createHelperEmptySignature ifX509_PEM:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } X509_PEM_SELFISGNED:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } ED25519:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } RSA2048_PEM:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } RSA4096_PEM:^(NSData *signature) {
        signatureData = signature;
    } other:^{
        XCTFail(@"Wrong signature type");
    }];
    
    XCTAssertNotNil(signatureData);
    XCTAssertEqual(signatureData.length, expectedEmptySignatureLength);
    
    // Get the empty signature from respond helper
    QredoRendezvousAuthSignature *respondHelperEmptySignature = [respondHelper emptySignature];
    XCTAssertNotNil(respondHelperEmptySignature);
    signatureData = nil;
    [respondHelperEmptySignature ifX509_PEM:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } X509_PEM_SELFISGNED:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } ED25519:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } RSA2048_PEM:^(NSData *signature) {
        XCTFail(@"Wrong signature type");
    } RSA4096_PEM:^(NSData *signature) {
        signatureData = signature;
    } other:^{
        XCTFail(@"Wrong signature type");
    }];
    
    XCTAssertNotNil(signatureData);
    XCTAssertEqual(signatureData.length, expectedEmptySignatureLength);
    
    // Empty signatures from create and respond helpers should be equal
    NSComparisonResult comparisonResult = [createHelperEmptySignature compare:respondHelperEmptySignature];
    XCTAssertEqual(comparisonResult, NSOrderedSame);
}

- (void)testCreateHelper_Invalid_MissingCrypto
{
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    id<CryptoImpl> crypto = nil;
    
    
    error = nil;
    
    XCTAssertThrows([QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                                          fullTag:initialFullTag
                                                                           crypto:crypto
                                                                   signingHandler:signingHandler
                                                                            error:&error]);
}

- (void)testCreateHelper_Invalid_NilTag
{
    NSError *error = nil;
    NSString *initialFullTag = nil;
    signDataBlock signingHandler = nil; // Using internally generated keys

    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
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
    NSString *initialFullTag = nil;
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testCreateHelper_Invalid_MultipleAtsInTag
{
    NSError *error = nil;
    NSString *initialFullTag = @"@@";
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
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
    NSString *initialFullTag = TestKeyJavaSdkClient4096Pem; // No @ prior to authentication tag
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
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
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem; // External keys, needs a signing handler
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorSignatureHandlerMissing);
}

- (void)testCreateHelper_Invalid_InternalKeysYetProvidedSigningHandler
{
    NSError *error = nil;
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally (so signing handler must be nil)
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        // Contents of signing handler doesn't matter for this test, just that one is provided
        return nil;
    };
    
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorSignatureHandlerIncorrectlyProvided);
}

- (void)testCreateHelperSigning_Invalid_NilDataToSign
{
    // Import a known Public Key and Private Key into Keychain
    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSInteger keySizeBits = 4096;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);
    
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);
    
    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient4096Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);
    
    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeRsa4096Pem);
    
    NSData *dataToSign = nil;
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNil(signature);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingDataToSign);
}

- (void)testCreateHelperSigning_Invalid_ExternalKeysSignerReturnsNil
{
    // Import a known Public Key and Private Key into Keychain
    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSInteger keySizeBits = 4096;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient4096X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient4096X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);
    
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);
    
    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient4096Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient4096Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);
    
    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);

        // Return a nil signature
        return nil;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeRsa4096Pem);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNil(signature);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorBadSignature);
}

- (void)testRespondHelper_Invalid_MissingCrypto
{
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<CryptoImpl> crypto = nil;
    
    
    error = nil;
    
    XCTAssertThrows([QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                                          fullTag:initialFullTag
                                                                           crypto:crypto
                                                                            error:&error]);
}

- (void)testRespondHelper_Invalid_NilTag
{
    NSError *error = nil;
    NSString *initialFullTag = nil;
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testRespondHelper_Invalid_EmptyTag
{
    NSError *error = nil;
    NSString *initialFullTag = nil;
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testRespondHelper_Invalid_MultipleAtsInTag
{
    NSError *error = nil;
    NSString *initialFullTag = @"@@";
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testRespondHelper_Invalid_MissingAtFromStartOfAuthenticationTag
{
    NSError *error = nil;
    NSString *initialFullTag = TestKeyJavaSdkClient4096Pem; // No @ prior to authentication tag
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
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
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = [@"dummy data" dataUsingEncoding:NSUTF8StringEncoding];
    QredoRendezvousAuthSignature *signature = nil;
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
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = [@"dummy data" dataUsingEncoding:NSUTF8StringEncoding];
    QredoRendezvousAuthSignature *signature = [respondHelper emptySignature];
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
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = [@"dummy data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *signatureData = [[NSData alloc] init];
    QredoRendezvousAuthSignature *signature = [QredoRendezvousAuthSignature rendezvousAuthRSA4096_PEMWithSignature:signatureData];
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
    NSString *authenticationTag = TestKeyJavaSdkClient4096Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *rendezvousData = nil;
    QredoRendezvousAuthSignature *signature = [respondHelper emptySignature];
    BOOL expectedValidity = NO;
    
    error = nil;
    BOOL signatureValid = [respondHelper isValidSignature:signature
                                           rendezvousData:rendezvousData
                                                    error:&error];
    XCTAssertEqual(signatureValid, expectedValidity);
}

// TODO: DH - add test using incorrect key length (e.g. 2048 bit). Unsure whether can detect yet.

@end
