/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "CryptoImplV1.h"
#import "QredoRendezvousHelpers.h"
#import "QredoRendezvousEd25519Helper.h"
#import "QredoClient.h"
#import "QredoAuthenticatedRendezvousTag.h"
#import "QredoBase58.h"
#import "QredoXCTestCase.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


@interface RendezvousEd25519HelperTests : QredoXCTestCase
@property (nonatomic) id<CryptoImpl> cryptoImpl;
@end

@implementation RendezvousEd25519HelperTests

- (void)setUp {
    [super setUp];
    self.cryptoImpl = [[CryptoImplV1 alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSignatureAndVerification_InternalKeys {
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
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

- (void)testSignatureAndVerification_ExternalKeys {
    
    __block NSError *error = nil;
    
    // Generate a keypair
    QredoED25519SigningKey *signingKey = [self.cryptoImpl qredoED25519SigningKey];
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = [QredoBase58 encodeData:signingKey.verifyKey.data];
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        NSData *signature = [self.cryptoImpl qredoED25519SignMessage:data withKey:signingKey error:&error];
        XCTAssertNotNil(signature);
        XCTAssertNil(error);
        return signature;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssert([finalFullTag hasPrefix:prefix]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
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

- (void)testCreateHelper_Invalid_SeveralAtCharsInTag {
    
    NSError *error = nil;

    // Multiple @ characters is invalid
    NSString *initialFullTag = @"MyTestRendez@Vous@"; // No authentication tag part = Generate keys internally
    
    signDataBlock signingHandler = nil; // Using internally generated keys

    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testCreateHelper_Invalid_ExternalKeysMissingSigningHandler
{
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezvous";
    NSString *authenticationTag = @"6Y7GUKrxESa1WYLL5kkVaUNyVisjW8dmH1x2jVhabuF9";
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorSignatureHandlerMissing);
}

- (void)testCreateHelper_InvalidAuthenticationTagPart
{
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendez";
    NSString *authenticationTag = @"Vous";
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];

    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        // This block shouldn't be called (due to validation errors), we just need a valid block (so just return input)
        return data;
    };

    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorAuthenticationTagInvalid);
}

- (void)testSignatureAndVerificationInvalidSignature
{
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QLFRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNotNil(signature);
    XCTAssertNil(error);
    
    __block NSData *signatureData = nil;

    [signature ifRendezvousAuthX509_PEM:^(NSData *signature) {
         XCTFail();
    } ifRendezvousAuthX509_PEM_SELFSIGNED:^(NSData *signature) {
         XCTFail();
    } ifRendezvousAuthED25519:^(NSData *signature) {
         signatureData = signature;
    } ifRendezvousAuthRSA2048_PEM:^(NSData *signature) {
         XCTFail();
    } ifRendezvousAuthRSA4096_PEM:^(NSData *signature) {
         XCTFail();
    }];

    XCTAssertGreaterThan([signatureData length], 0);
    
    NSMutableData *forgedSignatureData = [signatureData mutableCopy];
    unsigned char *forgedSignatureDataBytes = [forgedSignatureData mutableBytes];
    forgedSignatureDataBytes[0] = ~forgedSignatureDataBytes[0];
    
    QLFRendezvousAuthSignature *forgedSignature = [QLFRendezvousAuthSignature rendezvousAuthED25519WithSignature:forgedSignatureData];
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:forgedSignature rendezvousData:dataToSign error:&error];
    XCTAssertFalse(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerificationNoPrefixAndNoAuthenticationTag {
    
    NSError *error = nil;

    // No prefix and no authentication tag (Note: resultant tag should have preceeding @ even if no prefix provided)
    NSString *initialFullTag = @"@"; // No authentication tag part = Generate keys internally
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssertTrue([finalFullTag hasPrefix:@"@"]);

    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:finalFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    
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

- (void)testCreateHelper_Invalid_NilTag
{
    NSString *initialFullTag = nil;
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    NSError *error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error];

    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testCreateHelper_Invalid_MissingCrypto
{
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    XCTAssertThrows([QredoRendezvousHelpers
                     rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                     fullTag:initialFullTag
                     crypto:nil
                     trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                     crlPems:nil // Nil is fine for Ed25519 rendezvous
                     signingHandler:signingHandler
                     error:&error]);
    
}

- (void)testRespondHelper_Invalid_MissingCrypto
{
    NSError *error = nil;
    
    XCTAssertThrows([QredoRendezvousHelpers
                     rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                     fullTag:@"someTag@"
                     crypto:nil
                     trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                     crlPems:nil // Nil is fine for Ed25519 rendezvous
                     error:&error]);
}

- (void)testRespondHelper_Invalid_MissingTag
{
    NSError *error = nil;
    
    id helper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:nil
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    
    XCTAssertNil(helper);
    XCTAssert(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testRespondHelper_Invalid_SeveralAtCharsInTag {
    
    NSError *error = nil;
    
    // Multiple @ characters is invalid
    NSString *initialFullTag = @"MyTestRendez@Vous@"; // No authentication tag part = Generate keys internally
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testRespondHelper_Valid_NoPrefixTag {
    
    NSError *error = nil;
    
    NSString *initialFullTag = @"@AZVZXcTD5Qw6x6goPoRbfifq6MaHJys4xmmyEKozpact";
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
}

- (void)testRespondHelper_Valid_WithPrefixTag {
    
    NSError *error = nil;
    
    NSString *initialFullTag = @"prefix@AZVZXcTD5Qw6x6goPoRbfifq6MaHJys4xmmyEKozpact";
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
}

- (void)testRespondHelper_Invalid_MissingAtFromStartOfTag {
    
    NSError *error = nil;

    // Missing @ means an unauthenticated (anonymous) rendezvous
    NSString *initialFullTag = @"AZVZXcTD5Qw6x6goPoRbfifq6MaHJys4xmmyEKozpact";
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoAuthenticatedRendezvousTagErrorDomain);
    XCTAssertEqual(error.code, QredoAuthenticatedRendezvousTagErrorMalformedTag);
}

- (void)testRespondHelper_Invalid_BadCharsInTag
{
    NSError *error = nil;
    
    // Invalid base58 chars
    NSString *initialFullTag = @"test@1234567890123456789012345678901234567890tv+-";
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil // Nil is fine for Ed25519 rendezvous
                                                            crlPems:nil // Nil is fine for Ed25519 rendezvous
                                                              error:&error];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMalformedTag);
}

@end


