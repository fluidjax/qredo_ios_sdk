/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoTestConfiguration.h"
#import "QredoMqttTransport.h"
#import "NSData+QredoRandomData.h"
#import "QredoLogging.h"

@interface TransportListener : NSObject <QredoTransportDelegate>

@property XCTestExpectation *responseDataExpectation;
@property XCTestExpectation *errorExpectation;
@property BOOL responseDataReceived;
@property NSError *lastErrorReceived;

@end

@implementation TransportListener

-(void)didReceiveResponseData:(NSData *)data userData:(id)userData
{
    self.responseDataReceived = YES;
    
    if (self.responseDataExpectation)
    {
        [self.responseDataExpectation fulfill];
    }
}

-(void)didReceiveError:(NSError *)error userData:(id)userData
{
    self.lastErrorReceived = error;
    
    if (self.responseDataExpectation)
    {
        [self.errorExpectation fulfill];
    }
}

@end

@interface QredoMqttTransportTests : XCTestCase

@end

@implementation QredoMqttTransportTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit_CannotBeCalledDirectly
{
    XCTAssertThrowsSpecificNamed([[QredoMqttTransport alloc] init], NSException, NSInternalInconsistencyException, @"Called 'init' on QredoMqttTransport class but NSInternalInconsistencyException not thrown.");
}

- (void)testInitWithServiceURL_TCPWithPath
{
    NSURL *serviceURL = [NSURL URLWithString:@"tcp://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    [transport close];
}

- (void)testInitWithServiceURL_TCPWithoutPath
{
    NSURL *serviceURL = [NSURL URLWithString:@"tcp://test.host.qredo.com:8765"];
    
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    [transport close];
}

- (void)testInitWithServiceURL_SSLWithPath
{
    NSURL *serviceURL = [NSURL URLWithString:@"ssl://test.host.qredo.com:8765/path/to/somewhere"];
    
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    [transport close];
}

- (void)testInitWithServiceURL_SSLWithoutPath
{
    NSURL *serviceURL = [NSURL URLWithString:@"ssl://test.host.qredo.com:8765"];
    
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    [transport close];
}

- (void)testInitWithServiceURL_Incorrect
{
    NSURL *serviceURL = [NSURL URLWithString:@"http://test.host.qredo.com:8765/path/to/somewhere"];
    
    XCTAssertThrowsSpecificNamed([[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil], NSException, NSInvalidArgumentException, @"Provided unsupported URL scheme to QredoMqttTransport class but NSInvalidArgumentException not thrown.");
}

- (void)testConnectsToServer
{
    const double POLL_INTERVAL = 0.5;
    const double MAX_POLL_DURATION = 2.0;
    
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    
    XCTAssertNotNil(transport, "Transport should not be nil.");

    TransportListener *listener = [[TransportListener alloc] init];
    transport.responseDelegate = listener;
    
    // Give runloop time to allow connection to be established
    int pollCount = 0;
    double pollTime = 0;
    BOOL completed = NO;
    
    while (!completed && pollTime < MAX_POLL_DURATION)
    {
        NSDate* untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
        
        if (transport.connectedAndReady)
        {
            completed = YES;
        }
        
        pollCount++;
        pollTime = pollCount * POLL_INTERVAL;
    }
    
    if (!completed && pollTime >= MAX_POLL_DURATION) {
        XCTFail(@"Polling hit max duration and async did not complete as expected.");
    }

    XCTAssertTrue(transport.connectedAndReady, "Transport should have connected within the period allowed.");
    
    [transport close];
}

- (void)testConnectsToServer_CanConnectDoesNotNotifyFailure
{
    const double POLL_INTERVAL = 0.5;
    const double MAX_POLL_DURATION = 2.0;
    
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    
    XCTAssertNotNil(transport, "Transport should not be nil.");
    
    __block NSError *receivedError = nil;
    
    [transport configureReceivedErrorBlock:^(NSError *error, id userData) {
        receivedError = error;
    }];
    
    // Give runloop time to allow connection to be established
    int pollCount = 0;
    double pollTime = 0;
    BOOL completed = NO;
    
    while (!completed && pollTime < MAX_POLL_DURATION)
    {
        NSDate* untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
        
        if (receivedError != nil)
        {
            completed = YES;
        }
        
        pollCount++;
        pollTime = pollCount * POLL_INTERVAL;
    }
    
    XCTAssertNil(receivedError, @"Error block should not have been called.");
    
    [transport close];
}

- (void)testSupportsMultiResponse
{
    NSURL *serviceURL = [NSURL URLWithString:@"tcp://dev.qredo.me"];
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    
    BOOL canHandle = [transport supportsMultiResponse];
    XCTAssertTrue(canHandle, @"MQTT transport should support multi-response");
    
    [transport close];
}

- (void)testSend_Delegate
{
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    TransportListener *listener = [[TransportListener alloc] init];
    transport.responseDelegate = listener;
    
    // Use a non-nil payload
    NSData *payload = [[NSData alloc] init];
    id userData = nil;

    XCTAssertNoThrow([transport send:payload userData:userData], "Send threw an unexpected exception.");
    
    [transport close];
}

- (void)testSend_Block
{
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    XCTAssertNotNil(transport, @"Transport should not be nil.");
    
    // Use a non-nil payload
    // TODO: DH - MQTT doesn't seem to return a LF error response if an invalid request
    NSData *payload = [[NSData alloc] init];
    id userData = nil;
    
    XCTAssertNoThrow([transport send:payload userData:userData], "Send threw an unexpected exception.");
    
    [transport close];
}

- (void)testSend_Block_AttemptTriggerThreadingIssue
{
    /*
     This test will attempt to send large amounts of data (which require multiple network
     stream writes in Paho MQTT), and whilst that's in progress, call send again to trigger
     another send whilst Paho MQTT is still processing original request. If this occurs,
     then Paho will thrown an assert and crash.  Once this has been fixed in
     QredoMqttTransport, then this test will ensure that it is resolved.
     */

    const double POLL_INTERVAL = 0.5;
    const double MAX_POLL_DURATION = 2.0;
    
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    
    XCTAssertNotNil(transport, "Transport should not be nil.");
    
    TransportListener *listener = [[TransportListener alloc] init];
    transport.responseDelegate = listener;
    
    // Give runloop time to allow connection to be established
    int pollCount = 0;
    double pollTime = 0;
    BOOL completed = NO;
    
    while (!completed && pollTime < MAX_POLL_DURATION)
    {
        NSDate* untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
        
        if (transport.connectedAndReady)
        {
            completed = YES;
        }
        
        pollCount++;
        pollTime = pollCount * POLL_INTERVAL;
    }
    
    if (!completed && pollTime >= MAX_POLL_DURATION) {
        XCTFail(@"Polling hit max duration and async did not complete as expected.");
    }
    
    XCTAssertTrue(transport.connectedAndReady, "Transport should have connected within the period allowed.");
    
    // Connected, now proceed to the send tests
    
    // Use a large payload (MQTT doesn't appear to send response on invalid data)
    id userData = [NSData dataWithRandomBytesOfLength:16];
    NSData *payload = [NSData dataWithRandomBytesOfLength:1000000]; // 1000k

    __block XCTestExpectation *sendCompleteExpectation1 = [self expectationWithDescription:@"Send 1 completed"];
    __block XCTestExpectation *sendCompleteExpectation2 = [self expectationWithDescription:@"Send 2 completed"];
    __block XCTestExpectation *sendCompleteExpectation3 = [self expectationWithDescription:@"Send 3 completed"];
    dispatch_queue_t testQueue1 = dispatch_queue_create("testQueue1", nil);
    dispatch_queue_t testQueue2 = dispatch_queue_create("testQueue2", nil);
    dispatch_queue_t testQueue3 = dispatch_queue_create("testQueue3", nil);
    dispatch_async(testQueue1, ^{
        [transport send:payload userData:userData];
        [sendCompleteExpectation1 fulfill];
    });
    dispatch_async(testQueue2, ^{
        [transport send:payload userData:userData];
        [sendCompleteExpectation2 fulfill];
    });
    dispatch_async(testQueue3, ^{
        [transport send:payload userData:userData];
        [sendCompleteExpectation3 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        sendCompleteExpectation1 = nil;
        sendCompleteExpectation2 = nil;
        sendCompleteExpectation3 = nil;
    }];

    [transport close];
}

- (void)testSend_NoBlockNoDelegate
{
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    XCTAssertNotNil(transport, @"Transport should not be nil.");

    // Use a non-nil payload
    NSData *payload = [[NSData alloc] init];
    id userData = nil;
    
    XCTAssertThrowsSpecificNamed([transport send:payload userData:userData], NSException, NSInternalInconsistencyException, @"Tried to send data without a delegate or response blocks configured, but expected exception not thrown.");
}

- (void)testClose_Delegate
{
    const double POLL_INTERVAL = 0.5;
    const double MAX_POLL_DURATION = 2.0;
    
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    
    XCTAssertNotNil(transport, "Transport should not be nil.");
    
    TransportListener *listener = [[TransportListener alloc] init];
    transport.responseDelegate = listener;
    
    // Give runloop time to allow connection to be established
    int pollCount = 0;
    double pollTime = 0;
    BOOL connected = NO;
    
    while (!connected && pollTime < MAX_POLL_DURATION)
    {
        NSDate* untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
        
        if (transport.connectedAndReady)
        {
            connected = YES;
        }
        
        pollCount++;
        pollTime = pollCount * POLL_INTERVAL;
    }
    
    XCTAssertNil(listener.lastErrorReceived, @"Error listener should not have been called yet.");
    
    // We're now connected to the server, try closing and confirming we get a closed event
    [transport close];
    
    BOOL completed = NO;
    while (!completed && pollTime < MAX_POLL_DURATION)
    {
        NSDate* untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
        
        if (listener.lastErrorReceived != nil)
        {
            completed = YES;
        }
        
        pollCount++;
        pollTime = pollCount * POLL_INTERVAL;
    }
    
    XCTAssertNotNil(listener.lastErrorReceived, @"Error listener should have been called when closing.");
    XCTAssertTrue(listener.lastErrorReceived.code == QredoTransportErrorConnectionClosed, "Error code is incorrect.");
}

- (void)testClose_Block
{
    const double POLL_INTERVAL = 0.5;
    const double MAX_POLL_DURATION = 2.0;
    
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    QredoMqttTransport *transport = [[QredoMqttTransport alloc] initWithServiceURL:serviceURL pinnedCertificate:nil];
    
    XCTAssertNotNil(transport, "Transport should not be nil.");
    
    __block NSData *receivedData = nil;
    __block NSError *receivedError = nil;
    
    [transport configureReceivedResponseBlock:^(NSData *data, id userData) {
        receivedData = data;
    }];
    [transport configureReceivedErrorBlock:^(NSError *error, id userData) {
        receivedError = error;
    }];
    
    // Give runloop time to allow connection to be established
    int pollCount = 0;
    double pollTime = 0;
    BOOL connected = NO;
    
    while (!connected && pollTime < MAX_POLL_DURATION)
    {
        NSDate* untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
        
        if (transport.connectedAndReady)
        {
            connected = YES;
        }
        
        pollCount++;
        pollTime = pollCount * POLL_INTERVAL;
    }
    
    XCTAssertNil(receivedError, @"Error block should not have been called yet.");
    
    // We're now connected to the server, try closing and confirming we get a closed event
    [transport close];
    
    BOOL completed = NO;
    while (!completed && pollTime < MAX_POLL_DURATION)
    {
        NSDate* untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
        
        if (receivedError != nil)
        {
            completed = YES;
        }
        
        pollCount++;
        pollTime = pollCount * POLL_INTERVAL;
    }
    
    XCTAssertNotNil(receivedError, @"Error block should have been called when closing.");
    XCTAssertTrue(receivedError.code == QredoTransportErrorConnectionClosed, "Error code is incorrect.");
}

@end
