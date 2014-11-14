/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoTestConfiguration.h"

NSString *serviceURL = QREDO_SERVICE_URL;

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

    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:serviceURL]];
    XCTAssertNotNil(qredo);
    QredoVault *vault = [qredo defaultVault];
    XCTAssertNotNil(vault);

    firstQUID = vault.vaultId;
    XCTAssertNotNil(firstQUID);

    vault = nil;
    qredo = nil;

    qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:serviceURL]];

    XCTAssertEqualObjects([[qredo defaultVault] vaultId], firstQUID);
}


- (NSData*)randomDataWithLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: length];
    for (unsigned int i = 0; i < length; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    } return mutableData;
}

- (void)testGettingItems
{
    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:serviceURL]];
    QredoVault *vault = [qredo defaultVault];


    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2"};
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

    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
    {
        XCTAssertNil(error);
        XCTAssertNotNil(vaultItem);

        XCTAssertEqualObjects(vaultItem.metadata.summaryValues, item1SummaryValues);
        XCTAssert([vaultItem.value isEqualToData:item1Data]);

        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    [vault getItemMetadataWithDescriptor:item1Descriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
                       {
                           XCTAssertNil(error);
                           XCTAssertNotNil(vaultItemMetadata);

                           XCTAssertEqualObjects(vaultItemMetadata.summaryValues, item1SummaryValues);

                           dispatch_semaphore_signal(semaphore);
                       }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);


    // Testing errors
    QredoVaultItemDescriptor *randomDescriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:[QredoQUID QUID] itemId:[QredoQUID QUID]];

    [vault getItemWithDescriptor:randomDescriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
    {
        XCTAssertNotNil(error);
        XCTAssertNil(vaultItem);

        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    [vault getItemMetadataWithDescriptor:randomDescriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
     {
         XCTAssertNotNil(error);
         XCTAssertNil(vaultItemMetadata);

         dispatch_semaphore_signal(semaphore);
     }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

}

- (void)testEnumaration
{
    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:serviceURL]];
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

- (void)testListener
{
    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:serviceURL]];
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
