#import <XCTest/XCTest.h>

@interface QredoVaultUpdateTests : XCTestCase

@property BOOL useMQTT;

- (void)authoriseClient;
- (void)testGettingItems;
- (void)testPutItems;
- (void)testDeleteItems;

@end
