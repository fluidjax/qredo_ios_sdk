/* HEADER GOES HERE */
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoRendezvousHelpers.h"
#import "CryptoImplV1.h"
#import "QredoClient.h"
#import "QredoBase58.h"
#import "QredoXCTestCase.h"

@interface QredoRendezvousAnonymousHelperTests :QredoXCTestCase
@property (nonatomic) id<CryptoImpl> cryptoImpl;
@end

@implementation QredoRendezvousAnonymousHelperTests

-(void)setUp {
    [super setUp];
    
    self.cryptoImpl = [[CryptoImplV1 alloc] init];
}


-(void)tearDown {
    //Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void)testCreateAndRespondHelpers {
    NSError *error = nil;
    
    NSString *initialFullTag = @"AnonymousRendezvousTag";
    
    signDataBlock signingHandler = nil; //Must be nil as not used
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper.type,QredoRendezvousAuthenticationTypeAnonymous);
    
    NSString *createFullTag = [createHelper tag];
    XCTAssertNotNil(createFullTag);
    XCTAssertTrue([createFullTag isEqualToString:initialFullTag]);
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:createFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                              error:&error];
    XCTAssertNotNil(respondHelper);
    XCTAssertNil(error);
    XCTAssertEqual(respondHelper.type,QredoRendezvousAuthenticationTypeAnonymous);
    
    NSString *respondFullTag = [respondHelper tag];
    XCTAssertNotNil(respondFullTag);
    XCTAssert([respondFullTag isEqualToString:initialFullTag]);
    
    NSData *dataToSign = [@"The data to sign" dataUsingEncoding:NSUTF8StringEncoding];
    
    error = nil;
    QLFRendezvousAuthSignature *signature = [createHelper signatureWithData:dataToSign error:&error];
    XCTAssertNil(signature); //Anonymous rendezvous do not return signatures
    XCTAssertNil(error);
    
    error = nil;
    BOOL result = [respondHelper isValidSignature:signature rendezvousData:dataToSign error:&error];
    XCTAssertTrue(result); //Anonymous rendezvous always say signature is valid
    XCTAssertNil(error);
}


-(void)testCreateHelper_Valid_EmptyTag {
    NSError *error = nil;
    
    NSString *initialFullTag = @""; //Empty means generate new tag
    
    signDataBlock signingHandler = nil; //Must be nil as not used
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper1
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper1);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper1.type,QredoRendezvousAuthenticationTypeAnonymous);
    
    NSString *createFullTag1 = [createHelper1 tag];
    XCTAssertNotNil(createFullTag1);
    XCTAssertTrue(createFullTag1.length > 0);
    
    error = nil;
    NSData *originalTagData1 = [QredoBase58 decodeData:createFullTag1 error:&error];
    XCTAssertNotNil(originalTagData1);
    XCTAssertNil(error);
    XCTAssertEqual(originalTagData1.length,32);
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper2
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNotNil(createHelper2);
    XCTAssertNil(error);
    XCTAssertEqual(createHelper2.type,QredoRendezvousAuthenticationTypeAnonymous);
    
    NSString *createFullTag2 = [createHelper2 tag];
    XCTAssertNotNil(createFullTag2);
    XCTAssertTrue(createFullTag2.length > 0);
    
    error = nil;
    NSData *originalTagData2 = [QredoBase58 decodeData:createFullTag2 error:&error];
    XCTAssertNotNil(originalTagData2);
    XCTAssertNil(error);
    XCTAssertEqual(originalTagData2.length,32);
    
    //Can't really check for randomness, but can check that get different tags
    XCTAssertFalse([createFullTag1 isEqualToString:createFullTag2]);
    XCTAssertFalse([originalTagData1 isEqualToData:originalTagData2]);
}


-(void)testCreateHelper_Invalid_TagContainsAtSymbol {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    NSError *error = nil;
    
    NSString *initialFullTag = @"Anonymous@RendezvousTag"; //Invalid
    
    signDataBlock signingHandler = nil; //Must be nil as not used
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain,QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code,QredoRendezvousHelperErrorMalformedTag);
}


-(void)testCreateHelper_Invalid_MissingCrypto {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    NSError *error = nil;
    
    NSString *initialFullTag = @"AnonymousRendezvousTag";
    
    signDataBlock signingHandler = nil; //Must be nil as not used
    
    NSLog(@"*** The following 'Assertion failure' is intentional ***");
    
    XCTAssertThrows([QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                                          fullTag:initialFullTag
                                                                           crypto:nil
                                                                  trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                                          crlPems:nil //Nil is fine for Anonymous rendezvous
                                                                   signingHandler:signingHandler
                                                                            error:&error]);
}


-(void)testCreateHelper_Invalid_NilTag {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    NSError *error = nil;
    
    NSString *initialFullTag = nil; //Invalid
    
    signDataBlock signingHandler = nil; //Must be nil as not used
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain,QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code,QredoRendezvousHelperErrorMissingTag);
}


-(void)testCreateHelper_Invalid_NonNilSigningHandler {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    NSError *error = nil;
    
    NSString *initialFullTag = @"AnonymousRendezvousTag";
    
    signDataBlock signingHandler = ^NSData *(NSData *data,QredoRendezvousAuthenticationType authenticationType) {
        XCTAssertNotNil(data);
        //Contents of signing handler doesn't matter for this test, just that one is provided
        return nil;
    };
    
    error = nil;
    id<QredoRendezvousCreateHelper> createHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                     signingHandler:signingHandler
                                                              error:&error
       ];
    XCTAssertNil(createHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain,QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code,QredoRendezvousHelperErrorSignatureHandlerIncorrectlyProvided);
}


-(void)testRespondHelper_Invalid_EmptyTag {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    NSError *error = nil;
    
    NSString *initialFullTag = @"";
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                              error:&error
       ];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain,QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code,QredoRendezvousHelperErrorMissingTag);
}


-(void)testRespondHelper_Invalid_TagContainsAtSymbol {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    NSError *error = nil;
    
    NSString *initialFullTag = @"Anonymous@RendezvousTag"; //Invalid
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                              error:&error
       ];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain,QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code,QredoRendezvousHelperErrorMalformedTag);
}


-(void)testRespondHelper_Invalid_MissingCrypto {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    NSError *error = nil;
    
    NSString *initialFullTag = @"AnonymousRendezvousTag";
    
    NSLog(@"*** The following 'Assertion failure' is intentional ***");
    
    XCTAssertThrows([QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                                          fullTag:initialFullTag
                                                                           crypto:nil
                                                                  trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                                          crlPems:nil //Nil is fine for Anonymous rendezvous
                                                                            error:&error]);
}


-(void)testRespondHelper_Invalid_NilTag {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    NSError *error = nil;
    
    NSString *initialFullTag = nil; //Invalid
    
    error = nil;
    id<QredoRendezvousRespondHelper> respondHelper
    = [QredoRendezvousHelpers rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeAnonymous
                                                            fullTag:initialFullTag
                                                             crypto:self.cryptoImpl
                                                    trustedRootPems:nil //Nil is fine for Anonymous rendezvous
                                                            crlPems:nil //Nil is fine for Anonymous rendezvous
                                                              error:&error
       ];
    XCTAssertNil(respondHelper);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain,QredoRendezvousHelperErrorDomain);
    XCTAssertEqual(error.code,QredoRendezvousHelperErrorMissingTag);
}


@end
