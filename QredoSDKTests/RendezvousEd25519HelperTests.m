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
    
    NSString *prefix = @"MyTestRendezVous@";
    
    error = nil;
    id<QredoRendezvousCreateHelper> signingHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       prefix:prefix
       crypto:self.cryptoImpl
       error:&error
       ];
    XCTAssertNotNil(signingHelper);
    XCTAssertNil(error);
    
    NSString *fullTag = [signingHelper tag];
    XCTAssertNotNil(fullTag);
    
    error = nil;
    id<QredoRendezvousRespondHelper> verificationHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       fullTag:fullTag
       crypto:self.cryptoImpl
       error:&error];
    XCTAssertNotNil(verificationHelper);
    XCTAssertNil(error);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [signingHelper signatureWithData:data error:&error];
    XCTAssertNotNil(signature);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [verificationHelper isValidSignature:signature rendezvousData:data error:&error];
    XCTAssert(result);
    XCTAssertNil(error);
    
}

- (void)testSignatureAndVerificationInvalidSignature {
    
    NSError *error = nil;
    
    NSString *prefix = @"MyTestRendezVous@";
    
    error = nil;
    id<QredoRendezvousCreateHelper> signingHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       prefix:prefix
       crypto:self.cryptoImpl
       error:&error
       ];
    XCTAssertNotNil(signingHelper);
    XCTAssertNil(error);
    
    NSString *fullTag = [signingHelper tag];
    XCTAssertNotNil(fullTag);
    
    error = nil;
    id<QredoRendezvousRespondHelper> verificationHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       fullTag:fullTag
       crypto:self.cryptoImpl
       error:&error];
    XCTAssertNotNil(verificationHelper);
    XCTAssertNil(error);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [signingHelper signatureWithData:data error:&error];
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
    BOOL result = [verificationHelper isValidSignature:forgedSignature rendezvousData:data error:&error];
    XCTAssertFalse(result);
    XCTAssertNil(error);
}

- (void)testSignatureAndVerificationNoPrefix {
    
    NSError *error = nil;
    
    NSString *prefix = nil;
    
    error = nil;
    id<QredoRendezvousCreateHelper> signingHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       prefix:prefix
       crypto:self.cryptoImpl
       error:&error
       ];
    XCTAssertNotNil(signingHelper);
    XCTAssertNil(error);
    
    NSString *fullTag = [signingHelper tag];
    XCTAssertNotNil(fullTag);
    
    error = nil;
    id<QredoRendezvousRespondHelper> verificationHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       fullTag:fullTag
       crypto:self.cryptoImpl
       error:&error];
    XCTAssertNotNil(verificationHelper);
    XCTAssertNil(error);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [signingHelper signatureWithData:data error:&error];
    XCTAssertNotNil(signature);
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [verificationHelper isValidSignature:signature rendezvousData:data error:&error];
    XCTAssert(result);
    XCTAssertNil(error);
    
}

- (void)testSignatureAndVerificationNoPrefixInvalidSignature {
    
    NSError *error = nil;
    
    NSString *prefix = nil;
    
    error = nil;
    id<QredoRendezvousCreateHelper> signingHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       prefix:prefix
       crypto:self.cryptoImpl
       error:&error
       ];
    XCTAssertNotNil(signingHelper);
    XCTAssertNil(error);
    
    NSString *fullTag = [signingHelper tag];
    XCTAssertNotNil(fullTag);
    
    id<QredoRendezvousRespondHelper> verificationHelper
    = [QredoRendezvousHelpers
       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
       fullTag:fullTag
       crypto:self.cryptoImpl
       error:&error];
    XCTAssertNotNil(verificationHelper);
    XCTAssertNil(error);
    
    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [signingHelper signatureWithData:data error:&error];
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
    BOOL result = [verificationHelper isValidSignature:forgedSignature rendezvousData:data error:&error];
    XCTAssertFalse(result);
    XCTAssertNil(error);
    
}

@end


