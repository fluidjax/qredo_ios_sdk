#import <XCTest/XCTest.h>

@interface QredoVaultTests : XCTestCase

@property NSString *serviceURL;

- (void)testPersistanceVaultId;
- (void)testPutItem;
- (void)testPutItemMultiple;
- (void)testGettingItems;
- (void)testEnumeration;
- (void)testEnumerationReturnsCreatedItem;
- (void)testEnumerationAbortsOnStop;
- (void)testListener;
- (void)testVaultItemMetadataAndMutableMetadata;

@end
