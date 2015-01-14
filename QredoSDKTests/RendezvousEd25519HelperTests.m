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
    
    NSString *prefix = @"MyTestRendezVous@";
    
    id<QredoRendezvousHelper> signingHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       tag:prefix
       crypto:self.cryptoImpl
       ];
    XCTAssertNotNil(signingHelper);
    
    NSString *fullTag = [signingHelper tag];
    XCTAssertNotNil(fullTag);
    
    id<QredoRendezvousHelper> verificationHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       tag:fullTag
       crypto:self.cryptoImpl];
    XCTAssertNotNil(verificationHelper);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    QredoRendezvousAuthSignature *signature = [signingHelper signatureWithData:data];
    XCTAssertNotNil(signature);
    
    BOOL result = [verificationHelper isValidSignature:signature rendezvousData:data];
    XCTAssert(result);
    
}

- (void)testSignatureAndVerificationInvalidSignature {
    
    NSString *prefix = @"MyTestRendezVous@";
    
    id<QredoRendezvousHelper> signingHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       tag:prefix
       crypto:self.cryptoImpl
       ];
    XCTAssertNotNil(signingHelper);
    
    NSString *fullTag = [signingHelper tag];
    XCTAssertNotNil(fullTag);
    
    id<QredoRendezvousHelper> verificationHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       tag:fullTag
       crypto:self.cryptoImpl];
    XCTAssertNotNil(verificationHelper);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    QredoRendezvousAuthSignature *signature = [signingHelper signatureWithData:data];
    XCTAssertNotNil(signature);
    
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
    
    
    BOOL result = [verificationHelper isValidSignature:forgedSignature rendezvousData:data];
    XCTAssertFalse(result);
}

- (void)testSignatureAndVerificationNoPrefix {
    
    NSString *prefix = nil;
    
    id<QredoRendezvousHelper> signingHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       tag:prefix
       crypto:self.cryptoImpl
       ];
    XCTAssertNotNil(signingHelper);
    
    NSString *fullTag = [signingHelper tag];
    XCTAssertNotNil(fullTag);
    
    id<QredoRendezvousHelper> verificationHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       tag:fullTag
       crypto:self.cryptoImpl];
    XCTAssertNotNil(verificationHelper);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    QredoRendezvousAuthSignature *signature = [signingHelper signatureWithData:data];
    XCTAssertNotNil(signature);
    
    BOOL result = [verificationHelper isValidSignature:signature rendezvousData:data];
    XCTAssert(result);
    
}

- (void)testSignatureAndVerificationNoPrefixInvalidSignature {
    
    NSString *prefix = nil;
    
    id<QredoRendezvousHelper> signingHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       tag:prefix
       crypto:self.cryptoImpl
       ];
    XCTAssertNotNil(signingHelper);
    
    NSString *fullTag = [signingHelper tag];
    XCTAssertNotNil(fullTag);
    
    id<QredoRendezvousHelper> verificationHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       tag:fullTag
       crypto:self.cryptoImpl];
    XCTAssertNotNil(verificationHelper);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    QredoRendezvousAuthSignature *signature = [signingHelper signatureWithData:data];
    XCTAssertNotNil(signature);
    
    
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
    
    
    BOOL result = [verificationHelper isValidSignature:forgedSignature rendezvousData:data];
    XCTAssertFalse(result);
    
}

@end


