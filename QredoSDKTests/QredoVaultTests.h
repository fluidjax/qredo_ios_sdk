#import <XCTest/XCTest.h>

@interface QredoVaultTests : XCTestCase

@property NSString *serviceURL;

- (void)testPersistanceVaultId;
- (void)testGettingItems;
- (void)testEnumeration;
- (void)testEnumerationReturnsCreatedItem;
- (void)testListener;

@end
