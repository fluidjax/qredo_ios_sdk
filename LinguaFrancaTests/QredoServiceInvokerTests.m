/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoServiceInvoker.h"
#import "QredoTestConfiguration.h"
#import "QredoClient.h"
#import "NSData+QredoRandomData.h"
#import "NSData+ParseHex.h"

@interface QredoServiceInvokerTests : XCTestCase

@property NSUInteger pingSuccessResponseCount;
@property NSUInteger pingErrorResponseCount;
@property dispatch_semaphore_t pingSemaphore;
@property dispatch_semaphore_t getChallengeSemaphore;

@end

// NOTE: As there are quite fundamental threading differences between the HTTP and MQTT transports, the tests include both HTTP and MQTT variants

@implementation QredoServiceInvokerTests

- (void)setUp {
    [super setUp];

    self.pingSemaphore = dispatch_semaphore_create(1); // Only 1 at a time
    self.getChallengeSemaphore = dispatch_semaphore_create(1); // Only 1 at a time
    self.pingSuccessResponseCount = 0;
    self.pingErrorResponseCount = 0;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)incrementPingSuccessResponseCount
{
    dispatch_semaphore_wait(self.pingSemaphore, DISPATCH_TIME_FOREVER);
    self.pingSuccessResponseCount++;
    dispatch_semaphore_signal(self.pingSemaphore);
}

- (void)incrementPingErrorResponseCount
{
    dispatch_semaphore_wait(self.pingSemaphore, DISPATCH_TIME_FOREVER);
    self.pingErrorResponseCount++;
    dispatch_semaphore_signal(self.pingSemaphore);
}

- (QredoServiceInvoker *)commonTestInit:(NSURL *)serviceURL
{
    QredoAppCredentials *appCredentials = [QredoAppCredentials appCredentialsWithAppId:@"test~" appSecret:[NSData dataWithHexString:@"cafebabe"]];
   
    QredoServiceInvoker *serviceInvoker = [[QredoServiceInvoker alloc] initWithServiceURL:serviceURL pinnedCertificate:nil appCredentials:appCredentials];
    XCTAssertNotNil(serviceInvoker);
    
    // Give time for any threading needed to setup transport etc
    [NSThread sleepForTimeInterval:1];
    
    XCTAssertFalse(serviceInvoker.isTerminated);
    
    return serviceInvoker;
}

- (QredoServiceInvoker *)commonTestInitThenTerminate:(NSURL *)serviceURL
{
    QredoServiceInvoker *serviceInvoker = [self commonTestInit:serviceURL];

    // Now terminate
    [serviceInvoker terminate];
    
    // Give time for any threading needed to close transport etc
    [NSThread sleepForTimeInterval:1];
    
    return serviceInvoker;
}

- (void)testInit_HTTPUrl
{
    // Test using the HTTP URL
    NSURL *serviceURL = [NSURL URLWithString:QREDO_HTTP_SERVICE_URL];
    XCTAssertNotNil(serviceURL);
    
    QredoServiceInvoker *serviceInvoker = [self commonTestInit:serviceURL];
    XCTAssertNotNil(serviceInvoker);
    
    // HTTP doesn't support multi-response
    XCTAssertFalse(serviceInvoker.supportsMultiResponse);
}

- (void)testInit_MQTTUrl
{
    // Test using the MQTT URL
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    XCTAssertNotNil(serviceURL);
    
    QredoServiceInvoker *serviceInvoker = [self commonTestInit:serviceURL];
    XCTAssertNotNil(serviceInvoker);
    
    // MQTT supports multi-response
    XCTAssertTrue(serviceInvoker.supportsMultiResponse);
}

- (void)testInit_NilUrl
{
    NSURL *serviceURL = nil;
    XCTAssertNil(serviceURL);

    
    QredoAppCredentials *appCredentials = [QredoAppCredentials appCredentialsWithAppId:@"test~" appSecret:[NSData dataWithHexString:@"cafebabe"]];
    

    
    XCTAssertThrowsSpecificNamed( [[QredoServiceInvoker alloc] initWithServiceURL:serviceURL pinnedCertificate:nil appCredentials:appCredentials],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Nil NSURL but NSInvalidArgumentException not thrown.");
}

- (void)testTerminate_HTTPUrl
{
    // Test using the HTTP URL
    NSURL *serviceURL = [NSURL URLWithString:QREDO_HTTP_SERVICE_URL];
    XCTAssertNotNil(serviceURL);
    
    QredoServiceInvoker *serviceInvoker = [self commonTestInitThenTerminate:serviceURL];
    XCTAssertNotNil(serviceInvoker);
    XCTAssertTrue(serviceInvoker.isTerminated);
}

- (void)testTerminate_MQTTUrl
{
    // Test using the MQTT URL
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    XCTAssertNotNil(serviceURL);
    
    QredoServiceInvoker *serviceInvoker = [self commonTestInitThenTerminate:serviceURL];
    XCTAssertNotNil(serviceInvoker);
    XCTAssertTrue(serviceInvoker.isTerminated);
}

- (void)commonInvokeService_Ping:(QredoServiceInvoker *)serviceInvoker readerCompletedExpectation:(XCTestExpectation *)readerCompletedExpectation
{
    XCTAssertNotNil(serviceInvoker);
    
    [serviceInvoker invokeService:@"Ping"
                        operation:@"ping"
                    requestWriter:^void(QredoWireFormatWriter *writer) {
                        // Ping has nothing to write
                    }
                   responseReader:^void(QredoWireFormatReader *reader) {
                       BOOL result = [[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
                       XCTAssertTrue(result);
                       
//                       [self incrementPingSuccessResponseCount];
                       
                       [readerCompletedExpectation fulfill];
                   }
                     errorHandler:^(NSError *error) {
                         XCTFail(@"Error should not have occurred.");

//                         [self incrementPingErrorResponseCount];
                     }];
}

- (void)testInvokeService_Ping_HTTPUrl
{
    // Test using the HTTP URL
    NSURL *serviceURL = [NSURL URLWithString:QREDO_HTTP_SERVICE_URL];
    XCTAssertNotNil(serviceURL);
    
    QredoServiceInvoker *serviceInvoker = [self commonTestInit:serviceURL];
    XCTAssertNotNil(serviceInvoker);

    __block XCTestExpectation *readerCompletedExpectation = [self expectationWithDescription:@"Reader completed"];
    [self commonInvokeService_Ping:serviceInvoker readerCompletedExpectation:readerCompletedExpectation];
    
    // Allow 10 seconds for the operation to return
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        readerCompletedExpectation = nil;
    }];
}

- (void)testInvokeService_Ping_MQTTUrl
{
    // Test using the MQTT URL
    NSURL *serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    XCTAssertNotNil(serviceURL);
    
    QredoServiceInvoker *serviceInvoker = [self commonTestInit:serviceURL];
    XCTAssertNotNil(serviceInvoker);
    
    __block XCTestExpectation *readerCompletedExpectation = [self expectationWithDescription:@"Reader completed"];
    [self commonInvokeService_Ping:serviceInvoker readerCompletedExpectation:readerCompletedExpectation];

    // Allow 10 seconds for the operation to return
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        readerCompletedExpectation = nil;
    }];
}

- (void)commonInvokeService_ConcurrentOperationsWithServiceURL:(NSURL *)serviceURL iterations:(NSUInteger)iterations intervalPerIteration:(NSTimeInterval)intervalPerIteration
{
    XCTAssertNotNil(serviceURL);

    QredoServiceInvoker *serviceInvoker = [self commonTestInit:serviceURL];
    XCTAssertNotNil(serviceInvoker);
    

    // Create serial queues
    const int numberOfQueues = 8;
    NSMutableArray *queues = [[NSMutableArray alloc] initWithCapacity:numberOfQueues];
    for (int i = 0; i < numberOfQueues; i++) {
        NSString *queueName = [NSString stringWithFormat:@"testQueue%d", i];
        dispatch_queue_t queue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        [queues addObject:queue];
    }
    
    __block NSUInteger expectedPingResponseCount = 0;

    for (dispatch_queue_t queue in queues) {
        dispatch_async(queue, ^{
            for (int counter1 = 0; counter1 < iterations; counter1++) {
                expectedPingResponseCount++;
                [self commonInvokeService_Ping:serviceInvoker readerCompletedExpectation:nil];
            }
        });
    }
    
    // If the wait time is too short, will terminate/close transport whilst still in use and trigger errors
    NSTimeInterval waitTime = iterations * intervalPerIteration;
    [NSThread sleepForTimeInterval:waitTime];
    
    [serviceInvoker terminate];
    
    waitTime = 2; // 2 seconds to terminate transports
    [NSThread sleepForTimeInterval:waitTime];

    XCTAssertEqual(self.pingSuccessResponseCount + self.pingErrorResponseCount, expectedPingResponseCount);
    XCTAssertFalse(self.pingErrorResponseCount);
}

- (void)testInvokeService_ConcurrentOperations_HTTPUrl
{
    // Note: 7500 iterations takes long time, but had previously caused hangs before transport concurrency issues resolved
    const int requiredIterations = 50;

    // Give time for the process to complete (for HTTP, 0.09 seconds per iteration appears enough time,
    // otherwise will terminate/close transport whilst still in use and trigger errors)
    NSTimeInterval interval = 0.09;

    [self commonInvokeService_ConcurrentOperationsWithServiceURL:[NSURL URLWithString:QREDO_HTTP_SERVICE_URL]
                                                      iterations:requiredIterations
                                            intervalPerIteration:interval];
}

- (void)testInvokeService_ConcurrentOperations_MQTTUrl
{
    // Note: 7500 iterations takes long time, but had previously caused hangs before transport concurrency issues resolved
    const int requiredIterations = 50;
    
    // Give time for the process to complete (for MQTT, 0.09 seconds per iteration appears enough time,
    // otherwise will terminate/close transport whilst still in use and trigger errors)
    NSTimeInterval interval = 0.09;
    
    [self commonInvokeService_ConcurrentOperationsWithServiceURL:[NSURL URLWithString:QREDO_MQTT_SERVICE_URL]
                                                      iterations:requiredIterations
                                            intervalPerIteration:interval];
}

// TODO: DH - Invoke non-existant service
// TODO: DH - Invoke non-existant operation
// TODO: DH - Invoke operation with invalid data (trigger error message response - e.g. nil responder public key)
// TODO: DH - Trigger error in requestWriter
// TODO: DH - Trigger error in requestReader
// TODO: DH - Trigger errorHandler block
// TODO: DH - try to remove the response marshaller dependency from these tests (writer)
// TODO: DH - try to remove the response marshaller dependency from these tests (reader)

@end
