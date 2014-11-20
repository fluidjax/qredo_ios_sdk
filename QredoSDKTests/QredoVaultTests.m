/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoTestConfiguration.h"
#import "QredoTestUtils.h"

@interface QredoVaultListener : NSObject<QredoVaultDelegate>
{
    int scheduled, timedout;
    dispatch_queue_t queue;
}
@property dispatch_semaphore_t semaphore;
@property NSMutableArray *receivedItems;
@property NSError *error;
@property double signalTimeout;

@end

@implementation QredoVaultListener
- (instancetype)init {
    self = [super init];

    queue = dispatch_queue_create("test.qredo.queue", nil);

    return self;
}

- (void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error
{
    _error = error;
    dispatch_semaphore_signal(_semaphore);
}

- (void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata
{
    if (!_receivedItems) _receivedItems = [NSMutableArray array];

    [_receivedItems addObject:itemMetadata];

    ++scheduled;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_signalTimeout * NSEC_PER_SEC)), queue, ^{
        ++timedout;
        if (scheduled == timedout) {
//            [client resetWatermark];

            dispatch_semaphore_signal(_semaphore);
        }
    });
}

@end


@interface QredoVaultTests : XCTestCase

@end

@implementation QredoVaultTests

- (void)testPersistanceVaultId {
    QredoQUID *firstQUID = nil;

    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:qtu_serviceURL]];
    XCTAssertNotNil(qredo);
    QredoVault *vault = [qredo defaultVault];
    XCTAssertNotNil(vault);

    firstQUID = vault.vaultId;
    XCTAssertNotNil(firstQUID);

    vault = nil;
    qredo = nil;

    qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:qtu_serviceURL]];

    XCTAssertEqualObjects([[qredo defaultVault] vaultId], firstQUID);
}

- (void)testEnumeration
{
    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:qtu_serviceURL]];
    QredoVault *vault = [qredo defaultVault];

    __block NSError *error = nil;
    __block int count = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;

        if (*stop) {
            dispatch_semaphore_signal(semaphore);
        }
    } completionHandler:^(NSError *errorBlock) {
        error = errorBlock;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    XCTAssertNil(error);

    NSLog(@"count: %d", count);
}

- (void)testEnumerationReturnsCreatedItem
{
    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:qtu_serviceURL]];
    QredoVault *vault = [qredo defaultVault];
    
    // Create an item and store in vault
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    NSLog(@"Item summary values for new item: %@", item1SummaryValues);
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                                            accessLevel:0
                                                                                                          summaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)
     {
         item1Descriptor = newItemDescriptor;
         dispatch_semaphore_signal(semaphore);
     }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    // Confirm the item is found in the vault
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"], item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"], item1SummaryValues[@"key2"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key3"], item1SummaryValues[@"key3"]);
         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         
         NSLog(@"Got item with summary values: %@", vaultItem.metadata.summaryValues);
         
         dispatch_semaphore_signal(semaphore);
     }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    
    // Confirm enumerate finds item we added
    __block NSError *error = nil;
    __block int count = 0;
    __block BOOL itemFound = NO;
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;
        
        XCTAssertNil(error);
        XCTAssertNotNil(vaultItemMetadata);
        
        NSLog(@"Enumerated item %d summary values: %@", count, vaultItemMetadata.summaryValues);
        
        if ([vaultItemMetadata.summaryValues[@"key1"] isEqual:item1SummaryValues[@"key1"]] &&
            [vaultItemMetadata.summaryValues[@"key2"] isEqual:item1SummaryValues[@"key2"]] &&
            [vaultItemMetadata.summaryValues[@"key3"] isEqual:item1SummaryValues[@"key3"]])
        {
            itemFound = YES;
            NSLog(@"Item created earlier has been found (count = %d).", count);
        }
        
        if (*stop) {
            NSLog(@"Enumeration stopped.");
            dispatch_semaphore_signal(semaphore);
        }
    } completionHandler:^(NSError *errorBlock) {
        error = errorBlock;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    XCTAssertNil(error);

    // TODO: DH - Apparently server returns 50 items, so once 50 items created this test will fail.  Looks like must return first 50 items, rather than latest 50 items.
    XCTAssertTrue(itemFound, "Item just created was not found during enumeration.");
    
    NSLog(@"count: %d", count);
}

- (void)testListener
{
    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:qtu_serviceURL]];
    QredoVault *vault = [qredo defaultVault];

    __block NSError *error = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    QredoVaultListener *listener = [[QredoVaultListener alloc] init];
    listener.semaphore = semaphore;
    listener.signalTimeout = 2; //seconds

    vault.delegate = listener;

    [vault startListening];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [vault stopListening];

    XCTAssertNil(error);
}

@end
