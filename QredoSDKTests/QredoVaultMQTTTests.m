#import "QredoVaultTests.h"

@interface QredoVaultMQTTTests : QredoVaultTests

@end

@implementation QredoVaultMQTTTests

- (void)setUp {
    self.transportType = QredoClientOptionsTransportTypeMQTT;
    [super setUp];
}

- (void)testPersistanceVaultId {
    [super testPersistanceVaultId];
}

- (void)testPutItem {
    [super testPutItem];
}

- (void)testPutItemMultiple {
    [super testPutItemMultiple];
}

- (void)testGettingItems {
    [super testGettingItems];
}

- (void)testEnumeration {
    [super testEnumeration];
}

- (void)testEnumerationReturnsCreatedItem {
    [super testEnumerationReturnsCreatedItem];
}

- (void)testEnumerationAbortsOnStop {
    [super testEnumerationAbortsOnStop];
}

- (void)testListener {
    [super testListener];
}

- (void)testMultipleListeners {
    [super testMultipleListeners];
}

- (void)testRemovingListenerDurringNotification {
    [super testRemovingListenerDurringNotification];
}

- (void)testMultipleRemovingListenerDurringNotification {
    [super testMultipleRemovingListenerDurringNotification];
}

- (void)testRemovingNotObservingListener {
    [super testRemovingNotObservingListener];
}

- (void)testVaultItemMetadataAndMutableMetadata {
    [super testVaultItemMetadataAndMutableMetadata];
}

- (void)testGettingItemsFromCache {
    [super testGettingItemsFromCache];
}

@end
