//
//  QredoIndexPerformanceTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 09/12/2015.
//
//

#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoLocalIndex.h"
#import "QredoTestUtils.h"
#import "QredoVaultPrivate.h"
#import "QredoLocalIndex.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoIndexVault.h"
#import "Qredo.h"

@interface QredoIndexPerformanceTests :QredoXCTestCase

@end

@implementation QredoIndexPerformanceTests

QredoClient *client1;
QredoLocalIndex *qredoLocalIndex;
NSDate *myTestDate;
NSNumber *testNumber;




-(void)testMultiple{
    for (int i=0;i<10;i++){
        NSLog(@"Pass %i",i);
        [self setUp];
        [self test10Records];
    }
}

-(void)test10Records{
    int testSize = 10;
    
    NSString *clientPass = [QredoTestUtils randomStringWithLength:32];
    [self authoriseClient:clientPass];
    qredoLocalIndex = client1.defaultVault.localIndex;
    [qredoLocalIndex purgeAll];
    
     XCTAssertTrue(0 == [self countRecords:@"QredoIndexVaultItem"],@"There are %ld records in the index there should be 0",[self countRecords:@"QredoIndexVaultItem"]);
    XCTAssertNotNil(client1);
    [self addTestItems:testSize];
    XCTAssertTrue(testSize == [self countRecords:@"QredoIndexVaultItem"],@"There are %ld records in the index there shoudl be %i",[self countRecords:@"QredoIndexVaultItem"],testSize);

    [qredoLocalIndex removeIndexObserver];
    [qredoLocalIndex purgeAll];
    
    //At this point have added 10 records to the server, but purged them locally
    int countBefore = [qredoLocalIndex count];
    
    XCTAssertNotNil(client1);
    XCTAssertTrue(0 == [self countRecords:@"QredoIndexVaultItem"],@"Failed to purge items");
    
    __block XCTestExpectation *syncwait = [self expectationWithDescription:@"Sync"];
    __block int importCount =0;

    
    [qredoLocalIndex enableSyncWithBlock:^(QredoVaultItemMetadata *vaultMetaData) {
        importCount++;
        NSLog(@"Incoming %@, %@",[vaultMetaData.summaryValues objectForKey:@"key1"], client1.defaultVault.vaultId);
        QLog(@"importing %i",importCount);
        if (importCount==testSize) [syncwait fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:100 handler:^(NSError * _Nullable error) {
        syncwait=nil;
    }];
    
    int countAfter = [qredoLocalIndex count];

    
    //at this point we should have received 10 records from the server
    
    XCTAssertTrue(testSize == importCount,@"Failing to import %i items - imported %i", testSize, importCount);
    XCTAssertTrue(testSize == countAfter-countBefore,@"Failing to import %i items", testSize);
    
    XCTAssertTrue(testSize == [self countRecords:@"QredoIndexVaultItem"],@"Failed to import the correct number of records");
    
    
    QLog(@"Stats %i %i %i %i",testSize,countBefore, countAfter, importCount);

}

-(void)test100Records{
    int testSize = 100;
    NSString *clientPass = [QredoTestUtils randomStringWithLength:32];
    [self authoriseClient:clientPass];
    XCTAssertNotNil(client1);
    [self addTestItems:testSize];
    
    //At this point have added 100 records to the server, but purged them locally
    
    
    qredoLocalIndex = client1.defaultVault.localIndex;
    [qredoLocalIndex removeIndexObserver];
    [qredoLocalIndex purgeAll];
    int countBefore = [qredoLocalIndex count];
    
    XCTAssertNotNil(client1);
    
    __block XCTestExpectation *syncwait = [self expectationWithDescription:@"Sync"];
    __block int importCount =0;
    
    
    [qredoLocalIndex enableSyncWithBlock:^(QredoVaultItemMetadata *vaultMetaData) {
        importCount++;
        NSLog(@"Incoming %@, %@",[vaultMetaData.summaryValues objectForKey:@"key1"], client1.defaultVault.vaultId);
        QLog(@"importing %i",importCount);
        if (importCount==testSize) [syncwait fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:100 handler:^(NSError * _Nullable error) {
        syncwait=nil;
    }];
    
    int countAfter = [qredoLocalIndex count];
    
    
    //at this point we should have received 100 records from the server
    
    XCTAssertTrue(testSize <= importCount,@"Failing to import %i items", testSize);
    XCTAssertTrue(testSize == countAfter-countBefore,@"Failing to import %i items", testSize);
    
    
    NSLog(@"Stats %i %i %i %i",testSize,countBefore, countAfter, importCount);
    
}




#pragma mark
#pragma Private methods


- (void)setUp {
    [super setUp];
    [[QredoLocalIndexDataStore sharedQredoLocalIndexDataStore] deleteStore];
    
    myTestDate = [NSDate date];
    QLog(@"**************%@",myTestDate);
    testNumber = [NSNumber numberWithInt:3];
    self.continueAfterFailure = YES;
}


- (void)tearDown {
    [super tearDown];
}


- (void)authoriseClient:(NSString*)password {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client1"];
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.resetData = YES;
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:[QredoTestUtils randomPassword]
                   completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           client1 = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        clientExpectation = nil;
    }];
}


- (void)summaryValueTestSearch:(int)expectedMatches {
    //this search term returns each 100th item
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"key=%@ && value.string == %@", @"key1", @"88"];
    __block int count =0;
    [qredoLocalIndex enumerateSearch:searchTest withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        count++;
    } completionHandler:^(NSError *error) {
        XCTAssert(expectedMatches==count,@"Did not match the correct number of expected matches");
        QLog(@"Search Matched %i items",count);
    }];
}


- (void)addTestItems:(int)recordCount {
    QredoVault *vault = [client1 defaultVault];
    qredoLocalIndex = client1.defaultVault.localIndex;
   // [vault addMetadataIndexObserver];
    NSInteger countBefore = [qredoLocalIndex count];
    XCTAssertNotNil(vault);
    for (int i=0; i<recordCount; i++) {
        QLog(@"Adding Record %i",i);

        NSString *testSearchValue = [NSString stringWithFormat:@"%i", i];
        QredoVaultItemMetadata *item = [self createTestItemInVault:vault key1Value:testSearchValue];
    }
    NSInteger countAfter = [qredoLocalIndex count];
    XCTAssert(countAfter == countBefore+recordCount,@"Failed to add items");
   // [vault removeMetadataIndexObserver];
}


- (QredoVaultItemMetadata *)createTestItemInVault:(QredoVault *)vault key1Value:(NSString*)key1Value {
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": key1Value,
                                         @"key2": @"value2",
                                         @"key3": testNumber,
                                         @"key4": myTestDate};
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues];
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:metadata value:item1Data];
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"creatTestItem"];
    __block QredoVaultItemMetadata *createdItemMetaData = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
        XCTAssertNil(error);
        
        NSLog(@"Added  %@ %@",key1Value,vault.vaultId);
        
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
    long count = [results count];
    return count;
}

@end
