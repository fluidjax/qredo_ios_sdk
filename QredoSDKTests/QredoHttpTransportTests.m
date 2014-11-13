//
//  QredoHttpTransportTests.m
//  QredoSDK
//
//  Created by David Hearn on 13/10/2014.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoHttpTransport.h"

@interface QredoHttpTransportTests : XCTestCase<QredoTransportDelegate>

@end

@implementation QredoHttpTransportTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// Needed for QredoTransportDelegate
-(void)didReceiveResponseData:(NSData *)data
{
    
}

// Needed for QredoTransportDelegate
-(void)didReceiveError:(NSError *)error
{
    
}

- (void)testInit_CannotBeCalledDirectly
{
    XCTAssertThrowsSpecificNamed([[QredoHttpTransport alloc] init], NSException, NSInternalInconsistencyException, @"Called 'init' on QredoHttpTransport class but NSInternalInconsistencyException not thrown.");
}

- (void)testInitWithServiceURL
{
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoHttpTransport *transport = [[QredoHttpTransport alloc] initWithServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
}

- (void)testSend
{
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoHttpTransport *transport = [[QredoHttpTransport alloc] initWithServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    transport.responseDelegate = self;
    
    // Use a non-nil payload
    NSData *payload = [[NSData alloc] init];
    
    [transport send:payload userData:nil];
}
@end
