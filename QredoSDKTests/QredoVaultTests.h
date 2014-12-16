#import <XCTest/XCTest.h>

@interface QredoVaultTests : XCTestCase

@property BOOL useMQTT;

- (void)authoriseClient;
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
