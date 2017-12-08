/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoTransport.h"
#import "QredoHttpTransport.h"
#import "MasterConfig.h"


@interface QredoTransportTests :XCTestCase

@end

@implementation QredoTransportTests

-(void)setUp {
    [super setUp];
    //Put setup code here. This method is called before the invocation of each test method in the class.
}


-(void)tearDown {
    //Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void)testTransportForServiceURL_HTTPLowercase {
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoTransport *transport = [QredoTransport transportForServiceURL:serviceURL];
    
    XCTAssertNotNil(transport,@"Transport should not be nil.");
    XCTAssertTrue([transport isKindOfClass:[QredoHttpTransport class]]);
}


-(void)testTransportForServiceURL_HTTPUppercase {
    NSURL *serviceURL = [NSURL URLWithString:@"HTTP://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoTransport *transport = [QredoTransport transportForServiceURL:serviceURL];
    
    XCTAssertNotNil(transport,@"Transport should not be nil.");
    XCTAssertTrue([transport isKindOfClass:[QredoHttpTransport class]]);
}


-(void)testTransportForServiceURL_UnsupportedFTP {
    NSURL *serviceURL = [NSURL URLWithString:@"ftp://test.host.qredo.com:8765/path/to/somewhere"];
    
    XCTAssertThrowsSpecificNamed([QredoTransport transportForServiceURL:serviceURL],NSException,NSInvalidArgumentException,@"Passed in unsupported URL scheme but NSInvalidArgumentException not thrown.");
}


-(void)testInit_CannotBeCalledDirectly {
    NSLog(@"*** The following 'Assertion failure' is intentional ***");
    XCTAssertThrowsSpecificNamed([[QredoTransport alloc] init],NSException,NSInternalInconsistencyException,@"Called 'init' on base QredoTransport class but NSInternalInconsistencyException not thrown.");
}


-(void)testInitWithServiceURL {
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoTransport *transport = [[QredoTransport alloc] initWithServiceURL:serviceURL];
    
    XCTAssertNotNil(transport,@"Transport should not be nil.");
}


-(void)testCanHandleServiceURL_HTTP {
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];
    
    BOOL canHandle = [QredoTransport canHandleServiceURL:serviceURL];
    
    XCTAssertTrue(canHandle,@"Transport should be able to handle provided service URL");
}


-(void)testCanHandleServiceURL_Unsupported {
    NSURL *serviceURL = [NSURL URLWithString:@"mailto://test.host.qredo.com:8765/path/to/somewhere"];
    
    BOOL canHandle = [QredoTransport canHandleServiceURL:serviceURL];
    
    XCTAssertFalse(canHandle,@"Transport should not be able to handle provided service URL");
}


-(void)testSupportsMultiResponse_MustOverride {
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoTransport *transport = [[QredoTransport alloc] initWithServiceURL:serviceURL];
    
    XCTAssertNotNil(transport,@"Transport should not be nil.");
    
    XCTAssertThrowsSpecificNamed([transport supportsMultiResponse],NSException,NSInternalInconsistencyException,@"Called 'supportsMultiResponse' on base QredoTransport class but NSInternalInconsistencyException not thrown.");
}


-(void)testSend_MustOverride {
    NSURL *serviceURL = [NSURL URLWithString:TEST_HTTP_SERVICE_URL];
    
    QredoTransport *transport = [[QredoTransport alloc] initWithServiceURL:serviceURL];
    
    XCTAssertNotNil(transport,@"Transport should not be nil.");
    
    //Use a non-nil payload
    NSData *payload = [[NSData alloc] init];
    id userData = nil;
    
    XCTAssertThrowsSpecificNamed([transport send:payload userData:userData],NSException,NSInternalInconsistencyException,@"Called 'send' on base QredoTransport class but NSInternalInconsistencyException not thrown.");
}


-(void)testClose_MustOverride {
    NSURL *serviceURL = [NSURL URLWithString:TEST_HTTP_SERVICE_URL];
    
    QredoTransport *transport = [[QredoTransport alloc] initWithServiceURL:serviceURL];
    
    XCTAssertNotNil(transport,@"Transport should not be nil.");
    
    XCTAssertThrowsSpecificNamed([transport close],NSException,NSInternalInconsistencyException,@"Called 'close' on base QredoTransport class but NSInternalInconsistencyException not thrown.");
}


@end
