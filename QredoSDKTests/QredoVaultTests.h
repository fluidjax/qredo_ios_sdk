#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoXCTestCase.h"

@interface QredoVaultTests : QredoXCTestCase


- (void)authoriseClient;
- (void)testPersistanceVaultId;
- (void)testPutItem;
- (void)testPutItemMultiple;
- (void)testGettingItems;
- (void)testEnumeration;
- (void)testEnumerationReturnsCreatedItem;
- (void)testEnumerationAbortsOnStop;

- (void)testListener;
- (void)testMultipleListeners;
- (void)testRemovingListenerDurringNotification;
- (void)testMultipleRemovingListenerDurringNotification;
- (void)testRemovingNotObservingListener;

- (void)testVaultItemMetadataAndMutableMetadata;
- (void)testGettingItemsFromCache;

@end
