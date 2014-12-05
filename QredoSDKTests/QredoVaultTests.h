#import <XCTest/XCTest.h>

@interface QredoVaultTests : XCTestCase

@property BOOL useMQTT;

- (void)testPersistanceVaultId;
- (void)testGettingItems;
- (void)testEnumeration;
- (void)testEnumerationReturnsCreatedItem;
- (void)testListener;

@end
