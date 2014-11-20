//
//  QredoVaultUpdateTests.m
//  QredoSDK_nopods
//
//  Created by Gabriel Radu on 20/11/2014.
//
//

#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoTestConfiguration.h"
#import "QredoTestUtils.h"


@interface QredoVaultUpdateTests : XCTestCase

@end

@implementation QredoVaultUpdateTests

- (void)testGettingItems
{
    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:qtu_serviceURL]];
    QredoVault *vault = [qredo defaultVault];
    
    
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
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
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"], item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"], item1SummaryValues[@"key2"]);
         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         
         dispatch_semaphore_signal(semaphore);
     }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    [vault getItemMetadataWithDescriptor:item1Descriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItemMetadata);
         
         XCTAssertEqualObjects(vaultItemMetadata.summaryValues[@"key1"], item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItemMetadata.summaryValues[@"key2"], item1SummaryValues[@"key2"]);
         
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

- (void)testPutItems
{
    XCTestExpectation *testExpectation = nil;
    
    QredoClient *qredo = [[QredoClient alloc] initWithServiceURL:[NSURL URLWithString:qtu_serviceURL] options:@{QredoClientOptionVaultID: [QredoQUID QUID]}];
    QredoVault *vault = [qredo defaultVault];
    
    
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2"};
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                                            accessLevel:0
                                                                                                          summaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    
    NSDate *beforeFirstPutDate = [NSDate dateWithTimeIntervalSinceNow:-1];
    
    testExpectation = [self expectationWithDescription:@"First put"];
    [vault putItem:item1 completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)
     {
         item1Descriptor = newItemDescriptor;
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    NSDate *afterFirstPutDate = [NSDate dateWithTimeIntervalSinceNow:+1];
    
    testExpectation = [self expectationWithDescription:@"Get"];
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"], item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"], item1SummaryValues[@"key2"]);
         XCTAssert([beforeFirstPutDate compare:vaultItem.metadata.summaryValues[@"_created"]] != NSOrderedDescending);
         XCTAssert([afterFirstPutDate compare:vaultItem.metadata.summaryValues[@"_created"]] != NSOrderedAscending);
         XCTAssertNil(vaultItem.metadata.summaryValues[@"_modified"]);
         XCTAssertNil(vaultItem.metadata.summaryValues[@"_v"]);
         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    __block QredoVaultItemMetadata *fetchedMetadata = nil;
    __block NSUInteger numberOfFetchedMetadata = 0;
    testExpectation = [self expectationWithDescription:@"Enumerate"];
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        fetchedMetadata = vaultItemMetadata;
        numberOfFetchedMetadata++;
    } completionHandler:^(NSError *error) {
        [testExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    
    XCTAssertEqual(numberOfFetchedMetadata, 1);
    XCTAssertNotNil(fetchedMetadata);
    XCTAssertEqualObjects(fetchedMetadata.summaryValues[@"key1"], item1SummaryValues[@"key1"]);
    XCTAssertEqualObjects(fetchedMetadata.summaryValues[@"key2"], item1SummaryValues[@"key2"]);
    XCTAssert([beforeFirstPutDate compare:fetchedMetadata.summaryValues[@"_created"]] != NSOrderedDescending);
    XCTAssert([afterFirstPutDate compare:fetchedMetadata.summaryValues[@"_created"]] != NSOrderedAscending);
    XCTAssertNil(fetchedMetadata.summaryValues[@"_modified"]);
    XCTAssertNil(fetchedMetadata.summaryValues[@"_v"]);
    
    
    
    NSDate *beforeSecondPutDate = [NSDate dateWithTimeIntervalSinceNow:-1];
    
    NSData *item2Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    QredoVaultItem *item2 = [QredoVaultItem vaultItemWithMetadata:fetchedMetadata value:item2Data];
    testExpectation = [self expectationWithDescription:@"Second put"];
    [vault putItem:item2 completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error)
     {
         item1Descriptor = newItemDescriptor;
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    NSDate *afterSecondPutDate = [NSDate dateWithTimeIntervalSinceNow:+1];
    
    testExpectation = [self expectationWithDescription:@"Second get"];
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"], item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"], item1SummaryValues[@"key2"]);
         XCTAssert([fetchedMetadata.summaryValues[@"_created"] compare:vaultItem.metadata.summaryValues[@"_created"]] == NSOrderedSame);
         XCTAssert([beforeSecondPutDate compare:vaultItem.metadata.summaryValues[@"_modified"]] == NSOrderedAscending);
         XCTAssert([afterSecondPutDate compare:vaultItem.metadata.summaryValues[@"_modified"]] == NSOrderedDescending);
         
         XCTAssertEqualObjects([fetchedMetadata.descriptor valueForKey:@"sequenceValue"], vaultItem.metadata.summaryValues[@"_v"]);
         XCTAssert([vaultItem.value isEqualToData:item2Data]);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}


@end
