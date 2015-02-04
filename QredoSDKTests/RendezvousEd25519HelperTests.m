/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "CryptoImplV1.h"
#import "QredoRendezvousHelpers.h"
#import "QredoRendezvousEd25519Helper.h"
#import "QredoClient.h"

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


@interface RendezvousEd25519HelperTests : XCTestCase
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

- (void)testSignatureAndVerification {
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
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
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
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

- (void)testSignatureAndVerificationSeveralAtCharsInPrefix {
    
    NSError *error = nil;
    
    // TODO: DH - check this test still does what was originally intended now full tag, not prefix is provided
//    NSString *prefix = @"MyTestRendez@Vous@";
    NSString *prefix = @"MyTestRendez@Vous@";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys

    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
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
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
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

- (void)testSignatureAndVerificationNoAtCharsAtTheEndOfPrefix {
    
    NSError *error = nil;
    
    // TODO: DH - check this test still does what was originally intended now full tag, not prefix is provided
//    NSString *prefix = @"MyTestRendez@Vous";
    NSString *prefix = @"MyTestRendez@Vous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
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
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
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

- (void)testSignatureAndVerificationInvalidSignature {
    
    NSError *error = nil;
    
    // TODO: DH - check this test still does what was originally intended now full tag, not prefix is provided
//    NSString *prefix = @"MyTestRendezVous@";
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       fullTag:initialFullTag
       crypto:self.cryptoImpl
       signingHandler:signingHandler
       error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
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
    
    __block NSData *signatureData = nil;
    [signature
     ifX509_PEM:^(NSData *signature) {
         XCTFail();
     } X509_PEM_SELFISGNED:^(NSData *signature) {
         XCTFail();
     } ED25519:^(NSData *signature) {
         signatureData = signature;
     } RSA2048_PEM:^(NSData *signature) {
         XCTFail();
     } RSA4096_PEM:^(NSData *signature) {
         XCTFail();
     } other:^{
         XCTFail();
     }];
    XCTAssertGreaterThan([signatureData length], 0);
    
    NSMutableData *forgedSignatureData = [signatureData mutableCopy];
    unsigned char *forgedSignatureDataBytes = [forgedSignatureData mutableBytes];
    forgedSignatureDataBytes[0] = ~forgedSignatureDataBytes[0];
    
    QredoRendezvousAuthSignature *forgedSignature = [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:forgedSignatureData];
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:forgedSignature rendezvousData:data error:&error];
    XCTAssertFalse(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerificationNoPrefix {
    
    NSError *error = nil;
    
    NSString *prefix = @"";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       fullTag:initialFullTag
       crypto:self.cryptoImpl
       signingHandler:signingHandler
       error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    XCTAssertFalse([finalFullTag hasPrefix:@"@"]);

    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
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

- (void)testSignatureAndVerificationNoPrefixInvalidSignature {
    
    NSError *error = nil;
    
    // TODO: DH - check this test still does what was originally intended now full tag, not prefix is provided
//    NSString *prefix = nil;
    // TODO: DH - nil full tag - that should be an error?
    NSString *initialFullTag = nil;
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       fullTag:initialFullTag
       crypto:self.cryptoImpl
       signingHandler:signingHandler
       error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    
    NSString *finalFullTag = [createHelper tag];
    XCTAssertNotNil(finalFullTag);
    
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
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
    
    
    __block NSData *signatureData = nil;
    [signature
     ifX509_PEM:^(NSData *signature) {
         XCTFail();
     } X509_PEM_SELFISGNED:^(NSData *signature) {
         XCTFail();
     } ED25519:^(NSData *signature) {
         signatureData = signature;
     } RSA2048_PEM:^(NSData *signature) {
         XCTFail();
     } RSA4096_PEM:^(NSData *signature) {
         XCTFail();
     } other:^{
         XCTFail();
     }];
    XCTAssertGreaterThan([signatureData length], 0);
    
    NSMutableData *forgedSignatureData = [signatureData mutableCopy];
    unsigned char *forgedSignatureDataBytes = [forgedSignatureData mutableBytes];
    forgedSignatureDataBytes[0] = ~forgedSignatureDataBytes[0];
    
    QredoRendezvousAuthSignature *forgedSignature = [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:forgedSignatureData];
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:forgedSignature rendezvousData:data error:&error];
    XCTAssertFalse(result);
    XCTAssertNil(error);
    
}

- (void)testCreateHelperMissingCrypto
{
    NSError *error = nil;
    
    // TODO: DH - check this test still does what was originally intended now full tag, not prefix is provided
//    NSString *prefix = @"MyTestRendezVous@";
    NSString *prefix = @"MyTestRendezVous";
    NSString *authenticationTag = @""; // No authentication tag = Generate keys internally
    NSString *initialFullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
    
    signDataBlock signingHandler = nil; // Using internally generated keys
    
    XCTAssertThrows([QredoRendezvousHelpers
                     rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                     fullTag:initialFullTag
                     crypto:nil
                     signingHandler:signingHandler
                     error:&error
                     ]);
    
}

- (void)testRespondHelperMissingCrypto
{
    NSError *error = nil;
    
    XCTAssertThrows([QredoRendezvousHelpers
                     rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                     fullTag:@"someTag@"
                     crypto:nil
                     error:&error]);
}

- (void)testRespondHelperMissingTag
{
    NSError *error = nil;
    
    id helper = [QredoRendezvousHelpers
                     rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                     fullTag:nil
                     crypto:self.cryptoImpl
                     error:&error];
    
    XCTAssertNil(helper);
    XCTAssert(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

@end


