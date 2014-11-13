//
//  QredoTransportTests.m
//  QredoSDK
//
//  Created by David Hearn on 13/10/2014.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoTransport.h"
#import "QredoHttpTransport.h"

@interface QredoTransportTests : XCTestCase

@end

@implementation QredoTransportTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testTransportForServiceURL_HTTPLowercase
{
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoTransport *transport = [QredoTransport transportForServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    XCTAssertTrue([transport isKindOfClass:[QredoHttpTransport class]]);
}

- (void)testTransportForServiceURL_HTTPUppercase
{
    NSURL *serviceURL = [NSURL URLWithString:@"HTTP://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoTransport *transport = [QredoTransport transportForServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    XCTAssertTrue([transport isKindOfClass:[QredoHttpTransport class]]);
}

- (void)testTransportForServiceURL_UnsupportedFTP
{
    NSURL *serviceURL = [NSURL URLWithString:@"ftp://test.host.qredo.com:8765/path/to/somewhere"];
    
    XCTAssertThrowsSpecificNamed([QredoTransport transportForServiceURL:serviceURL], NSException, NSInvalidArgumentException, @"Passed in unsupported URL scheme but NSInvalidArgumentException not thrown.");
}

- (void)testTransportForServiceURL_UnsupportedHTTPS
{
    NSURL *serviceURL = [NSURL URLWithString:@"https://test.host.qredo.com:8765/path/to/somewhere"];
    
    XCTAssertThrowsSpecificNamed([QredoTransport transportForServiceURL:serviceURL], NSException, NSInvalidArgumentException, @"Passed in unsupported URL scheme but NSInvalidArgumentException not thrown.");
}

- (void)testInit_CannotBeCalledDirectly
{
    XCTAssertThrowsSpecificNamed([[QredoTransport alloc] init], NSException, NSInternalInconsistencyException, @"Called 'init' on base QredoTransport class but NSInternalInconsistencyException not thrown.");
}

- (void)testInitWithServiceURL
{
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];

    QredoTransport *transport = [[QredoTransport alloc] initWithServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
}

- (void)testSend_MustOverride
{
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoTransport *transport = [[QredoTransport alloc] initWithServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    // Use a non-nil payload
    NSData *payload = [[NSData alloc] init];
    
    XCTAssertThrowsSpecificNamed([transport send:payload userData:nil], NSException, NSInternalInconsistencyException, @"Called 'send' on base QredoTransport class but NSInternalInconsistencyException not thrown.");
}

@end
