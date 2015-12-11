//
//  QredoIndexPerformanceTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 09/12/2015.
//
//

#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoLocalIndexPrivate.h"
#import "QredoTestUtils.h"
#import "QredoVaultPrivate.h"

@interface QredoIndexPerformanceTests : XCTestCase

@end

@implementation QredoIndexPerformanceTests

QredoClient *client1;
QredoLocalIndex *qredoLocalIndex;
NSDate *myTestDate;
NSNumber *testNumber;




//Performance Tests
-(void)testAddDummryRecords{
    //adding 1K records on Mac takes 160secs
    //do not run this on the current vaules that have 100,1000,10000 records - as they are already initialized
    //    NSString *clientPass = @"100";  //has 100 item ID's
    //    NSString *clientPass = @"1000"; //has 1000 item ID's
    //    NSString *clientPass = @"10000";//has 10000 item ID's
        NSString *clientPass = @"2";//has 10000 item ID's
    
        [self authoriseClient:clientPass];
        XCTAssertNotNil(client1);
        [qredoLocalIndex purge];
        [self addTestItems:2];
}




/**

 Mac OSX
    100 Records Complete Sync of Metadata from server into empty local index - 1.5 seconds
    100 Records Search meta data for a unique record = 0.001
    1000 Records Complete Sync of Metadata from server into empty local index - 13 seconds
    1000 Records Search meta data for a unique record = 0.002
    10000 Records Complete Sync of Metadata from server into empty local index - 240 seconds
    10000 Records Search meta data for a unique record = 0.02
 */


-(void)testDebug{
    int testSize = 100;
    NSString *clientPass = [NSString stringWithFormat:@"%i",testSize];
    [self authoriseClient:clientPass];
    qredoLocalIndex = [[QredoLocalIndex alloc] initWithVault:client1.defaultVault];
    
    [qredoLocalIndex purgeAllVaults];
    XCTAssertNotNil(client1);
    int waitTime = (6*testSize)/100;
    if (waitTime<10)waitTime=100;
    
    __block  XCTestExpectation *syncwait = [self expectationWithDescription:@"Sync"];
    
  //  NSLog(@"API HIGHWATER BEFORE %@",client1.defaultVault.highWatermark);
    [qredoLocalIndex purgeAllVaults];
    NSInteger countBefore = [qredoLocalIndex count];
    
    
    [qredoLocalIndex syncIndexWithCompletion:^(int syncCount, NSError *error) {
        [syncwait fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:100000 handler:^(NSError * _Nullable error) {
        syncwait=nil;
    }];

    
    NSInteger countAfter = [qredoLocalIndex count];
 //   NSLog(@"API HIGHWATER AFTER %@",client1.defaultVault.highWatermark);
    NSLog(@"Count of Metadata items in coredata =  %ld",(long)countAfter-countBefore);
    

}



-(void)testPerfomance100{
    int testSize = 100;
    NSString *clientPass = [NSString stringWithFormat:@"%i",testSize];
    [self authoriseClient:clientPass];
    qredoLocalIndex = [[QredoLocalIndex alloc] initWithVault:client1.defaultVault];
    [qredoLocalIndex purgeAllVaults];
    XCTAssertNotNil(client1);
    int waitTime = (6*testSize)/100;
    __block  XCTestExpectation *syncwait = [self expectationWithDescription:@"Sync"];
    
    
    NSLog(@"Sync Start");
    [qredoLocalIndex syncIndexWithCompletion:^(int syncCount, NSError *error) {
        NSLog(@"Sync Complete - imported %i",syncCount);
         [syncwait fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:waitTime handler:^(NSError * _Nullable error) {
        syncwait=nil;
    }];
    
    [self measureBlock:^{
        [self summaryValueTestSearch:1];
    }];
}


-(void)testPerfomance1000{
    int testSize = 1000;
    NSString *clientPass = [NSString stringWithFormat:@"%i",testSize];
    [self authoriseClient:clientPass];
    qredoLocalIndex = [[QredoLocalIndex alloc] initWithVault:client1.defaultVault];
    [qredoLocalIndex purgeAllVaults];
    XCTAssertNotNil(client1);
    int waitTime = (6*testSize)/100;
    __block  XCTestExpectation *syncwait = [self expectationWithDescription:@"Sync"];
    
    NSLog(@"Sync Start");
    [qredoLocalIndex syncIndexWithCompletion:^(int syncCount, NSError *error) {
        NSLog(@"Sync Complete - imported %i",syncCount);
        [syncwait fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:waitTime handler:^(NSError * _Nullable error) {
        syncwait=nil;
    }];
    
    [self measureBlock:^{
        [self summaryValueTestSearch:1];
    }];
}

-(void)testPerfomance10000{
    int testSize = 10000;
    NSString *clientPass = [NSString stringWithFormat:@"%i",testSize];
    [self authoriseClient:clientPass];
    qredoLocalIndex = [[QredoLocalIndex alloc] initWithVault:client1.defaultVault];
    [qredoLocalIndex purgeAllVaults];
    XCTAssertNotNil(client1);
    int waitTime = (6*testSize)/100;
    __block  XCTestExpectation *syncwait = [self expectationWithDescription:@"Sync"];
    
     NSLog(@"Sync Start");
    [qredoLocalIndex syncIndexWithCompletion:^(int syncCount, NSError *error) {
        NSLog(@"Sync Complete - imported %i",syncCount);
        [syncwait fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:waitTime handler:^(NSError * _Nullable error) {
        syncwait=nil;
    }];
    
    [self measureBlock:^{
        [self summaryValueTestSearch:1];
    }];
}

-(void)testPerfomance10000noLoad{
    int testSize = 10000;
    NSString *clientPass = [NSString stringWithFormat:@"%i",testSize];
    [self authoriseClient:clientPass];
    qredoLocalIndex = [[QredoLocalIndex alloc] initWithVault:client1.defaultVault];
    XCTAssertNotNil(client1);
    
    
    [self measureBlock:^{
        [self summaryValueTestSearch:1];
    }];
}



#pragma mark
#pragma Private methods


- (void)setUp {
    [super setUp];
    myTestDate = [NSDate date];
    NSLog(@"**************%@",myTestDate);
    testNumber = [NSNumber numberWithInt:3];
    self.continueAfterFailure = YES;
}


- (void)tearDown {
    [super tearDown];
}


-(void)authoriseClient:(NSString*)password{
    
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client1"];
    
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.resetData = YES;
    
    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:password
                                 options:clientOptions
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

- (NSData*)randomDataWithLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: length];
    for (unsigned int i = 0; i < length; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    } return mutableData;
}



-(void)summaryValueTestSearch:(int)expectedMatches{
    //this search term returns each 100th item
    NSPredicate *searchTest = [NSPredicate predicateWithFormat:@"key=%@ && value.string == %@", @"key1", @"88"];
    
    __block int count =0;
    [qredoLocalIndex enumerateSearch:searchTest withBlock:^(QredoVaultItemMetadata *vaultMetaData, BOOL *stop) {
        count++;
    } completionHandler:^(NSError *error) {
        XCTAssert(expectedMatches==count,@"Did not match the correct number of expected matches");
        NSLog(@"Search Matched %i items",count);
    }];
    
}



-(void)addTestItems:(int)recordCount{
    NSInteger countBefore = [qredoLocalIndex count];
    QredoVault *vault = [client1 defaultVault];
    XCTAssertNotNil(vault);
    
    for (int i=0;i<recordCount;i++){
        NSLog(@"Adding Record %i",i);
        NSString *testSearchValue = [NSString stringWithFormat:@"%i", i];
        QredoVaultItemMetadata *item = [self createTestItemInVault:vault key1Value:testSearchValue];
        [qredoLocalIndex putItemWithMetadata:item];
    }
    
    NSInteger countAfter = [qredoLocalIndex count];
    XCTAssert(countAfter == countBefore+recordCount ,@"Failed to add items");
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
    
    
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"creatTestItem"];
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
