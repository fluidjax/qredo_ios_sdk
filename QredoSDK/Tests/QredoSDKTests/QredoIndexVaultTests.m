/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoVault.h"
#import "QredoTestUtils.h"
#import "QredoVaultPrivate.h"
#import "QredoLocalIndex.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoIndexVault.h"
#import "QredoIndexVaultItem.h"
#import "QredoIndexVaultItemMetadata.h"
#import "QredoNetworkTime.h"

//#import "PDDebugger.h"

@interface QredoIndexVaultTests :QredoXCTestCase

@end

@implementation QredoIndexVaultTests


QredoVault *vault;
QredoLocalIndex *qredoLocalIndex;

QredoVault *vault2;
QredoLocalIndex *qredoLocalIndex2;

NSDate *myTestDate;
NSNumber *testNumber;




-(void)setUp {
    [super setUp];
    [self initLogging];
    
    myTestDate = [QredoNetworkTime dateTime];
    testNumber = [NSNumber numberWithInt:3];
    self.continueAfterFailure = YES;
    
    [self createRandomClient1];
    vault = testClient1.defaultVault;
    qredoLocalIndex = testClient1.defaultVault.localIndex;

    
    [self createRandomClient2];
    vault2 = testClient2.defaultVault;
    qredoLocalIndex2 = testClient2.defaultVault.localIndex;

    
    XCTAssertNotNil(vault);
    XCTAssertNotNil(qredoLocalIndex);
    
}



-(void)initLogging {
    [QredoLogger addLoggingForClassName:@"QredoVault"];
    [QredoLogger addLoggingForClassName:@"QredoLocalIndexDataStore"];
}


-(void)testSearch {
    for (int i = 0; i < 300; i++){
        [self createTestItemInVault:vault key1Value:[NSString stringWithFormat:@"some value continaing %i",i]];
    }
    
    [self summaryValueTestSearch:3];
}


-(void)testUpdateAccessDatePut {
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [self randomStringWithLength:1024];
    long long startSize = [vault cacheFileSize];
    
    [self createLarge1MTestItem:vault];
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + 1,@"Item shouldn't be added to cache as it is disabled Before %ld After %ld",(long)before,(long)after);
    long long endSize = [vault cacheFileSize];
    //QredoLogInfo(@"Start:%ld  End:%ld", startSize, endSize);
}


//-(void)testCoredataCacheEstimateConstants{
//This test was used as a utility (with rolling modifications) to determine the constants in QredoLocalIndexCacheInvalidation
//so the estimate of the coredata file size can be more accurate
//there is no need to run this as a standard test

/*
 [qredoLocalIndex purgeAll];
 [vault setMaxCacheSize:10000000000];
 long startFile = [vault cacheFileSize];
 
 long recordCount=1000;
 long vaultSize  = 1000;
 long metaSize       = 100;
 long metadataCount  = 10;
 
 for (int i=0;i<recordCount;i++){
 [self createVaultItemSize:(int)vaultSize metadataSize:(int)metaSize withMetadataRecords:(int)metadataCount];
 }
 
 long endFile = [vault cacheFileSize];
 
 QredoLogInfo(@"Start  Size on Disk = %ld", startFile);;
 QredoLogInfo(@"End    Size on Disk = %ld", endFile);
 
 long sizeOfPayload      = recordCount *vaultSize;
 long sizeOfMetdadata    = (recordCount * metadataCount) * metaSize;
 long recordSize = (vaultSize+(metaSize*metadataCount))* recordCount;
 
 QredoLogInfo(@"Overhead per record is          = %ld", (endFile - startFile - recordSize)/recordCount);
 QredoLogInfo(@"Overhead per metadata record is = %ld", (endFile - startFile - recordSize)/recordCount/metadataCount);
 QredoLogInfo(@"Metadata size is                = %ld", metadataCount*metaSize);
 
 QredoLogInfo(@"Size on disk is       %ld",  endFile);
 QredoLogInfo(@"Index size stimate is %lld",[qredoLocalIndex.cacheInvalidator totalCacheSizeEstimate]);
 
 QredoLogInfo(@"*** Difference between estimate & actual %0.2f",(float)endFile/(float)[qredoLocalIndex.cacheInvalidator totalCacheSizeEstimate]);
 */

//}



-(void)testFillCacheAfterMiss {
    [qredoLocalIndex purgeAll];
    
    
    //create item and make sure it has a value in the cache
    QredoVaultItemMetadata *meta =  [self createLarge1MTestItem:vault];
    long before = [self countRecords:@"QredoIndexVaultItem"];
    XCTAssertTrue([vault.localIndex hasValue:meta.descriptor],@"Vault item should have a value/payload");
    
    //delete the value in the cache
    [vault.localIndex deleteItemValue:meta.descriptor error:nil];
    long after = [self countRecords:@"QredoIndexVaultItem"];
    XCTAssertFalse([vault.localIndex hasValue:meta.descriptor],@"Vault item should have had the value/payload deleted");
    XCTAssert(before == after,@"Whole Item has been deleted - but it should still exist - just with no payload");
    
    
    //get the item from server - it should now be in the index
    [self getItemWithDescriptor:meta inVault:vault];
    XCTAssertTrue([vault.localIndex hasValue:meta.descriptor],@"Vault item should again have a value/payload");
}


-(void)testFillWithMetadata {
    [qredoLocalIndex purgeAll];
    
    QredoIndexVault *qredoIndexVault = qredoLocalIndex.qredoIndexVault;
    [vault setMaxCacheSize:10000];
    int recordCount = 20;
    
    for (int i = 0; i < recordCount; i++){
        [self createVaultItemSize:1 metadataSize:1000];
    }
    
    [qredoLocalIndex saveAndWait];
    
    
    long long endValueSize     = qredoIndexVault.valueTotalSizeValue;
    long long endMetadataSize  = qredoIndexVault.metadataTotalSizeValue;
    
    XCTAssertTrue(recordCount == [self countRecords:@"QredoIndexVaultItem"],@"Failed to import the correct number of records");
    XCTAssertTrue([self countRecords:@"QredoIndexVaultItemPayload"] == 0,@"Failed to remove all the Values");
}


-(void)testCacheFill {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    [qredoLocalIndex purgeAll];
    [vault setMaxCacheSize:280000];
    int recordCount = 100;
    
    for (int i = 0; i < recordCount; i++){
        [self createVaultItemSize:200000 metadataSize:500];
    }
    
    [qredoLocalIndex saveAndWait];
    
    XCTAssertTrue(recordCount == [self countRecords:@"QredoIndexVaultItem"],@"Failed to import the correct number of records");
    XCTAssertTrue([self countRecords:@"QredoIndexVaultItemPayload"] < 100,@"Failed to drop some item payloads");
}


-(void)testLastAccessTimes {
    //Test to ensure that different types of cache access cause the last access date/time to be updated
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [self randomStringWithLength:1024];
    long long startSize = [vault cacheFileSize];
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    
    [qredoLocalIndex saveAndWait];
    
    QredoIndexVaultItem *indexVaultItem = [qredoLocalIndex getIndexVaultItemFor:junk1];
    NSDate *date1 = indexVaultItem.latest.lastAccessed;
    
    sleep(1);
    QredoVaultItem *vaultItem1 = [qredoLocalIndex getVaultItemFromIndexWithDescriptor:junk1.descriptor];
    NSDate *date2 = indexVaultItem.latest.lastAccessed;
    XCTAssertFalse([date1 isEqualToDate:date2],@"getVaultItemFromIndexWithDescriptor Access to item not registered in cache");
    
    
    sleep(1);
    QredoVaultItemMetadata *metadata = [qredoLocalIndex getMetadataFromIndexWithDescriptor:junk1.descriptor];
    NSDate *date3 = indexVaultItem.latest.lastAccessed;
    XCTAssertFalse([date2 isEqualToDate:date3],@"getMetadataFromIndexWithDescriptor Access to item not registered in cache");
    
    
    sleep(1);
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@",randomKeyValue];
    __block int count = 0;
    
    [qredoLocalIndex enumerateSearch:searchTest
                           withBlock:^(QredoVaultItemMetadata *vaultMetaData,BOOL *stop) {
                               count++;
                           }
                   completionHandler:^(NSError *error) {
                   }];
    NSDate *date4 = indexVaultItem.latest.lastAccessed;
    XCTAssertFalse([date3 isEqualToDate:date4],@"enumerateSearch Access to item not registered in cache");
}


-(void)testDisableMetadataCache {
    NSInteger before = [qredoLocalIndex count];
    
    [vault metadataCacheEnabled:NO];
    NSString *randomKeyValue = [self randomStringWithLength:32];
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before,@"Item shouldn't be added to cache as it is disabled Before %ld After %ld",(long)before,(long)after);
}



-(void)testMetaDataCacheDisable {
    [vault metadataCacheEnabled:NO];
    NSInteger before = [qredoLocalIndex count];
    
    NSString *randomKeyValue = [self randomStringWithLength:32];
    
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before,@"Item has incorrectly been added to the cache  Before %ld After %ld",(long)before,(long)after);
    
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@",randomKeyValue];
    
    __block int count = 0;
    __block QredoVaultItemMetadata *checkVaultMetaData;
    [qredoLocalIndex enumerateSearch:searchTest
                           withBlock:^(QredoVaultItemMetadata *vaultMetaData,BOOL *stop) {
                               checkVaultMetaData = vaultMetaData;
                               count++;
                           }
                   completionHandler:^(NSError *error) {
                   }];
    
    
    //metadata should come from the cache
    XCTAssert(count == 0,"Incorrect number of items found");
    
    XCTAssert(checkVaultMetaData == nil,@"Vault item doesnt come from the cache/index");
    
    
    //value should come from the server (not cache)
    QredoVaultItem *vaultItem = [self getItemWithDescriptor:junk1 inVault:vault];
    XCTAssertNotNil(vaultItem);
    XCTAssert(vaultItem.metadata.origin == QredoVaultItemOriginServer,@"Vault Item doesnt come from server");
}


-(void)testEnableValueCache {
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [self randomStringWithLength:32];
    
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    NSInteger after = [qredoLocalIndex count];
    
    XCTAssert(after == before + 1,@"Item hasn't been correctly added to the cache Before %ld After %ld",(long)before,(long)after);
    
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@",randomKeyValue];
    
    __block int count = 0;
    __block QredoVaultItemMetadata *checkVaultMetaData;
    [qredoLocalIndex enumerateSearch:searchTest
                           withBlock:^(QredoVaultItemMetadata *vaultMetaData,BOOL *stop) {
                               checkVaultMetaData = vaultMetaData;
                               count++;
                           }
                   completionHandler:^(NSError *error) {
                   }];
    
    
    //metadata should come from the cache
    XCTAssert(count == 1,"Incorrect number of items found");
    XCTAssert(checkVaultMetaData.origin == QredoVaultItemOriginCache,@"Vault item doesnt come from the cache/index");
    
    
    //value should come from the server (not cache)
    QredoVaultItem *vaultItem = [self getItemWithDescriptor:checkVaultMetaData inVault:vault];
    XCTAssertNotNil(vaultItem);
    XCTAssert(vaultItem.metadata.origin == QredoVaultItemOriginCache,@"Vault Item doesnt come from server");
}


-(void)testDisableValueCache {
    NSInteger before = [qredoLocalIndex count];
    
    [vault valueCacheEnabled:NO];
    NSString *randomKeyValue = [self randomStringWithLength:32];
    
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + 1,@"Item hasn't been correctly added to the cache Before %ld After %ld",(long)before,(long)after);
    
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@",randomKeyValue];
    
    __block int count = 0;
    __block QredoVaultItemMetadata *checkVaultMetaData;
    [qredoLocalIndex enumerateSearch:searchTest
                           withBlock:^(QredoVaultItemMetadata *vaultMetaData,BOOL *stop) {
                               checkVaultMetaData = vaultMetaData;
                               count++;
                           }
                   completionHandler:^(NSError *error) {
                   }];
    
    
    //metadata should come from the cache
    XCTAssert(count == 1,"Incorrect number of items found");
    XCTAssert(checkVaultMetaData.origin == QredoVaultItemOriginCache,@"Vault item doesnt come from the cache/index");
    
    
    //value should come from the server (not cache)
    QredoVaultItem *vaultItem = [self getItemWithDescriptor:checkVaultMetaData inVault:vault];
    XCTAssertNotNil(vaultItem);
    XCTAssert(vaultItem.metadata.origin == QredoVaultItemOriginServer,@"Vault Item doesnt come from server");
}


-(void)testPersistentFileSize {
    long long initialSize = [vault cacheFileSize];
    NSString *randomVal = [self randomStringWithLength:4096];
    
    for (int i = 0; i < 10; i++){
        [self createTestItemInVault:vault key1Value:randomVal];
    }
    
    //flush to disk
    [qredoLocalIndex saveAndWait];
    long long finalSize = [vault cacheFileSize];
    XCTAssert(finalSize > initialSize,@"Persistent store filesize didnt grow in size when a new item is added");
}


-(void)testEmptyPredicate {
    __block int count = 0;
    
    [qredoLocalIndex enumerateSearch:nil
                           withBlock:^(QredoVaultItemMetadata *vaultMetaData,BOOL *stop) {
                               count++;
                           }
                   completionHandler:^(NSError *error) {
                       XCTAssertNotNil(error);
                       XCTAssert(count == 0,@"Count should be zero for nil predicate");
                   }];
}


-(void)testMultipleClientsAndVaults {

    
    XCTAssertNotEqual(testClient1,testClient2,@"Error creating clients");
    XCTAssertNotEqual(vault,vault2,@"Error creating vaults");
    XCTAssertNotEqual(qredoLocalIndex,qredoLocalIndex2,@"Error creating localIndexes");
    
    NSInteger client1count1 = [qredoLocalIndex count];
    NSInteger client2count1 = [qredoLocalIndex2 count];
    
    [self createTestItemInVault:vault key1Value:[self randomStringWithLength:32]];
    
    NSInteger client1count2 = [qredoLocalIndex count];
    NSInteger client2count2 = [qredoLocalIndex2 count];
    
    XCTAssertTrue(client1count2 == client1count1 + 1,@"failed to insert new item");
    XCTAssertTrue(client2count1 == client2count2,@"incorrectly added new item to the wrong client");
    
    [self createTestItemInVault:vault2 key1Value:[self randomStringWithLength:32]];
    NSInteger client1count3 = [qredoLocalIndex count];
    NSInteger client2count3 = [qredoLocalIndex2 count];
    
    XCTAssertTrue(client1count3 == client1count2,@"incorrectly added new item to the wrong client");
    XCTAssertTrue(client2count3 == client2count2 + 1,@"failed to insert new item");
}


//-(void)testIndexSourceMultiple{
//    for (int i=0;i<1000;i++){
//        NSLog(@"Count %i",i);
//        [self setUp];
//        [self testIndexSource];
//        [self tearDown];
//    }
//}


-(void)testIndexSource {
    //put item in index
    //delete item from index
    //clear cache (reset watermark)
    //wait for it to populate from server
    //check that the item requests the vault items value from the server
    
    
    //check item is in index
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [self randomStringWithLength:32];
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];

    sleep(2);
    
    NSInteger after = [qredoLocalIndex count];
    
    XCTAssert(after == before + 1,@"Failed to put new LocalIndex item Before %ld After %ld",(long)before,(long)after);
    
    //check metadata is set
    QredoVaultItem *vaultItem = [self getItemWithDescriptor:junk1 inVault:vault];
    NSString *key1Value = vaultItem.metadata.summaryValues[@"key1"];
    XCTAssert([key1Value isEqualToString:randomKeyValue],@"Metadata data in vault item not set correctly");
    XCTAssert(vaultItem.metadata.origin == QredoVaultItemOriginCache,@"Metata data in vault item not set correctly");
    
    //check value is set
    NSString *str = @"this is some fixed test data";
    NSData *item1Data = [str dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssert([vaultItem.value isEqualToData:item1Data],"Value in vault item not set correctly");
    
    //clear cache
    [qredoLocalIndex purge];
    NSInteger afterPurge = [qredoLocalIndex count];
    XCTAssert(afterPurge == after - 1,@"Failed to purge index");
    
    //wait for index to be re-populated from server
    __block XCTestExpectation *receivedAfterPurgeExpectation = [self expectationWithDescription:@"receivedAfterPurgeExpectation"];
    __block QredoVaultItemMetadata *incomingMetadata;
    
    
    [vault addMetadataIndexObserver:^(QredoVaultItemMetadata *vaultMetaData) {
        
        incomingMetadata = vaultMetaData;
        [receivedAfterPurgeExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     receivedAfterPurgeExpectation = nil;
                                 }];
    
    //check that when we retrieve the item it now is not in the cache and so its origin is QredoVaultItemOriginServer
    QredoVaultItem *vaultItem2 = [self getItemWithDescriptor:incomingMetadata inVault:vault];
    NSString *key1Value2 = vaultItem.metadata.summaryValues[@"key1"];
    XCTAssert([key1Value2 isEqualToString:randomKeyValue],@"Metadata data in vault item not set correctly");
    XCTAssert(vaultItem2.metadata.origin == QredoVaultItemOriginServer,@"Metata data in vault item not set correctly");
    //QredoLogInfo(@"testSimplePut Before %ld After %ld", (long)before, (long)after);
}


-(void)testSimplePut {
    int testCount = 2;
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [self randomStringWithLength:32];
    
    [testClient1.defaultVault addMetadataIndexObserver];
    
    
    //wait for registration
    sleep(2);

    
    for (int i = 0; i < testCount; i++){
        QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    }
    sleep(2);

    
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + testCount,@"Failed to put new LocalIndex item Before %ld After %ld",(long)before,(long)after);
    //QredoLogInfo(@"testSimplePut Before %ld After %ld", (long)before, (long)after);
    [testClient1.defaultVault removeMetadataIndexObserver];
}


-(void)testMultiplePut {
    NSInteger before = [qredoLocalIndex count];
    int addCount = 5;
    
    for (int i = 0; i < addCount; i++){
        NSString *randomKeyValue = [self randomStringWithLength:32];
        QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    }
    
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + addCount,@"Failed to put new LocalIndex item");
    //QredoLogInfo(@"testMultiplePut Before %ld After %ld", (long)before, (long)after);
}


-(void)testEnumerateRandomClient {
    NSInteger before = [qredoLocalIndex count];
    //QredoLogInfo(@"Count before %ld", (long)before);
    NSString *randomTag = [self randomStringWithLength:32];
    
    QredoVaultItemMetadata *item1 = [self createTestItemInVault:vault key1Value:randomTag];
    QredoVaultItemMetadata *item2 = [self createTestItemInVault:vault key1Value:randomTag];
    QredoVaultItemMetadata *item3 = [self createTestItemInVault:vault key1Value:@"value2"];
    
    NSInteger after = [qredoLocalIndex count];
    //QredoLogInfo(@"Count after %ld", (long)after);
    
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@",randomTag];
    
    __block int count = 0;
    
    [qredoLocalIndex enumerateSearch:searchTest
                           withBlock:^(QredoVaultItemMetadata *vaultMetaData,BOOL *stop) {
                               count++;
                           }
                   completionHandler:^(NSError *error) {
                       //QredoLogInfo(@"Found %i matches",count);
                   }];
    
    
    XCTAssert(after == before + 3,@"Failed to add 3 items After:%ld  Before:%ld",(long)after,(long)before);
    XCTAssert(count == 2,@"Failed to find 2 matches in search Found %i",count);
}


-(void)testItemDelete {
    NSInteger before = [qredoLocalIndex count];
    
    QredoVaultItemMetadata *meta1 = [self createTestItemInVault:vault key1Value:@"chris"];
    
    QredoVaultItem *item1 = [self getItemWithDescriptor:meta1 inVault:vault];
    QredoVaultItemMetadata *meta2 = [self updateItem:item1 inVault:vault];
    
    NSInteger afterPut = [qredoLocalIndex count];
    
    XCTAssert(afterPut == before + 1,@"Failed to put new LocalIndex item");
    
    [qredoLocalIndex deleteItem:meta2.descriptor];
    
    NSInteger afterDelete = [qredoLocalIndex count];
    XCTAssert(afterDelete == before,@"Failed to delete LocalIndex item");
}


-(void)testPurge {
    NSInteger before = [qredoLocalIndex count];
    
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:@"value1"];
    QredoVaultItemMetadata *meta1 = [self createTestItemInVault:vault key1Value:@"chris"];
    QredoVaultItem *item1 = [self getItemWithDescriptor:meta1 inVault:vault];
    QredoVaultItemMetadata *meta2 = [self updateItem:item1 inVault:vault];
    QredoVaultItemMetadata *junk2 = [self createTestItemInVault:vault key1Value:@"value1"];
    
    NSInteger after = [qredoLocalIndex count];
    
    XCTAssert(after == before + 3,@"Failed to add new items");
    
    [vault purgeCache];
    NSInteger afterPurge = [qredoLocalIndex count];
    XCTAssert([qredoLocalIndex count] == 0,@"Failed to purge items");
}


#pragma mark
#pragma mark - Private





-(void)summaryValueTestSearch:(int)expectedMatches {
    //this search term returns each 100th item
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"key=%@ && value.string CONTAINS %@",@"key1",@"99"];
    
    __block int count = 0;
    
    [qredoLocalIndex enumerateSearch:searchTest
                           withBlock:^(QredoVaultItemMetadata *vaultMetaData,BOOL *stop) {
                               count++;
                           }
                   completionHandler:^(NSError *error) {
                       XCTAssert(expectedMatches == count,@"Did not match the correct number of expected matches");
                   }];
}





-(QredoVaultItem *)getItemWithDescriptor:(QredoVaultItemMetadata *)metadata inVault:(QredoVault *)vault {
    QredoVaultItemDescriptor *item1Descriptor = metadata.descriptor;
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"Get item"];
    __block QredoVaultItem *retrievedVaultItem = nil;
    
    [vault getItemWithDescriptor:item1Descriptor
               completionHandler:^(QredoVaultItem *vaultItem,NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         retrievedVaultItem = vaultItem;
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    return retrievedVaultItem;
}


-(QredoVaultItemMetadata *)updateItem:(QredoVaultItem *)item1 inVault:(QredoVault *)vault {
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    
    [vault putItem:item1
 completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(newItemMetadata);
         createdItemMetaData = newItemMetadata;
         [testExpectation fulfill];
     }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    return createdItemMetaData;
}


-(QredoVaultItemMetadata *)createVaultItemSize:(int)vaultItemSize metadataSize:(int)metadataSize withMetadataRecords:(int)metadataRecords {
    //create a vault item with a specific size (both value & metadata)
    
    NSMutableDictionary *item1SummaryValues = [[NSMutableDictionary alloc] init];
    
    for (int i = 0; i < metadataRecords; i++){
        NSString *key = [NSString stringWithFormat:@"key%i",i];
        NSString *metadataString          = [self randomStringWithLength:metadataSize];
        [item1SummaryValues setObject:metadataString forKey:key];
    }
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues];
    
    
    NSString *valueString             = [self randomStringWithLength:vaultItemSize];
    NSData *item1Data                 = [valueString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item with defined size"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    [vault putItem:item1
 completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
     XCTAssertNil(error);
     XCTAssertNotNil(newItemMetadata);
     createdItemMetaData = newItemMetadata;
     [testExpectation fulfill];
 }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    return createdItemMetaData;
}


-(QredoVaultItemMetadata *)createVaultItemSize:(int)vaultItemSize metadataSize:(int)metadataSize {
    //create a vault item with a specific size (both value & metadata)
    NSString *valueString             = [self randomStringWithLength:vaultItemSize];
    NSData *item1Data                 = [valueString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *metadataString          = [self randomStringWithLength:metadataSize];
    
    NSDictionary *item1SummaryValues = @{ @"key":metadataString };
    
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues];
    
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item with defined size"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    
    [vault putItem:item1
 completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
     XCTAssertNil(error);
     XCTAssertNotNil(newItemMetadata);
     createdItemMetaData = newItemMetadata;
     [testExpectation fulfill];
 }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    return createdItemMetaData;
}


-(QredoVaultItemMetadata *)createLarge1MTestItem:(QredoVault *)vault {
    NSString *str = [self randomStringWithLength:1048576];
    
    NSData *item1Data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *item1SummaryValues = @{ @"key1":@"value1",
                                          @"key2":@"value2",};
    
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues];
    
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put large item"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    
    [vault putItem:item1
 completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
     XCTAssertNil(error);
     XCTAssertNotNil(newItemMetadata);
     createdItemMetaData = newItemMetadata;
     [testExpectation fulfill];
 }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    return createdItemMetaData;
}


-(QredoVaultItemMetadata *)createTestItemInVault:(QredoVault *)vault key1Value:(NSString *)key1Value {
    NSString *str = @"this is some fixed test data";
    NSData *item1Data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *item1SummaryValues = @{ @"key1":key1Value,
                                          @"key2":@"value2",
                                          @"key3":testNumber,
                                          @"key4":myTestDate };
    
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues];
    
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    
    [vault putItem:item1  completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
     XCTAssertNil(error);
     XCTAssertNotNil(newItemMetadata);
     createdItemMetaData = newItemMetadata;
     [testExpectation fulfill];
 }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    return createdItemMetaData;
}


-(long)countRecords:(NSString *)entityName {
    //Count how many rows/records in the supplied entity
    NSManagedObjectContext *moc = qredoLocalIndex.qredoIndexVault.managedObjectContext;
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
    
    long count = [results count];
    
    return count;
}


-(void)testPutItemType1 {
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [self randomStringWithLength:32];
    
    [testClient1.defaultVault addMetadataIndexObserver];
    
    
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{ @"key1":@"test item",
                                          @"key2":@"value2" };
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadataDictionary:item1SummaryValues value:item1Data ];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"TestputItemType1"];
    [testClient1.defaultVault
     putItem:item1
     completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
         XCTAssertNil(error);
         XCTAssertNotNil(newItemMetadata);
         [testExpectation fulfill];
     }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + 1,@"Failed to put new LocalIndex item Before %ld After %ld",(long)before,(long)after);
}


-(void)testPutItemType3 {
    //There is an itemID in the index, with the same Sequence ID & previous Sequence Number
    //So this must be a new version of a locally created item
    
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [self randomStringWithLength:32];
    
    [testClient1.defaultVault addMetadataIndexObserver];
    
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{ @"key1":@"test item",
                                          @"key2":@"value2" };
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadataDictionary:item1SummaryValues value:item1Data ];
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"TestputItemType1"];
    __block QredoVaultItemMetadata *itemMetadata;
    
    [testClient1.defaultVault
     putItem:item1
     completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
         XCTAssertNil(error);
         XCTAssertNotNil(newItemMetadata);
         itemMetadata = newItemMetadata;
         [testExpectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + 1,@"Failed to put new LocalIndex item Before %ld After %ld",(long)before,(long)after);
    
    NSData *item1Data2 = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues2 = @{ @"key1":@"test item",
                                           @"key2":@"NEWVALUE" };
    
    QredoVaultItem *item2 = [QredoVaultItem vaultItemWithMetadataDictionary:item1SummaryValues2 value:item1Data2 ];
    item2.metadata.descriptor = itemMetadata.descriptor;
    __block XCTestExpectation *testExpectation2 = [self expectationWithDescription:@"TestputItemType1"];
    __block QredoVaultItemMetadata *itemMetadata2;
    
    [testClient1.defaultVault
     putItem:item2
     completionHandler:^(QredoVaultItemMetadata *newItemMetadata2,NSError *error) {
         XCTAssertNil(error);
         XCTAssertNotNil(newItemMetadata2);
         itemMetadata2 = newItemMetadata2;
         [testExpectation2 fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    NSInteger afterSecond = [qredoLocalIndex count];
    XCTAssert(afterSecond == after,@"There should not be a new item in the cache now Before %ld After %ld",(long)before,(long)after);
    
    NSString *val = [itemMetadata2.summaryValues objectForKey:@"key2"];
    XCTAssertTrue([val isEqualToString:@"NEWVALUE"]);
}


-(void)testPutItemType4 {
    //There is an itemID with the same Sequence ID & Sequqnce Number
    //So this is an existing item, sets its value
   
    
    
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [self randomStringWithLength:32];
    [testClient1.defaultVault addMetadataIndexObserver];
    [testClient2.defaultVault addMetadataIndexObserver];
    
    
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{ @"key1":@"test item",
                                          @"key2":@"value2" };
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadataDictionary:item1SummaryValues value:item1Data ];
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"TestputItemType1"];
    __block QredoVaultItemMetadata *itemMetadata;
    
    [testClient1.defaultVault
     putItem:item1
     completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
         XCTAssertNil(error);
         XCTAssertNotNil(newItemMetadata);
         itemMetadata = newItemMetadata;
         [testExpectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + 1,@"Failed to put new LocalIndex item Before %ld After %ld",(long)before,(long)after);
    
    
    //end of 1st put
    
    
    
    NSData *item1Data2 = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues2 = @{ @"key1":@"test item",
                                           @"key2":@"NEWVALUE" };
    
    QredoVaultItem *item2 = [QredoVaultItem vaultItemWithMetadataDictionary:item1SummaryValues2 value:item1Data2 ];
    item2.metadata.descriptor = [[QredoVaultItemDescriptor alloc] initWithSequenceId:nil sequenceValue:0 itemId:item1.metadata.descriptor.itemId];
    
    
    
    __block XCTestExpectation *testExpectation2 = [self expectationWithDescription:@"TestputItemType1"];
    __block QredoVaultItemMetadata *itemMetadata2;
    
    
    
    
    
    
    [testClient2.defaultVault
     putItem:item2
     completionHandler:^(QredoVaultItemMetadata *newItemMetadata2,NSError *error) {
         XCTAssertNil(error);
         XCTAssertNotNil(newItemMetadata2);
         itemMetadata2 = newItemMetadata2;
         [testExpectation2 fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     testExpectation = nil;
                                 }];
    
    NSInteger afterSecond = [qredoLocalIndex count];
    XCTAssert(afterSecond == after,@"There should not be a new item in the cache now Before %ld After %ld",(long)before,(long)after);
    
    NSString *val = [itemMetadata2.summaryValues objectForKey:@"key2"];
    XCTAssertTrue([val isEqualToString:@"NEWVALUE"]);
}


@end
