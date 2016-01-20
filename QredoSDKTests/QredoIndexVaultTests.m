//
//  QredoIndexVaultTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 02/12/2015.
//
//

#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoVault.h"
#import "QredoTestUtils.h"
#import "QredoVaultPrivate.h"
#import "QredoLocalIndex.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoIndexVault.h"
#import "QredoIndexVaultItem.h"
#import "QredoIndexVaultItemMetadata.h"

//#import "PDDebugger.h"

@interface QredoIndexVaultTests :XCTestCase

@end

@implementation QredoIndexVaultTests

QredoClient *client1;
QredoVault *vault;
QredoLocalIndex *qredoLocalIndex;

QredoClient *client2;
QredoVault *vault2;
QredoLocalIndex *qredoLocalIndex2;

NSDate *myTestDate;
NSNumber *testNumber;



- (void)testSearch {
    for (int i=0; i<300; i++) {
        [self createTestItemInVault:vault key1Value:[NSString stringWithFormat:@"some value continaing %i",i]];
    }
    [self summaryValueTestSearch:3];
}



-(void)testUpdateAccessDatePut{
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [QredoTestUtils randomStringWithLength:1024];
    long startSize = [vault cacheFileSize];
    [self createLarge1MTestItem:vault];
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before+1 ,@"Item shouldn't be added to cache as it is disabled Before %ld After %ld", (long)before, (long)after);
    long endSize = [vault cacheFileSize];
    NSLog(@"Start:%ld  End:%ld", startSize, endSize);
}



-(void)testCoredataCacheEstimateConstants{
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

    NSLog(@"Start  Size on Disk = %ld", startFile);;
    NSLog(@"End    Size on Disk = %ld", endFile);
    
    long sizeOfPayload      = recordCount *vaultSize;
    long sizeOfMetdadata    = (recordCount * metadataCount) * metaSize;
    long recordSize = (vaultSize+(metaSize*metadataCount))* recordCount;
    
    NSLog(@"Overhead per record is          = %ld", (endFile - startFile - recordSize)/recordCount);
    NSLog(@"Overhead per metadata record is = %ld", (endFile - startFile - recordSize)/recordCount/metadataCount);
    NSLog(@"Metadata size is                = %ld", metadataCount*metaSize);

    NSLog(@"Size on disk is       %ld",  endFile);
    NSLog(@"Index size stimate is %lld",[qredoLocalIndex.cacheInvalidator totalCacheSizeEstimate]);
    
    NSLog(@"*** Difference between estimate & actual %0.2f",(float)endFile/(float)[qredoLocalIndex.cacheInvalidator totalCacheSizeEstimate]);
 */
    
}
    


-(void)testFillWithMetadata{
    [qredoLocalIndex purgeAll];
    QredoIndexVault *qredoIndexVault = qredoLocalIndex.qredoIndexVault;
    [vault setMaxCacheSize:10000];
    int recordCount = 20;
    
    for (int i=0;i<recordCount;i++){
        [self createVaultItemSize:1 metadataSize:1000];
    }
    [qredoLocalIndex saveAndWait];
    
    
    long long endValueSize     = qredoIndexVault.valueTotalSizeValue;
    long long endMetadataSize  = qredoIndexVault.metadataTotalSizeValue;
    
    XCTAssertTrue(recordCount == [self countRecords:@"QredoIndexVaultItem"],@"Failed to import the correct number of records");
    XCTAssertTrue([self countRecords:@"QredoIndexVaultItemPayload"]==0,@"Failed to remove all the Values");
}


-(void)testCacheFill{
    [qredoLocalIndex purgeAll];
    int recordCount = 100;

    for (int i=0;i<recordCount;i++){
         [self createVaultItemSize:200000 metadataSize:500];
    }
    [qredoLocalIndex saveAndWait];

    XCTAssertTrue(recordCount == [self countRecords:@"QredoIndexVaultItem"],@"Failed to import the correct number of records");
    XCTAssertTrue([self countRecords:@"QredoIndexVaultItemPayload"]<100,@"Failed to drop some item payloads");
}


-(void)testLastAccessTimes{
    //Test to ensure that different types of cache access cause the last access date/time to be updated
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [QredoTestUtils randomStringWithLength:1024];
    long startSize = [vault cacheFileSize];
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    [qredoLocalIndex saveAndWait];
    
    QredoIndexVaultItem *indexVaultItem = [qredoLocalIndex getIndexVaultItemFor:junk1];
    NSDate *date1 = indexVaultItem.latest.lastAccessed;
    
    sleep(1);
    QredoVaultItem *vaultItem1 =[qredoLocalIndex getVaultItemFromIndexWithDescriptor:junk1.descriptor];
    NSDate *date2 = indexVaultItem.latest.lastAccessed;
    XCTAssertFalse([date1 isEqualToDate:date2],@"getVaultItemFromIndexWithDescriptor Access to item not registered in cache");

    
    sleep(1);
    QredoVaultItemMetadata *metadata =[qredoLocalIndex getMetadataFromIndexWithDescriptor:junk1.descriptor];
    NSDate *date3 = indexVaultItem.latest.lastAccessed;
    XCTAssertFalse([date2 isEqualToDate:date3],@"getMetadataFromIndexWithDescriptor Access to item not registered in cache");
   
    
    sleep(1);
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@", randomKeyValue];
    __block int count =0;
    
    [qredoLocalIndex enumerateSearch:searchTest withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        count++;
    } completionHandler:^(NSError *error) {
    }];
    NSDate *date4 = indexVaultItem.latest.lastAccessed;
    XCTAssertFalse([date3 isEqualToDate:date4],@"enumerateSearch Access to item not registered in cache");
}


-(void)testDisableMetadataCache{
    NSInteger before = [qredoLocalIndex count];
    [vault metadataCacheEnabled:NO];
    NSString *randomKeyValue = [QredoTestUtils randomStringWithLength:32];
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before ,@"Item shouldn't be added to cache as it is disabled Before %ld After %ld", (long)before, (long)after);
}



-(void)testDisableValueCache{
    NSInteger before = [qredoLocalIndex count];
    [vault valueCacheEnabled:NO];
    NSString *randomKeyValue = [QredoTestUtils randomStringWithLength:32];
    
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before+1 ,@"Item hasn't been correctly added to the cache Before %ld After %ld", (long)before, (long)after);
    
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@", randomKeyValue];
    
    __block int count =0;
    __block QredoVaultItemMetadata *checkVaultMetaData;
    [qredoLocalIndex enumerateSearch:searchTest withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        checkVaultMetaData = vaultMetaData;
        count++;
    } completionHandler:^(NSError *error) {
    }];
    
    
    //metadata should come from the cache
    XCTAssert(count==1,"Incorrect number of items found");
    XCTAssert(checkVaultMetaData.origin == QredoVaultItemOriginCache,@"Vault item doesnt come from the cache/index");
    

    //value should come from the server (not cache)
    QredoVaultItem *vaultItem = [self getItemWithDescriptor:checkVaultMetaData inVault:vault];
    XCTAssertNotNil(vaultItem);
    XCTAssert(vaultItem.metadata.origin == QredoVaultItemOriginServer,@"Vault Item doesnt come from server");
    
}



-(void)testPersistentFileSize{
    long initialSize = [vault cacheFileSize];
    NSString * randomVal = [QredoTestUtils randomStringWithLength:4096];
    for (int i=0; i<10; i++) {
        [self createTestItemInVault:vault key1Value:randomVal];
    }
    //flush to disk
    [qredoLocalIndex saveAndWait];
    long finalSize = [vault cacheFileSize];
    XCTAssert(finalSize>initialSize,@"Persistent store filesize didnt grow in size when a new item is added");
    
}


- (void)testEmptyPredicate {
    NSInteger before = [qredoLocalIndex count];
    NSString * randomTag = [QredoTestUtils randomStringWithLength:32];
    
    QredoVaultItemMetadata *item1 = [self createTestItemInVault:vault key1Value:randomTag];
    QredoVaultItemMetadata *item2 = [self createTestItemInVault:vault key1Value:randomTag];
    QredoVaultItemMetadata *item3 = [self createTestItemInVault:vault key1Value:@"value2"];
    
    NSInteger after = [qredoLocalIndex count];
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@", randomTag];
    __block int count =0;
    
    [qredoLocalIndex enumerateSearch:nil withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        count++;
    } completionHandler:^(NSError *error) {
        XCTAssertNotNil(error);
        XCTAssert(count==0,@"Count should be zero for nil predicate");
    }];
}


- (void)testMultipleClientsAndVaults {
    [self authoriseSecondClient:[QredoTestUtils randomPassword]];
    
    XCTAssertNotEqual(client1, client2,@"Error creating clients");
    XCTAssertNotEqual(vault, vault2,@"Error creating vaults");
    XCTAssertNotEqual(qredoLocalIndex, qredoLocalIndex2,@"Error creating localIndexes");
    
    NSInteger client1count1 = [qredoLocalIndex count];
    NSInteger client2count1 = [qredoLocalIndex2 count];
    
    [self createTestItemInVault:vault key1Value:[QredoTestUtils randomStringWithLength:32]];
    
    NSInteger client1count2 = [qredoLocalIndex count];
    NSInteger client2count2 = [qredoLocalIndex2 count];
    
    XCTAssertTrue(client1count2 == client1count1+1,@"failed to insert new item");
    XCTAssertTrue(client2count1 == client2count2,@"incorrectly added new item to the wrong client");
    
    [self createTestItemInVault:vault2 key1Value:[QredoTestUtils randomStringWithLength:32]];
    NSInteger client1count3 = [qredoLocalIndex count];
    NSInteger client2count3 = [qredoLocalIndex2 count];
    
    XCTAssertTrue(client1count3 == client1count2,@"incorrectly added new item to the wrong client");
    XCTAssertTrue(client2count3 == client2count2+1,@"failed to insert new item");
}


- (void)testIndexSource {
    
    //put item in index
    //delete item from index
    //clear cache (reset watermark)
    //wait for it to populate from server
    //check that the item requests the vault items value from the server
    
    
    //check item is in index
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [QredoTestUtils randomStringWithLength:32];
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + 1,@"Failed to put new LocalIndex item Before %ld After %ld", (long)before, (long)after);
    
    //check metadata is set
    QredoVaultItem *vaultItem = [self getItemWithDescriptor:junk1 inVault:vault];
    NSString *key1Value =vaultItem.metadata.summaryValues[@"key1"];
    XCTAssert([key1Value isEqualToString:randomKeyValue],@"Metadata data in vault item not set correctly");
    XCTAssert(vaultItem.metadata.origin == QredoVaultItemOriginCache,@"Metata data in vault item not set correctly");
    
    //check value is set
    NSString *str = @"this is some fixed test data";
    NSData* item1Data = [str dataUsingEncoding:NSUTF8StringEncoding];
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
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        receivedAfterPurgeExpectation = nil;
    }];
    
    //check that when we retrieve the item it now is not in the cache and so its origin is QredoVaultItemOriginServer
    QredoVaultItem *vaultItem2 = [self getItemWithDescriptor:incomingMetadata inVault:vault];
    NSString *key1Value2 =vaultItem.metadata.summaryValues[@"key1"];
    XCTAssert([key1Value2 isEqualToString:randomKeyValue],@"Metadata data in vault item not set correctly");
    XCTAssert(vaultItem2.metadata.origin == QredoVaultItemOriginServer,@"Metata data in vault item not set correctly");
    //NSLog(@"testSimplePut Before %ld After %ld", (long)before, (long)after);
}


- (void)testSimplePut {
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [QredoTestUtils randomStringWithLength:32];
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + 1,@"Failed to put new LocalIndex item Before %ld After %ld", (long)before, (long)after);
    //NSLog(@"testSimplePut Before %ld After %ld", (long)before, (long)after);
}


- (void)testMultiplePut {
    NSInteger before = [qredoLocalIndex count];
    int addCount = 20;
    for (int i=0; i<addCount; i++) {
        NSString *randomKeyValue = [QredoTestUtils randomStringWithLength:32];
        QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    }
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + addCount,@"Failed to put new LocalIndex item");
    //NSLog(@"testMultiplePut Before %ld After %ld", (long)before, (long)after);
}


- (void)testEnumerateRandomClient {
    NSInteger before = [qredoLocalIndex count];
    //NSLog(@"Count before %ld", (long)before);
    NSString * randomTag = [QredoTestUtils randomStringWithLength:32];
    
    QredoVaultItemMetadata *item1 = [self createTestItemInVault:vault key1Value:randomTag];
    QredoVaultItemMetadata *item2 = [self createTestItemInVault:vault key1Value:randomTag];
    QredoVaultItemMetadata *item3 = [self createTestItemInVault:vault key1Value:@"value2"];
    
    NSInteger after = [qredoLocalIndex count];
    //NSLog(@"Count after %ld", (long)after);
    
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@", randomTag];
    
    __block int count =0;
    
    [qredoLocalIndex enumerateSearch:searchTest withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        count++;
    } completionHandler:^(NSError *error) {
       //NSLog(@"Found %i matches",count);
    }];
    
    
    XCTAssert(after == before+3,@"Failed to add 3 items After:%ld  Before:%ld", (long)after, (long)before);
    XCTAssert(count == 2,@"Failed to find 2 matches in search Found %i", count);
}


- (void)testItemDelete {
    NSInteger before = [qredoLocalIndex count];
    
    QredoVaultItemMetadata *meta1 = [self createTestItemInVault:vault key1Value:@"chris"];
    
    QredoVaultItem *item1 = [self getItemWithDescriptor:meta1 inVault:vault];
    QredoVaultItemMetadata *meta2 = [self updateItem:item1 inVault:vault];
    
    NSInteger afterPut = [qredoLocalIndex count];
    XCTAssert(afterPut == before + 1,@"Failed to put new LocalIndex item");
    
    [qredoLocalIndex deleteItem:meta1.descriptor];
    
    NSInteger afterDelete = [qredoLocalIndex count];
    XCTAssert(afterDelete == before,@"Failed to delete LocalIndex item");
}


- (void)testIndexPutGet {
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:@"value1"];
    QredoVaultItemMetadata *meta1 = [self createTestItemInVault:vault key1Value:@"chris"];
    QredoVaultItem *item1 = [self getItemWithDescriptor:meta1 inVault:vault];
    QredoVaultItemMetadata *meta2 = [self updateItem:item1 inVault:vault];
    QredoVaultItemMetadata *junk2 = [self createTestItemInVault:vault key1Value:@"value1"];
    
    QredoVaultItemDescriptor *searchDescriptorWithOnlyItemId =  [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:nil itemId:meta1.descriptor.itemId];
    QredoVaultItemMetadata *retrievedFromCacheMetatadata =      [qredoLocalIndex getMetadataFromIndexWithDescriptor:searchDescriptorWithOnlyItemId];
    
    XCTAssertTrue([[retrievedFromCacheMetatadata.summaryValues objectForKey:@"key1"] isEqualToString:@"chris"],@"Summary data is incorrect");
    XCTAssertTrue([[retrievedFromCacheMetatadata.summaryValues objectForKey:@"key2"] isEqualToString:@"value2"],@"Summary data is incorrect");
    XCTAssertTrue([[retrievedFromCacheMetatadata.summaryValues objectForKey:@"key3"] isEqual:testNumber],@"Summary data is correct");
    
    NSDate *ret =(NSDate*)[retrievedFromCacheMetatadata.summaryValues objectForKey:@"key4"];
    
    
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"key like %@ && value.date==%@", @"key*", myTestDate];
    
    __block int count =0;
    [qredoLocalIndex enumerateSearch:searchTest withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        //NSLog(@"Found a match for %@", vaultMetaData.descriptor.itemId);
        count++;
    } completionHandler:^(NSError *error) {
        NSLog(@"Current Values = %i",count);
    }];
    
    
    count =0;
    [qredoLocalIndex enumerateSearch:searchTest withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        //NSLog(@"Found a match for %@", vaultMetaData.descriptor.itemId);
        count++;
    } completionHandler:^(NSError *error) {
        
        NSLog(@"All Values = %i",count);
    }];
}



- (void)testPurge {
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
#pragma Private


- (void)setUp {
    [super setUp];
    myTestDate = [NSDate date];
    testNumber = [NSNumber numberWithInt:3];
    self.continueAfterFailure = YES;
    [self authoriseClient:[QredoTestUtils randomPassword]];
}


- (void)tearDown {
    [super tearDown];
}


- (void)summaryValueTestSearch:(int)expectedMatches {
    //this search term returns each 100th item
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"key=%@ && value.string CONTAINS %@", @"key1", @"99"];
    
    __block int count =0;
    [qredoLocalIndex enumerateSearch:searchTest withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        count++;
    } completionHandler:^(NSError *error) {
        XCTAssert(expectedMatches==count,@"Did not match the correct number of expected matches");
        NSLog(@"Search Matched %i items",count);
    }];
    
}


- (void)authoriseClient:(NSString*)password {
    
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client1"];
    
    
    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:password
                                 options:nil
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           client1 = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        clientExpectation = nil;
    }];
    vault = client1.defaultVault;
    qredoLocalIndex = client1.defaultVault.localIndex;
    
    XCTAssertNotNil(client1);
    XCTAssertNotNil(vault);
    XCTAssertNotNil(qredoLocalIndex);
    
    
}


- (void)authoriseSecondClient:(NSString*)password {
    
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client2"];
    
    
    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:password
                                 options:nil
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           client2 = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        clientExpectation = nil;
    }];
    vault2 = client2.defaultVault;
    qredoLocalIndex2 = client2.defaultVault.localIndex;
    
    
    XCTAssertNotNil(client2);
    XCTAssertNotNil(vault2);
    XCTAssertNotNil(qredoLocalIndex2);
    
    
}


- (NSData*)randomDataWithLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: length];
    for (unsigned int i = 0; i < length; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    } return mutableData;
}


- (QredoVaultItem*)getItemWithDescriptor:(QredoVaultItemMetadata *)metadata inVault:(QredoVault *)vault {
    QredoVaultItemDescriptor *item1Descriptor = metadata.descriptor;
    __block XCTestExpectation  *testExpectation = [self expectationWithDescription:@"Get item"];
    __block QredoVaultItem *retrievedVaultItem = nil;
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         retrievedVaultItem = vaultItem;
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
    return retrievedVaultItem;
}


- (QredoVaultItemMetadata *)updateItem:(QredoVaultItem *)item1 inVault:(QredoVault *)vault {
    
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(newItemMetadata);
         createdItemMetaData = newItemMetadata;
         [testExpectation fulfill];
     }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
    return createdItemMetaData;
}


- (QredoVaultItemMetadata *)createVaultItemSize:(int)vaultItemSize metadataSize:(int)metadataSize withMetadataRecords:(int)metadataRecords{
    //create a vault item with a specific size (both value & metadata)
    
    NSMutableDictionary *item1SummaryValues = [[NSMutableDictionary alloc] init];
    for (int i=0;i<metadataRecords;i++){
        NSString *key = [NSString stringWithFormat:@"key%i",i];
        NSString *metadataString          = [QredoTestUtils randomStringWithLength:metadataSize];
        [item1SummaryValues setObject:metadataString forKey:key];
    }
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                 accessLevel:0
                                                                               summaryValues:item1SummaryValues];
    
    
    NSString *valueString             = [QredoTestUtils randomStringWithLength:vaultItemSize];
    NSData* item1Data                 = [valueString dataUsingEncoding:NSUTF8StringEncoding];

    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item with defined size"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
        XCTAssertNil(error);
        XCTAssertNotNil(newItemMetadata);
        createdItemMetaData = newItemMetadata;
        [testExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
    return createdItemMetaData;
}


- (QredoVaultItemMetadata *)createVaultItemSize:(int)vaultItemSize metadataSize:(int)metadataSize{
    //create a vault item with a specific size (both value & metadata)
    NSString *valueString             = [QredoTestUtils randomStringWithLength:vaultItemSize];
    NSData* item1Data                 = [valueString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *metadataString          = [QredoTestUtils randomStringWithLength:metadataSize];
    
    NSDictionary *item1SummaryValues = @{@"key": metadataString};
    
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                 accessLevel:0
                                                                               summaryValues:item1SummaryValues];
    
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item with defined size"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
        XCTAssertNil(error);
        XCTAssertNotNil(newItemMetadata);
        createdItemMetaData = newItemMetadata;
        [testExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
    return createdItemMetaData;
}



- (QredoVaultItemMetadata *)createLarge1MTestItem:(QredoVault *)vault{
   
    NSString *str = [QredoTestUtils randomStringWithLength:1048576];
    
    NSData* item1Data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                        };
    
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                 accessLevel:0
                                                                               summaryValues:item1SummaryValues];
    
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put large item"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
        XCTAssertNil(error);
        XCTAssertNotNil(newItemMetadata);
        createdItemMetaData = newItemMetadata;
        [testExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
    return createdItemMetaData;
}


- (QredoVaultItemMetadata *)createTestItemInVault:(QredoVault *)vault key1Value:(NSString*)key1Value {
    
    NSString *str = @"this is some fixed test data";
    NSData* item1Data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *item1SummaryValues = @{@"key1": key1Value,
                                         @"key2": @"value2",
                                         @"key3": testNumber,
                                         @"key4": myTestDate};
    
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                 accessLevel:0
                                                                               summaryValues:item1SummaryValues];
    
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
        XCTAssertNil(error);
        XCTAssertNotNil(newItemMetadata);
        createdItemMetaData = newItemMetadata;
        [testExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
    return createdItemMetaData;
}


-(long)countRecords:(NSString *)entityName{
    //Count how many rows/records in the supplied entity
    NSManagedObjectContext *moc = qredoLocalIndex.qredoIndexVault.managedObjectContext;
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
    
    return [results count];
}


@end