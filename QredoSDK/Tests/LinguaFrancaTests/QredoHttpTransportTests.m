/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoTestConfiguration.h"
#import "QredoHttpTransport.h"
#import "NSData+QredoRandomData.h"
#import "QredoLoggerPrivate.h"
#import "MasterConfig.h"


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
-(void)didReceiveResponseData:(NSData *)data userData:(id)userData
{
    
}

// Needed for QredoTransportDelegate
-(void)didReceiveError:(NSError *)error userData:(id)userData
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
    
    [transport close];
}

- (void)testInitWithServiceURL_IncorrectMqttUrl
{
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    
    XCTAssertThrowsSpecificNamed([[QredoHttpTransport alloc] initWithServiceURL:serviceURL], NSException, NSInvalidArgumentException, @"Provided unsupported URL scheme to QredoHttpTransport class but NSInvalidArgumentException not thrown.");
}

- (void)testSupportsMultiResponse{
    

    
    NSURL *serviceURL = [NSURL URLWithString:QREDO_HTTP_SERVICE_URL];
    QredoHttpTransport *transport = [[QredoHttpTransport alloc] initWithServiceURL:serviceURL ];
    
    BOOL canHandle = [transport supportsMultiResponse];
    XCTAssertFalse(canHandle, @"HTTP transport should not support multi-response");
    
    [transport close];
}

- (void)testSend_Delegate
{
    NSURL *serviceURL = [NSURL URLWithString:QREDO_HTTP_SERVICE_URL];
    
    QredoHttpTransport *transport = [[QredoHttpTransport alloc] initWithServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    transport.responseDelegate = self;
    
    // Use a non-nil payload
    NSData *payload = [[NSData alloc] init];
    id userData = nil;
    
    [transport send:payload userData:userData];
    
    [transport close];
}

- (void)testSend_Block
{
    NSURL *serviceURL = [NSURL URLWithString:QREDO_HTTP_SERVICE_URL];
    
    QredoHttpTransport *transport = [[QredoHttpTransport alloc] initWithServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    [transport configureReceivedResponseBlock:^(NSData *data, id userData) {}];
    
    // Use a non-nil payload
    // TODO: DH - HTTP seems to return a LF error response if an invalid request
    NSData *payload = [[NSData alloc] init];
    id userData = nil;
    
    [transport send:payload userData:userData];
    
    [transport close];
}

- (void)testSend_Block_UserDataReturned
{
    NSURL *serviceURL = [NSURL URLWithString:QREDO_HTTP_SERVICE_URL];
    
    QredoHttpTransport *transport = [[QredoHttpTransport alloc] initWithServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    id userData = [NSData dataWithRandomBytesOfLength:16];
    __block id returnedUserData = nil;
    
    __block XCTestExpectation *responseReceivedExpectation = [self expectationWithDescription:@"Send triggered response"];
    [transport configureReceivedResponseBlock:^(NSData *data, id userData) {
        returnedUserData = userData;
        [responseReceivedExpectation fulfill];
    }];
    
    // Use a non-nil payload
    NSData *payload = [[NSData alloc] init];
    
    [transport send:payload userData:userData];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        responseReceivedExpectation = nil;
    }];
    
    XCTAssertNotNil(returnedUserData);
    XCTAssertEqualObjects(userData, returnedUserData);
    
    [transport close];
}

- (void)testSend_NoBlockNoDelegate
{
    NSURL *serviceURL = [NSURL URLWithString:QREDO_HTTP_SERVICE_URL];
    
    QredoHttpTransport *transport = [[QredoHttpTransport alloc] initWithServiceURL:serviceURL];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    // Use a non-nil payload
    NSData *payload = [[NSData alloc] init];
    id userData = nil;
    
    XCTAssertThrowsSpecificNamed([transport send:payload userData:userData], NSException, NSInternalInconsistencyException, @"Tried to send data without a delegate or response blocks configured, but expected exception not thrown.");
}
@end
