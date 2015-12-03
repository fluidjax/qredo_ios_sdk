//
//  QredoIndexVaultTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 02/12/2015.
//
//

#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoTestUtils.h"
#import "QredoVaultPrivate.h"
//#import "PDDebugger.h"

@interface QredoIndexVaultTests : XCTestCase

@end

@implementation QredoIndexVaultTests

QredoClient *client1;
QredoLocalIndex *qredoLocalIndex;
NSDate *myTestDate;
NSNumber *testNumber;

- (void)setUp {
    [super setUp];
    [self authoriseClient];
    
    
    NSString *dateString = @"25-Nov-68 00:00:00";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd-MMM-yy hh:mm:ss";

    myTestDate = [dateFormatter dateFromString:dateString];
    testNumber = [NSNumber numberWithInt:3];
    
    qredoLocalIndex = [QredoLocalIndex sharedQredoLocalIndex];
    
//    [[PDDebugger defaultInstance] enableNetworkTrafficDebugging];
//    [[PDDebugger defaultInstance] forwardAllNetworkTraffic];
//    [[PDDebugger defaultInstance] enableCoreDataDebugging];
//    [[PDDebugger defaultInstance] addManagedObjectContext:qredoLocalIndex.managedObjectContext withName:@"QredoLocalIndex"];
//    [[PDDebugger defaultInstance] enableViewHierarchyDebugging];
//    [[PDDebugger defaultInstance] connectToURL:[NSURL URLWithString:@"ws://localhost:9000/device"]];
//    
    self.continueAfterFailure = YES;
}

- (void)tearDown {
    [super tearDown];
}

-(void)authoriseClient{
    //Create two clients each with their own new random vaults
    
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client1"];
    
    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:[QredoTestUtils randomPassword]
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
         NSLog(@"Update item itemId %@  SequenceId %lld", newItemMetadata.descriptor.itemId, newItemMetadata.descriptor.sequenceValue);
         [testExpectation fulfill];
     }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
    return createdItemMetaData;
}

-(QredoVaultItemMetadata *)createTestItemInVault:(QredoVault *)vault{
    

    
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
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


-(void)testMultiple{
    for (int i=0;i<100;i++){
        [self testIndexPutGet];
    }
}

-(void)testIndexPutGet{
    XCTAssertNotNil(client1);
    QredoVault *vault = [client1 defaultVault];
    XCTAssertNotNil(vault);
    
    QredoVaultItemMetadata *junk1 = [self createTestItemInVault:vault];
    [qredoLocalIndex putItemWithMetadata:junk1];
    
    QredoVaultItemMetadata *meta1 = [self createTestItemInVault:vault];
    QredoVaultItem *item1 = [self getItemWithDescriptor:meta1 inVault:vault];
    [qredoLocalIndex putItemWithMetadata:meta1];
    
 //   QredoVaultItemMetadata *meta2 = [self updateItem:item1 inVault:vault];
 //   [qredoLocalIndex putItemWithMetadata:meta2];
    
    QredoVaultItemMetadata *junk2 = [self createTestItemInVault:vault];
    [qredoLocalIndex putItemWithMetadata:junk2];

    
    QredoVaultItemDescriptor *searchDescriptorWithOnlyItemId =  [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:nil itemId:meta1.descriptor.itemId];
    QredoVaultItemMetadata *retrievedFromCacheMetatadata =      [qredoLocalIndex get:searchDescriptorWithOnlyItemId];

    XCTAssertTrue([[retrievedFromCacheMetatadata.summaryValues objectForKey:@"key1"] isEqualToString:@"value1"],@"Summary data is incorrect");
    XCTAssertTrue([[retrievedFromCacheMetatadata.summaryValues objectForKey:@"key2"] isEqualToString:@"value2"],@"Summary data is incorrect");
    XCTAssertTrue([[retrievedFromCacheMetatadata.summaryValues objectForKey:@"key3"] isEqual:testNumber],@"Summary data is correct");
    XCTAssertTrue([[retrievedFromCacheMetatadata.summaryValues objectForKey:@"key4"] isEqualToDate:myTestDate]);
    
}







@end
