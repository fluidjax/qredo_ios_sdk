/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoRendezvousHelpers.h"
#import "CryptoImplV1.h"
#import "QredoClient.h"

@interface QredoRendezvousAnonymousHelperTests : XCTestCase
@property (nonatomic) id<CryptoImpl> cryptoImpl;
@end

@implementation QredoRendezvousAnonymousHelperTests

- (void)setUp {
    [super setUp];
    
    self.cryptoImpl = [[CryptoImplV1 alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCreateAndRespondHelpers
{
    NSError *error = nil;
    
    NSString *initialFullTag = @"AnonymousRendezvousTag";
    
    signDataBlock signingHandler = nil; // Must be nil as not used
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeAnonymous);
    
    NSString *createFullTag = [createHelper tag];
    XCTAssertNotNil(createFullTag);
    XCTAssertTrue([createFullTag isEqualToString:initialFullTag]);

    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:createFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    XCTAssertEqual(respondHelper.type, QredoRendezvousAuthenticationTypeAnonymous);

    NSString *respondFullTag = [respondHelper tag];
    XCTAssertNotNil(respondFullTag);
    XCTAssert([respondFullTag isEqualToString:initialFullTag]);

    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QredoRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNil(signature); // Anonymous rendezvous do not return signatures
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:signature rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result); // Anonymous rendezvous always say signature is valid
    XCTAssertNil(error);
}

- (void)testCreateHelper_Valid_EmptyTag
{
    NSError *error = nil;
    
    NSString *initialFullTag = @""; // Empty means generate new tag
    
    signDataBlock signingHandler = nil; // Must be nil as not used
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type, QredoRendezvousAuthenticationTypeAnonymous);
    
    NSString *createFullTag = [createHelper tag];
    XCTAssertNotNil(createFullTag);
    XCTAssertTrue(createFullTag.length > 0);
    // TODO: DH - check that it is valid base58 (once that's complete)
    // TODO: DH - check un-base58 encoding is 32byte long
}

- (void)testCreateHelper_Invalid_MissingCrypto
{
    NSError *error = nil;
    
    NSString *initialFullTag = @"AnonymousRendezvousTag";
    
    signDataBlock signingHandler = nil; // Must be nil as not used
    
    XCTAssertThrows([QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                                          fullTag:initialFullTag
                                                                           crypto:nil
                                                                   signingHandler:signingHandler
                                                                            error:&error]);
}

- (void)testCreateHelper_Invalid_NilTag
{
    NSError *error = nil;
    
    NSString *initialFullTag = nil; // Invalid
    
    signDataBlock signingHandler = nil; // Must be nil as not used
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
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

- (void)testCreateHelper_Invalid_NonNilSigningHandler
{
    NSError *error = nil;
    
    NSString *initialFullTag = @"AnonymousRendezvousTag";
    
    signDataBlock signingHandler = ^NSData *(NSData *data, QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        // Contents of signing handler doesn't matter for this test, just that one is provided
        return nil;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
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

- (void)testRespondHelper_Invalid_EmptyTag
{
    NSError *error = nil;
    
    NSString *initialFullTag = @"";
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error
       ];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

- (void)testRespondHelper_Invalid_MissingCrypto
{
    NSError *error = nil;
    
    NSString *initialFullTag = @"AnonymousRendezvousTag";
    
    XCTAssertThrows([QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                                          fullTag:initialFullTag
                                                                           crypto:nil
                                                                            error:&error]);
}

- (void)testRespondHelper_Invalid_NilTag
{
    NSError *error = nil;
    
    NSString *initialFullTag = nil; // Invalid
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                              error:&error
       ];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code, QredoRendezvousHelperErrorMissingTag);
}

@end
