#import <XCTest/XCTest.h>
#import "Qredo.h"

@interface QredoVaultTests : XCTestCase

@property (nonatomic) QredoClientOptionsTransportType transportType;

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

@end
