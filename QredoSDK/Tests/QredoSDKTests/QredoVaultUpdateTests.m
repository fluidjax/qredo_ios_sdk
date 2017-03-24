/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"
#import "QredoTestUtils.h"
#import "QredoVaultUpdateTests.h"
#import "NSDictionary+Contains.h"


@interface QredoVaultUpdateTests ()
{
    int systemItemsCount;
    NSMutableArray *systemItemDescriptors;
}

@end

@implementation QredoVaultUpdateTests

-(void)setUp {
    [super setUp];
    [self createRandomClient1];
    [self addSystemVaultItems];
}




-(void)addSystemVaultItems {
    
    //system items are those that are created when a vault is initialized. It can be, for example, device info.
    __block XCTestExpectation *systemItemsExpectation = [self expectationWithDescription:@"count system items"];
    QredoVault *vault = [testClient1 defaultVault];
    systemItemDescriptors = [NSMutableArray array];
    systemItemsCount = 0;
    [vault enumerateVaultItemsAllVersionsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop) {
        systemItemsCount++;
        [systemItemDescriptors addObject:vaultItemMetadata.descriptor];
    }
                                  completionHandler:^(NSError *error) {
                                      XCTAssertNil(error);
                                      [systemItemsExpectation fulfill];
                                  }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     systemItemsExpectation = nil;
                                 }];
}


-(void)testGettingItems {
    __block XCTestExpectation *testExpectation = nil;
    
    QredoVault *vault = [testClient1 defaultVault];
    
    
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{ @"key1":@"value1",
                                          @"key2":@"value2" };
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues];
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata
                                                            value:item1Data];
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    
    testExpectation = [self expectationWithDescription:@"Put"];
    [vault putItem:item1
 completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error)
     {
         XCTAssertNil(error);
         item1Descriptor = newItemMetadata.descriptor;
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    testExpectation = [self expectationWithDescription:@"Get item"];
    [vault getItemWithDescriptor:item1Descriptor
               completionHandler:^(QredoVaultItem *vaultItem,NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"],item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"],item1SummaryValues[@"key2"]);
         XCTAssert([vaultItem.value
                    isEqualToData:item1Data]);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    testExpectation = [self expectationWithDescription:@"Get metadata"];
    [vault getItemMetadataWithDescriptor:item1Descriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata,NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItemMetadata);
         
         XCTAssertEqualObjects(vaultItemMetadata.summaryValues[@"key1"],item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItemMetadata.summaryValues[@"key2"],item1SummaryValues[@"key2"]);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    
    //Testing errors
    QredoVaultItemDescriptor *randomDescriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:[QredoQUID QUID] itemId:[QredoQUID QUID]];
    
    testExpectation = [self expectationWithDescription:@"Get nonexistent item"];
    [vault getItemWithDescriptor:randomDescriptor
               completionHandler:^(QredoVaultItem *vaultItem,NSError *error)
     {
         XCTAssertNotNil(error);
         XCTAssertNil(vaultItem);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    testExpectation = [self expectationWithDescription:@"Get nonexistent metadata"];
    [vault getItemMetadataWithDescriptor:randomDescriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata,NSError *error)
     {
         XCTAssertNotNil(error);
         XCTAssertNil(vaultItemMetadata);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
}


-(void)testPutItems {
    __block XCTestExpectation *testExpectation = nil;
    
    QredoVault *vault = [testClient1 defaultVault];
    
    
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{ @"key1":@"value1",
                                          @"key2":@"value2" };
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues];
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    
    NSDate *beforeFirstPutDate = [NSDate dateWithTimeIntervalSinceNow:-30];
    
    testExpectation = [self expectationWithDescription:@"First put"];
    [vault putItem:item1
 completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error)
     {
         XCTAssertNil(error);
         item1Descriptor = newItemMetadata.descriptor;
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    
    NSDate *afterFirstPutDate = [NSDate dateWithTimeIntervalSinceNow:+30];
    
    testExpectation = [self expectationWithDescription:@"Get"];
    [vault getItemWithDescriptor:item1Descriptor
               completionHandler:^(QredoVaultItem *vaultItem,NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"],item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"],item1SummaryValues[@"key2"]);
         XCTAssert([beforeFirstPutDate compare:vaultItem.metadata.summaryValues[@"_created"]] != NSOrderedDescending);
         XCTAssert([afterFirstPutDate compare:vaultItem.metadata.summaryValues[@"_created"]] != NSOrderedAscending);
         XCTAssertNil(vaultItem.metadata.summaryValues[@"_modified"]);
         XCTAssertNil(vaultItem.metadata.summaryValues[@"_v"]);
         XCTAssert([vaultItem.value
                    isEqualToData:item1Data]);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    __block QredoVaultItemMetadata *fetchedMetadata = nil;
    __block NSUInteger numberOfFetchedMetadata = 0;
    testExpectation = [self expectationWithDescription:@"Enumerate"];
    [vault enumerateVaultItemsAllVersionsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop) {
        if (![systemItemDescriptors containsObject:vaultItemMetadata.descriptor]){
            fetchedMetadata = vaultItemMetadata;
        }
        
        numberOfFetchedMetadata++;
    }
                                  completionHandler:^(NSError *error) {
                                      XCTAssertNil(error);
                                      [testExpectation fulfill];
                                  }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    
    
    
    XCTAssertEqual(numberOfFetchedMetadata,1 + systemItemsCount);
    XCTAssertNotNil(fetchedMetadata);
    XCTAssertEqualObjects(fetchedMetadata.summaryValues[@"key1"],item1SummaryValues[@"key1"]);
    XCTAssertEqualObjects(fetchedMetadata.summaryValues[@"key2"],item1SummaryValues[@"key2"]);
    XCTAssert([beforeFirstPutDate compare:fetchedMetadata.summaryValues[@"_created"]] != NSOrderedDescending);
    XCTAssert([afterFirstPutDate compare:fetchedMetadata.summaryValues[@"_created"]] != NSOrderedAscending);
    XCTAssertNil(fetchedMetadata.summaryValues[@"_modified"]);
    XCTAssertNil(fetchedMetadata.summaryValues[@"_v"]);
    
    
    
    NSDate *beforeSecondPutDate = [NSDate dateWithTimeIntervalSinceNow:-1];
    
    NSData *item2Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    QredoVaultItem *item2 = [QredoVaultItem vaultItemWithMetadata:fetchedMetadata value:item2Data];
    testExpectation = [self expectationWithDescription:@"Second put"];
    [vault putItem:item2
 completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error)
     {
         XCTAssertNil(error);
         item1Descriptor = newItemMetadata.descriptor;
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    NSDate *afterSecondPutDate = [NSDate dateWithTimeIntervalSinceNow:+1];
    
    testExpectation = [self expectationWithDescription:@"Second get"];
    [vault getItemWithDescriptor:item1Descriptor
               completionHandler:^(QredoVaultItem *vaultItem,NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"],item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"],item1SummaryValues[@"key2"]);
         //XCTAssert([fetchedMetadata.summaryValues[@"_created"] compare:vaultItem.metadata.summaryValues[@"_created"]] == NSOrderedSame);
         //XCTAssert([beforeSecondPutDate compare:vaultItem.metadata.summaryValues[@"_modified"]] == NSOrderedAscending);
         //XCTAssert([afterSecondPutDate compare:vaultItem.metadata.summaryValues[@"_modified"]] == NSOrderedDescending);
         //
         //XCTAssertEqualObjects([fetchedMetadata.descriptor valueForKey:@"sequenceValue"], vaultItem.metadata.summaryValues[@"_v"]);
         XCTAssert([vaultItem.value
                    isEqualToData:item2Data]);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
}


-(void)testDeleteItems {
    __block XCTestExpectation *testExpectation = nil;
    
    QredoVault *vault = [testClient1 defaultVault];
    
    
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{ @"key1":@"value1",
                                          @"key2":@"value2" };
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues];
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    
    testExpectation = [self expectationWithDescription:@"put"];
    [vault putItem:item1
 completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error)
     {
         XCTAssertNil(error);
         item1Descriptor = newItemMetadata.descriptor;
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    __block QredoVaultItemMetadata *fetchedMetadata = nil;
    __block NSUInteger numberOfFetchedMetadata = 0;
    testExpectation = [self expectationWithDescription:@"enumerate before delete"];
    [vault enumerateVaultItemsAllVersionsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop) {
        if (![systemItemDescriptors containsObject:vaultItemMetadata.descriptor]){
            fetchedMetadata = vaultItemMetadata;
        }
        
        numberOfFetchedMetadata++;
    }
                                  completionHandler:^(NSError *error) {
                                      XCTAssertNil(error);
                                      [testExpectation fulfill];
                                  }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    
    XCTAssertEqual(numberOfFetchedMetadata,1 + systemItemsCount);
    XCTAssertNotNil(fetchedMetadata);
    XCTAssert([fetchedMetadata.summaryValues
               containsDictionary:item1SummaryValues
               comparison:^BOOL (id a,id b) {
                   return [a isEqual:b];
               }]);
    XCTAssertNil(fetchedMetadata.summaryValues[@"_modified"]);
    XCTAssertNil(fetchedMetadata.summaryValues[@"_v"]);
    
    
    
    testExpectation = [self expectationWithDescription:@"delete"];
    __block QredoVaultItemDescriptor *deletedItemDesc;
    [vault deleteItem:fetchedMetadata
    completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor,NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(newItemDescriptor);
        deletedItemDesc = newItemDescriptor;
        [testExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    
    fetchedMetadata = nil;
    numberOfFetchedMetadata = 0;
    testExpectation = [self expectationWithDescription:@"enumerate after delete"];
    [vault enumerateVaultItemsAllVersionsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop) {
        if (![systemItemDescriptors containsObject:vaultItemMetadata.descriptor]){
            fetchedMetadata = vaultItemMetadata;
        }
        
        numberOfFetchedMetadata++;
    }
                                  completionHandler:^(NSError *error) {
                                      XCTAssertNil(error);
                                      [testExpectation fulfill];
                                  }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    
    //items will still be there
    XCTAssertEqual(numberOfFetchedMetadata,systemItemsCount + 2);
    XCTAssertNotNil(fetchedMetadata);
    
    
    
    
    testExpectation = [self expectationWithDescription:@"get metadata of a deleted item"];
    [vault getItemMetadataWithDescriptor:deletedItemDesc
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata,NSError *error) {
                           XCTAssertNil(vaultItemMetadata);
                           XCTAssertNil(error);
                           [testExpectation fulfill];
                       }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    
    testExpectation = [self expectationWithDescription:@"get a deleted item"];
    [vault getItemWithDescriptor:deletedItemDesc
               completionHandler:^(QredoVaultItem *vaultItem,NSError *error) {
                   XCTAssertNil(vaultItem);
                   XCTAssert(error);
                   [testExpectation fulfill];
               }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
}


@end
