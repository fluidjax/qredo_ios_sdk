#import <XCTest/XCTest.h>

@interface QredoVaultUpdateTests : XCTestCase

@property NSURL *serviceURL;

- (void)authoriseClient;
- (void)testGettingItems;
- (void)testPutItems;
- (void)testDeleteItems;

@end
