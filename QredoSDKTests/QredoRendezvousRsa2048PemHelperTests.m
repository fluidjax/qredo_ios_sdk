/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
// TODO: DH - check whether all these are needed
#import "QredoRendezvousHelpers.h"
#import "QredoCrypto.h"
#import "CryptoImplV1.h"
#import "TestCertificates.h"
#import "QredoCertificateUtils.h"
#import "QredoLogging.h"
#import "QredoSecKeyRefPair.h"

@interface QredoRendezvousRsa2048PemHelperTests : XCTestCase
@property (nonatomic) id<CryptoImpl> cryptoImpl;
@end

@implementation QredoRendezvousRsa2048PemHelperTests

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

// TODO: DH - this method is used in other tests - move this somewhere common, to prevent duplication?
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
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
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
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
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
    XCTAssertTrue(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerification_ExternalKeys {
    
    // Import a known Public Key and Private Key into Keychain
    // NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSInteger keySizeBits = 2048;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient2048X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient2048X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);

    NSData *publicKeyPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);

    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient2048Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient2048Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);

    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = TestKeyJavaSdkClient2048Pem;
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
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
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
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
    NSInteger keySizeBits = 2048;
    
    NSData *publicKeyX509Data = [NSData dataWithBytes:TestPubKeyJavaSdkClient2048X509DerArray
                                               length:sizeof(TestPubKeyJavaSdkClient2048X509DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(publicKeyX509Data);
    
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils convertX509PublicKeyToPkcs1PublicKey:publicKeyX509Data];
    XCTAssertNotNil(publicKeyPkcs1Data);
    
    NSData *privateKeyData = [NSData dataWithBytes:TestPrivKeyJavaSdkClient2048Pkcs1DerArray
                                            length:sizeof(TestPrivKeyJavaSdkClient2048Pkcs1DerArray) / sizeof(uint8_t)];
    XCTAssertNotNil(privateKeyData);
    
    QredoSecKeyRefPair *keyRefPair = [self setupKeypairForPublicKeyData:publicKeyPkcs1Data
                                                         privateKeyData:privateKeyData
                                                            keySizeBits:keySizeBits];
    XCTAssertNotNil(keyRefPair);
    
    NSError *error = nil;
    
    NSString *authenticationTag = TestKeyJavaSdkClient2048Pem;
    NSString *prefix1 = @"MyTestRendezVous";
    NSString *initialFullTag1 = [NSString stringWithFormat:@"%@@%@", prefix1, authenticationTag];
    
    NSString *prefix2 = @"MyOtherTestRendezVous";
    NSString *initialFullTag2 = [NSString stringWithFormat:@"%@@%@", prefix2, authenticationTag];

    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSInteger saltLength = [QredoRendezvousHelpers saltLengthForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem];
        NSData *signature = [QredoCrypto rsaPssSignMessage:data saltLength:saltLength keyRef:keyRefPair.privateKeyRef];
        XCTAssertNotNil(signature);
        return signature;
    };
    
    // Use 1st time
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper1
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
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
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
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
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
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
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
                                                            fullTag:finalFullTag1
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper1);
    XCTAssertNil(error);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature1 = [createHelper1 signatureWithData:data error:&error];
    XCTAssertNotNil(signature1);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper1 isValidSignature:signature1 rendezvousData:data error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    
    // Use 2nd time (same tag)
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper2
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
                                                            fullTag:finalFullTag1
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper2);
    XCTAssertNil(error);
    
    error = nil;
    QredoRendezvousAuthSignature *signature2 = [createHelper2 signatureWithData:data error:&error];
    XCTAssertNotNil(signature2);
    XCTAssertNil(error);
    
    error = nil;
    result = [respondHelper2 isValidSignature:signature2 rendezvousData:data error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    
    // Use 3rd time (different tag)
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper3
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
                                                            fullTag:finalFullTag2
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper2);
    XCTAssertNil(error);
    
    error = nil;
    QredoRendezvousAuthSignature *signature3 = [createHelper2 signatureWithData:data error:&error];
    XCTAssertNotNil(signature3);
    XCTAssertNil(error);
    
    error = nil;
    result = [respondHelper3 isValidSignature:signature3 rendezvousData:data error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
}
@end
