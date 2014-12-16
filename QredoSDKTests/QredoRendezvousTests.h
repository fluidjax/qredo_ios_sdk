#import <XCTest/XCTest.h>

@interface QredoRendezvousTests : XCTestCase

@property BOOL useMQTT;

- (void)authoriseClient;
- (void)testCreateRendezvous;
- (void)testCreateAndRespondRendezvous;

@end