/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoRendezvousHelpers.h"
#import "QredoCrypto.h"
#import "CryptoImplV1.h"
#import "TestCertificates.h"
//#import "QredoCertificateUtils.h"

@interface QredoRendezvousRsa2048PemHelperTests : XCTestCase
@property (nonatomic) id<CryptoImpl> cryptoImpl;
@end

@implementation QredoRendezvousRsa2048PemHelperTests

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
    
//    error = nil;
//    id<QredoRendezvousRespondHelper> respondHelper
//    = [QredoRendezvousHelpers
//       rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
//       fullTag:finalFullTag
//       crypto:self.cryptoImpl
//       error:&error];
//    XCTAssertNotNil(respondHelper);
//    XCTAssertNil(error);
//    
//    NSData *data = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
//    
//    error = nil;
//    QredoRendezvousAuthSignature *signature = [createHelper signatureWithData:data error:&error];
//    XCTAssertNotNil(signature);
//    XCTAssertNil(error);
//    
//    error = nil;
//    BOOL result = [respondHelper isValidSignature:signature rendezvousData:data error:&error];
//    XCTAssert(result);
//    XCTAssertNil(error);
}

@end
