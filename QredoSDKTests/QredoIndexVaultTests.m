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
#import "QredoLocalIndexPrivate.h"

//#import "PDDebugger.h"

@interface QredoIndexVaultTests : XCTestCase

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




-(void)testMultipleClientsAndVaults{
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
    XCTAssertTrue(client2count1 == client2count2  ,@"incorrectly added new item to the wrong client");
    
    
    [self createTestItemInVault:vault2 key1Value:[QredoTestUtils randomStringWithLength:32]];
    
    NSInteger client1count3 = [qredoLocalIndex count];
    NSInteger client2count3 = [qredoLocalIndex2 count];

    XCTAssertTrue(client1count3 == client1count2,@"incorrectly added new item to the wrong client");
        XCTAssertTrue(client2count3 == client2count2+1  ,@"failed to insert new item");
    
}


-(void)testSimplePut{
    NSInteger before = [qredoLocalIndex count];
    NSString *randomKeyValue = [QredoTestUtils randomStringWithLength:32];
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + 1,@"Failed to put new LocalIndex item Before %ld After %ld", (long)before, (long)after);
    NSLog(@"testSimplePut Before %ld After %ld", (long)before, (long)after);
}


-(void)testMultiplePut{
    NSInteger before = [qredoLocalIndex count];
    int addCount = 20;
    for (int i=0;i<addCount;i++){
        NSString *randomKeyValue = [QredoTestUtils randomStringWithLength:32];
        QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:randomKeyValue];
    }
    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + addCount,@"Failed to put new LocalIndex item");
     NSLog(@"testMultiplePut Before %ld After %ld", (long)before, (long)after);
}


-(void)testEnumerateRandomClient{
    NSInteger before = [qredoLocalIndex count];
    NSLog(@"Count before %ld", (long)before);
    NSString * randomTag = [QredoTestUtils randomStringWithLength:32];
    
    QredoVaultItemMetadata *item1 = [self createTestItemInVault:vault key1Value:randomTag];
    QredoVaultItemMetadata *item2 = [self createTestItemInVault:vault key1Value:randomTag];
    QredoVaultItemMetadata *item3 = [self createTestItemInVault:vault key1Value:@"value2"];
    
    NSInteger after = [qredoLocalIndex count];
    NSLog(@"Count after %ld", (long)after);
    
     NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"value.string==%@", randomTag];
    
    __block int count =0;

    [qredoLocalIndex enumerateSearch:searchTest withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        count++;
    } completionHandler:^(NSError *error) {
        NSLog(@"Found %i matches",count);
    }];
    
   
    XCTAssert(after == before+3 ,@"Failed to add 3 items After:%ld  Before:%ld", (long)after, (long)before);
    XCTAssert(count == 2 ,@"Failed to find 2 matches in search Found %i", count);
}

-(void)testItemDelete{
    NSInteger before = [qredoLocalIndex count];
    
    QredoVaultItemMetadata *meta1 = [self createTestItemInVault:vault key1Value:@"chris"];
    
    QredoVaultItem *item1 = [self getItemWithDescriptor:meta1 inVault:vault];
    QredoVaultItemMetadata *meta2 = [self updateItem:item1 inVault:vault];
    
    NSInteger afterPut = [qredoLocalIndex count];
    XCTAssert(afterPut == before + 1,@"Failed to put new LocalIndex item");
    
    [qredoLocalIndex deleteItem:meta1.descriptor];
    
    NSInteger afterDelete = [qredoLocalIndex count];
    XCTAssert(afterDelete == before ,@"Failed to delete LocalIndex item");
}


-(void)testIndexPutGet{
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:@"value1"];
    QredoVaultItemMetadata *meta1 = [self createTestItemInVault:vault key1Value:@"chris"];
    QredoVaultItem *item1 = [self getItemWithDescriptor:meta1 inVault:vault];
    QredoVaultItemMetadata *meta2 = [self updateItem:item1 inVault:vault];
    QredoVaultItemMetadata *junk2 = [self createTestItemInVault:vault key1Value:@"value1"];
    
    QredoVaultItemDescriptor *searchDescriptorWithOnlyItemId =  [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:nil itemId:meta1.descriptor.itemId];
    QredoVaultItemMetadata *retrievedFromCacheMetatadata =      [qredoLocalIndex get:searchDescriptorWithOnlyItemId];

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


-(void)testPurge{
    NSInteger before = [qredoLocalIndex count];
    
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:@"value1"];
    QredoVaultItemMetadata *meta1 = [self createTestItemInVault:vault key1Value:@"chris"];
    QredoVaultItem *item1 = [self getItemWithDescriptor:meta1 inVault:vault];
    QredoVaultItemMetadata *meta2 = [self updateItem:item1 inVault:vault];
    QredoVaultItemMetadata *junk2 = [self createTestItemInVault:vault key1Value:@"value1"];

    NSInteger after = [qredoLocalIndex count];
    XCTAssert(after == before + 3 ,@"Failed to add new items");
    [qredoLocalIndex purge];
    NSInteger afterPurge = [qredoLocalIndex count];
    XCTAssert([qredoLocalIndex count] == 0 ,@"Failed to add new items");

}





-(void)testIndexSync{
    NSInteger count1 = [qredoLocalIndex count];
   
    QredoVaultItemMetadata *item1 = [self createTestItemInVault:vault key1Value:@"value1"];
    QredoVaultItemMetadata *item2 = [self createTestItemInVault:vault key1Value:@"value1"];
    QredoVaultItemMetadata *item3 = [self createTestItemInVault:vault key1Value:@"value1"];

    NSInteger count2 = [qredoLocalIndex count];
    
    XCTAssert(count2 == count1+3 ,@"Failed to add LocalIndex item");
    
    [qredoLocalIndex purge];
    NSInteger count3 = [qredoLocalIndex count];
    
    XCTAssert(count3 == 0 ,@"Failed to delete from LocalIndex");
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    __block int reportedSyncCount =0;
    
    
    [qredoLocalIndex syncIndexWithCompletion:^(int syncCount, NSError *error) {
        NSLog(@"Sync'd %i items", syncCount);
        reportedSyncCount = syncCount;
        [testExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError * _Nullable error) {
        testExpectation = nil;
    }];
    
     NSInteger count4 = [qredoLocalIndex count];
    
    
    XCTAssertEqual(count4, count2,"The added new items doesn't match the actual increase");
 
}


-(void)testLargeIndexSync{
   
    NSInteger before1 = [qredoLocalIndex count];
    
    static int itemCount1 =11;
    
    for (int i=0;i<itemCount1;i++){
        QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:@"value1"];
    }
    
    NSInteger after1 = [qredoLocalIndex count];
    XCTAssert(after1 == before1+itemCount1 ,@"Failed to add LocalIndex item");
    
    __block XCTestExpectation *testExpectation1 = [self expectationWithDescription:@"put item 1"];
    __block int reportedSyncCount1 =0;
    
    [qredoLocalIndex syncIndexWithCompletion:^(int syncCount, NSError *error) {
        reportedSyncCount1 = syncCount;
        [testExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError * _Nullable error) {
        testExpectation1 = nil;
    }];
    
    XCTAssertEqual(after1-before1, reportedSyncCount1,"The added new items doesn't match the actual increase");
    NSInteger afterSync1 = [qredoLocalIndex count];

    
    [qredoLocalIndex purge];
    NSInteger before2 = [qredoLocalIndex count];
    
    static int itemCount2 =13;
    
    for (int i=0;i<itemCount2;i++){
        QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault key1Value:@"value1"];
        [qredoLocalIndex putItemWithMetadata:junk1];
    }

    //NSLog(@"after add 3 items");
    NSInteger after2 = [qredoLocalIndex count];
    
    __block  XCTestExpectation *testExpectation2 = [self expectationWithDescription:@"put item 2"];
    __block int reportedSyncCount2 =0;
    
    [qredoLocalIndex syncIndexWithCompletion:^(int syncCount, NSError *error) {
        //NSLog(@"Sync'd #2 %i items", syncCount);
        reportedSyncCount2 = syncCount;
        [testExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError * _Nullable error) {
        testExpectation2 = nil;
    }];
    
    XCTAssertEqual(itemCount1+itemCount2, reportedSyncCount2,"The added new items doesn't match the actual increase");
    NSInteger afterSync2 = [qredoLocalIndex count];
    //[qredoLocalIndex dump:@"after sync #2"];
    
    //sync again just for kicks
    
    __block  XCTestExpectation *testExpectation3 = [self expectationWithDescription:@"put item 3"];
    __block int reportedSyncCount3 =0;
    
    [qredoLocalIndex syncIndexWithCompletion:^(int syncCount, NSError *error) {
        //NSLog(@"Sync'd #4 %i items", syncCount);
         [qredoLocalIndex dump:@"after sync #4"];
        reportedSyncCount3 = syncCount;
        [testExpectation3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError * _Nullable error) {
        testExpectation3 = nil;
    }];
    
    NSInteger afterSync3 = [qredoLocalIndex count];
    XCTAssertEqual(afterSync3, itemCount1+itemCount2,"The added new items doesn't match the actual increase");
    //[qredoLocalIndex dump:@"The End"];
    
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


-(void)summaryValueTestSearch:(int)expectedMatches{
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



-(void)authoriseClient:(NSString*)password{
    
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
    
    
    NSLog(@"Valult in test %@",vault);
    
    
    XCTAssertNotNil(client1);
    XCTAssertNotNil(vault);
    XCTAssertNotNil(qredoLocalIndex);
    
    
}


-(void)authoriseSecondClient:(NSString*)password{
    
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



-(QredoVaultItem*)getItemWithDescriptor:(QredoVaultItemMetadata *)metadata inVault:(QredoVault *)vault{
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


-(QredoVaultItemMetadata *)updateItem:(QredoVaultItem *)item1 inVault:(QredoVault *)vault{
    
    
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

-(QredoVaultItemMetadata *)createTestItemInVault:(QredoVault *)vault key1Value:(NSString*)key1Value{
    
    
    
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": key1Value,
                                         @"key2": @"value2",
                                         @"key3": testNumber,
                                         @"key4": myTestDate
                                         };
    
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                 accessLevel:0
                                                                               summaryValues:item1SummaryValues];
    
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata  value:item1Data];
    
    
    
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


@end
