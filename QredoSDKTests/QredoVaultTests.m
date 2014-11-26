/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <XCTest/XCTest.h>
#import "QredoVaultTests.h"
#import "Qredo.h"
#import "QredoTestConfiguration.h"
#import "QredoTestUtils.h"
#import "NSDictionary+Contains.h"

@interface QredoVaultListener : NSObject<QredoVaultDelegate>

@property XCTestExpectation *didReceiveVaultItemMetadataExpectation;
@property XCTestExpectation *didFailWithErrorExpectation;
@property NSMutableArray *receivedItems;
@property NSError *error;

@end

@implementation QredoVaultListener

- (void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error
{
    NSLog(@"Vault operation failed with error: %@", error);

    self.error = error;
    
    if (self.didFailWithErrorExpectation) {
        [self.didFailWithErrorExpectation fulfill];
    }
}

- (void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata
{
    NSLog(@"Received VaultItemMetadata");
    
    if (!self.receivedItems) {
        self.receivedItems = [NSMutableArray array];
    }

    [self.receivedItems addObject:itemMetadata];

    if (self.didReceiveVaultItemMetadataExpectation) {
        [self.didReceiveVaultItemMetadataExpectation fulfill];
    }
}

@end

@interface QredoVaultTests ()
{
    QredoClient *qredo;
}

@end


@implementation QredoVaultTests

- (void)setUp {
    [super setUp];

    self.serviceURL = QREDO_HTTP_SERVICE_URL;

    XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];

    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:@{QredoClientOptionServiceURL: self.serviceURL,
                                                  QredoClientOptionVaultID: [QredoQUID QUID]}
                              completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  qredo = clientArg;
                                  [clientExpectation fulfill];
                              }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];

}

- (NSData*)randomDataWithLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: length];
    for (unsigned int i = 0; i < length; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    } return mutableData;
}

- (void)testPersistanceVaultId {
    QredoQUID *firstQUID = nil;

    XCTAssertNotNil(qredo);
    QredoVault *vault = [qredo defaultVault];
    XCTAssertNotNil(vault);

    firstQUID = vault.vaultId;
    XCTAssertNotNil(firstQUID);

    vault = nil;
    qredo = nil;

    XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:@{QredoClientOptionServiceURL: self.serviceURL}
                              completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  qredo = clientArg;
                                  [clientExpectation fulfill];
                              }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertEqualObjects([[qredo defaultVault] vaultId], firstQUID);
}

- (void)testGettingItems
{
    QredoVault *vault = [qredo defaultVault];
    
    
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2"};

    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                                            accessLevel:0
                                                                                                          summaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)
     {
         item1Descriptor = newItemDescriptor;
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];

    testExpectation = [self expectationWithDescription:@"get item 1 with descriptor"];
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);

         XCTAssertTrue([vaultItem.metadata.summaryValues containsDictionary:item1SummaryValues comparison:^BOOL(id a, id b) {
             return [a isEqual:b];
         }]);

         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];

    testExpectation = [self expectationWithDescription:@"get item 1 metadata"];
    [vault getItemMetadataWithDescriptor:item1Descriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItemMetadata);

         XCTAssertTrue([vaultItemMetadata.summaryValues containsDictionary:item1SummaryValues comparison:^BOOL(id a, id b) {
             return [a isEqual:b];
         }]);

         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];
    
    
    // Testing errors
    QredoVaultItemDescriptor *randomDescriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:[QredoQUID QUID] itemId:[QredoQUID QUID]];

    testExpectation = [self expectationWithDescription:@"get item with random descriptor"];
    [vault getItemWithDescriptor:randomDescriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNotNil(error);
         XCTAssertNil(vaultItem);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];

    testExpectation = [self expectationWithDescription:@"get item metadata with random descriptor"];
    [vault getItemMetadataWithDescriptor:randomDescriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
     {
         XCTAssertNotNil(error);
         XCTAssertNil(vaultItemMetadata);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];
}

- (void)testEnumeration
{
    QredoVault *vault = [qredo defaultVault];

    __block NSError *error = nil;
    __block int count = 0;
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"Enumerate"];
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;

    } completionHandler:^(NSError *errorBlock) {
        error = errorBlock;
        [testExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];
    XCTAssertNil(error);

    NSLog(@"count: %d", count);
}

- (void)testEnumerationReturnsCreatedItem
{
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

    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    
    XCTestExpectation *putItemCompletedExpectation = [self expectationWithDescription:@"PutItem completion handler called"];
    [vault putItem:item1 completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)
     {
         XCTAssertNil(error, @"Error occurred during PutItem");
         item1Descriptor = newItemDescriptor;

         [putItemCompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];
    XCTAssertNotNil(item1Descriptor, @"Descriptor returned is nil");
    
    // Confirm the item is found in the vault
    XCTestExpectation *getItemCompletedExpectation = [self expectationWithDescription:@"GetItem completion handler called"];
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"], item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"], item1SummaryValues[@"key2"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key3"], item1SummaryValues[@"key3"]);
         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         
         NSLog(@"Got item with summary values: %@", vaultItem.metadata.summaryValues);

         [getItemCompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];

    // Confirm enumerate finds item we added
    __block NSError *error = nil;
    __block int count = 0;
    __block BOOL itemFound = NO;
    XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
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
        
    } completionHandler:^(NSError *errorBlock) {
        error = errorBlock;
        [completionHandlerCalled fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];

    XCTAssertNil(error);

    XCTAssertTrue(itemFound, "Item just created was not found during enumeration.");
    
    // Note: DH - Apparently server returns 50 items, so once 50 items created this test will fail.  Looks like it returns first 50 items, rather than latest 50 items.
    if (!itemFound && count == 50)
    {
        XCTFail(@"Created item was not found and 50 items were enumerated. Likely failure was due to server only returning oldest 50 items.");
    }
    
    NSLog(@"count: %d", count);
}

- (void)testListener
{
    QredoVault *vault = [qredo defaultVault];

    QredoVaultListener *listener = [[QredoVaultListener alloc] init];
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];

    vault.delegate = listener;

    [vault startListening];

    // Create an item to ensure that there's data later than any current HWM
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2"};
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                                            accessLevel:0
                                                                                                          summaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)
     {
         item1Descriptor = newItemDescriptor;
     }];

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:nil];
    XCTAssertNil(listener.error);
    XCTAssertNotNil(listener.receivedItems);
    XCTAssertTrue(listener.receivedItems.count > 0);


    [vault stopListening];
}

@end
