/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoVaultTests.h"

@interface QredoVaultWebSocketTests :QredoVaultTests

@end

@implementation QredoVaultWebSocketTests

-(void)setUp {
    self.transportType = QredoClientOptionsTransportTypeWebSockets;
    [super setUp];
}


-(void)testPersistanceVaultId {
    [super testPersistanceVaultId];
}


-(void)testPutItem {
    [super testPutItem];
}


-(void)testPutItemMultiple {
    [super testPutItemMultiple];
}


-(void)testGettingItems {
    [super testGettingItems];
}


-(void)testEnumeration {
    [super testEnumeration];
}


-(void)testEnumerationReturnsCreatedItem {
    [super testEnumerationReturnsCreatedItem];
}


-(void)testEnumerationAbortsOnStop {
    [super testEnumerationAbortsOnStop];
}


-(void)testListener {
    [super testListener];
}


-(void)testMultipleListeners {
    [super testMultipleListeners];
}


-(void)testRemovingListenerDurringNotification {
    [super testRemovingListenerDurringNotification];
}


-(void)testMultipleRemovingListenerDurringNotification {
    [super testMultipleRemovingListenerDurringNotification];
}


-(void)testRemovingNotObservingListener {
    [super testRemovingNotObservingListener];
}


-(void)testVaultItemMetadataAndMutableMetadata {
    [super testVaultItemMetadataAndMutableMetadata];
}


-(void)testGettingItemsFromCache {
    [super testGettingItemsFromCache];
}


@end
