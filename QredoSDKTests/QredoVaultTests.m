/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <XCTest/XCTest.h>
#import "QredoVaultTests.h"
#import "Qredo.h"
#import "QredoTestUtils.h"
#import "NSDictionary+Contains.h"
#import "QredoVaultPrivate.h"
#import "QredoNetworkTime.h"

@interface QredoVaultListener : NSObject<QredoVaultObserver>

@property XCTestExpectation *didReceiveVaultItemMetadataExpectation;
@property XCTestExpectation *didFailWithErrorExpectation;
@property NSMutableArray *receivedItems;
@property NSError *error;


@end

@implementation QredoVaultListener

- (void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error
{
    self.error = error;
    
    if (self.didFailWithErrorExpectation) {
        [self.didFailWithErrorExpectation fulfill];
    }
}

- (void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata
{
    if (!self.receivedItems) {
        self.receivedItems = [NSMutableArray array];
    }

    [self.receivedItems addObject:itemMetadata];

    if (self.didReceiveVaultItemMetadataExpectation) {
        [self.didReceiveVaultItemMetadataExpectation fulfill];
    }
}

@end



@interface QredoVaultListenerWithEmptyImplementation : NSObject<QredoVaultObserver>
{
    BOOL _deallocEntered;
}
@property (nonatomic) QredoVault *vault;
@end

@implementation QredoVaultListenerWithEmptyImplementation

- (instancetype)initWithVault:(QredoVault *)vault
{
    self = [super init];
    if (self) {
        self.vault = vault;
        [self.vault addVaultObserver:self];
    }
    return self;
}

- (void)dealloc
{
    _deallocEntered = YES;
    [self.vault removeVaultObserver:self];
}

- (void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error
{
}

- (void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata
{
    if (_deallocEntered) {
        NSAssert(FALSE, @"QredoVaultListenerWithEmptyImplementation notified after dealloc has been called.");
    }
}

@end

@interface QredoVault()
- (void)notifyObservers:(void(^)(id<QredoVaultObserver> observer))notificationBlock;
@end


@interface QredoVaultTests ()
{
    QredoClient *client;
    NSString *savedPassword;
}

@end


@implementation QredoVaultTests

- (void)setUp {
    [super setUp];
    [self authoriseClient];
}

-(void)tearDown {
    [super tearDown];
    if (client) {
        [client closeSession];
    }
}

- (void)authoriseClient{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.transportType = self.transportType;
  
    savedPassword = [self randomPassword];
    
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:savedPassword
                             options:clientOptions
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  XCTAssertNil(error);
                                  XCTAssertNotNil(clientArg);
                                  client = clientArg;
                                  [clientExpectation fulfill];
                              }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
}


- (void)testPersistanceVaultId {
    QredoQUID *firstQUID = nil;

    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);

    firstQUID = vault.vaultId;
    XCTAssertNotNil(firstQUID);

    vault = nil;
    client = nil;

    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.transportType = self.transportType;
    
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:savedPassword
                             options:clientOptions
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  XCTAssertNil(error);
                                  XCTAssertNotNil(clientArg);
                                  client = clientArg;
                                  [clientExpectation fulfill];
                              }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];

    XCTAssertEqualObjects([[client defaultVault] vaultId], firstQUID);
}


-(void)testEnumerateContainsDeletedItems{
    [self resetKeychain];
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    // Create an item and store in vault
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                           value:item1Data];
    
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    __block QredoVaultItemMetadata *item1Metadata = nil;
    
    QredoVaultListener *listener = [[QredoVaultListener alloc] init];
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener];
    
    
    
    
    
    
    [vault putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
        XCTAssertNil(error, @"Error occurred during PutItem");
        item1Descriptor = newItemMetadata.descriptor;
        item1Metadata = newItemMetadata;
    }];
    
    ///wait for listener
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
    //[vault removeVaultObserver:listener];
    
    
    
    //enumerate the items in the vault
    
    __block int count=0;
    __block NSMutableArray *enumArray = [[NSMutableArray alloc] init];
    __block XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;
    } completionHandler:^(NSError *error) {
        [completionHandlerCalled fulfill];
        completionHandlerCalled = nil;
        //complete
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        completionHandlerCalled = nil;
    }];
    
    XCTAssertTrue(count==1,@"there should be 1 item in the vault");

    
    
    
   // delete item
    __block QredoVaultItemDescriptor *deleteItemDescriptor = nil;
    QredoVaultListener *listener2 = [[QredoVaultListener alloc] init];
    listener2.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener2];
    
    [vault deleteItem:item1Metadata completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
        deleteItemDescriptor=newItemDescriptor;
    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener2.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
  
    
    //enumerate the items in the vault
    
    __block int itemDeleted =0;
    __block int itemNotDeleted =0;
    
    
    
    __block int count2 =0;
    __block XCTestExpectation *completionHandlerCalled2 = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count2++;
        if ([vaultItemMetadata isDeleted]==YES)itemDeleted++;
        if ([vaultItemMetadata isDeleted]==NO )itemNotDeleted++;
    } completionHandler:^(NSError *error) {
         [completionHandlerCalled2 fulfill];
         completionHandlerCalled2 = nil;
        //complete
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        completionHandlerCalled2 = nil;
    }];
    
     XCTAssertTrue(itemDeleted==1,@"there should be 1 deleted Item");
     XCTAssertTrue(itemNotDeleted==1,@"there should be 1 not deleted Item");
     XCTAssertTrue(count2==2,@"there should be 2 items in the vault ");
  
    [client closeSession];
    

    
    
}



-(void)testEnumerateUpdated{
    [self resetKeychain];
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    // Create an item and store in vault
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                           value:item1Data];
    
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    __block QredoVaultItemMetadata *item1Metadata = nil;
    
    QredoVaultListener *listener = [[QredoVaultListener alloc] init];
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener];
    
    
    
    
    
    
    [vault putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
        XCTAssertNil(error, @"Error occurred during PutItem");
        item1Descriptor = newItemMetadata.descriptor;
        item1Metadata = newItemMetadata;
        
        //NSLog(@"PUT%@",item1Metadata.descriptor);
    }];
    
    ///wait for listener
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
    //[vault removeVaultObserver:listener];
    
    
    
    //enumerate the items in the vault
    
    __block int count=0;
    __block NSMutableArray *enumArray = [[NSMutableArray alloc] init];
    __block XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;
         //NSLog(@"GET 1%@",vaultItemMetadata.descriptor);
    } completionHandler:^(NSError *error) {
        [completionHandlerCalled fulfill];
        completionHandlerCalled = nil;
        //complete
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        completionHandlerCalled = nil;
    }];
    
    XCTAssertTrue(count==1,@"there should be 1 item in the vault");
    
    
    
    
    // update the item
    __block QredoVaultItemMetadata *updateItemMetadata = nil;
    QredoVaultListener *listener2 = [[QredoVaultListener alloc] init];
    listener2.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener2];
    
    
    
    [vault updateItem:item1Metadata value:nil completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
        updateItemMetadata = newItemMetadata;
        //NSLog(@"UPDATE%@",newItemMetadata.descriptor);
    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener2.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
    
    
    //enumerate the items in the vault
    
    __block int count2 =0;
    __block XCTestExpectation *completionHandlerCalled2 = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count2++;
        //NSLog(@"GET2 %@",vaultItemMetadata.descriptor);
    } completionHandler:^(NSError *error) {
        [completionHandlerCalled2 fulfill];
        completionHandlerCalled2 = nil;
        //complete
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        completionHandlerCalled2 = nil;
    }];
    
    
    XCTAssertTrue(count2==2,@"there should be 2 items in the vault ");
    
    
    
    //now delete the item
    // delete item
    __block QredoVaultItemDescriptor *deleteItemDescriptor = nil;
    QredoVaultListener *listener3 = [[QredoVaultListener alloc] init];
    listener3.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener3];
    
    [vault deleteItem:item1Metadata completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
        //NSLog(@"DELETE %@",newItemDescriptor);
        deleteItemDescriptor=newItemDescriptor;
    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener2.didReceiveVaultItemMetadataExpectation = nil;
    }];

    
    
    //enumerate the items in the vault after the delete
    
    __block int count3 =0;
    __block XCTestExpectation *completionHandlerCalled3 = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count3++;
        //NSLog(@"ENUM after delete %@",vaultItemMetadata.descriptor);
    } completionHandler:^(NSError *error) {
        [completionHandlerCalled3 fulfill];
        completionHandlerCalled3 = nil;
        //complete
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        completionHandlerCalled3 = nil;
    }];
    
    
    XCTAssertTrue(count3==3,@"there should be 3 items in the vault there are %i", count3);
    
    
    [client closeSession];
    
    
    
    
    
    
}





-(void)testPutDelete{
    [self resetKeychain];
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    // Create an item and store in vault
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    
    __block QredoVaultItemMetadata *itemMetadata = nil;
    
    __block XCTestExpectation *putItemCompletedExpectation = [self expectationWithDescription:@"PutItem completion handler called"];
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error, @"Error occurred during PutItem");
         item1Descriptor = newItemMetadata.descriptor;
         itemMetadata = newItemMetadata;
         [putItemCompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        putItemCompletedExpectation = nil;
    }];
    XCTAssertNotNil(item1Descriptor, @"Descriptor returned is nil");
    
    // Confirm the item is found in the vault
    __block XCTestExpectation *getItemCompletedExpectation = [self expectationWithDescription:@"GetItem completion handler called"];
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"], item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"], item1SummaryValues[@"key2"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key3"], item1SummaryValues[@"key3"]);
         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         
         [getItemCompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        getItemCompletedExpectation = nil;
    }];
    
    // Confirm enumerate finds item we added
    __block int count = 0;
    __block BOOL itemFound = NO;
    __block XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;
        
        XCTAssertNotNil(vaultItemMetadata);
        
        if ([vaultItemMetadata.summaryValues[@"key1"] isEqual:item1SummaryValues[@"key1"]] &&
            [vaultItemMetadata.summaryValues[@"key2"] isEqual:item1SummaryValues[@"key2"]] &&
            [vaultItemMetadata.summaryValues[@"key3"] isEqual:item1SummaryValues[@"key3"]])
        {
            itemFound = YES;
        }
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [completionHandlerCalled fulfill];
    }];
    
    // Note: May need a longer timeout if there's lots of items to enumerate. May depend on how many items added since test last run.
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        completionHandlerCalled = nil;
    }];
    
    XCTAssertTrue(itemFound, "Item just created was not found during enumeration.(%i items)",count);
    
    // Note: DH - Apparently server returns 50 items, so once 50 items created this test will fail.  Looks like it returns first 50 items, rather than latest 50 items.
    if (!itemFound && count == 50)    {
        XCTFail(@"Created item was not found and 50 items were enumerated. Likely failure was due to server only returning oldest 50 items."); // this has been fixed and the client enumerates all items not just pages of 50
    }


    
    //delete the item
    //delete item
    
    __block QredoVaultItemDescriptor *deletedItem=nil;
    __block XCTestExpectation *deleteExpectation = [self expectationWithDescription:@"delete item 1"];
    [vault deleteItem:itemMetadata completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(newItemDescriptor);
        deletedItem = newItemDescriptor;
        [deleteExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        deleteExpectation = nil;
    }];
    
    
    
        // Confirm enumerate finds item we added
    __block int count2 = 0;
    __block BOOL itemFound2 = NO;
    __block XCTestExpectation *completionHandlerCalled2 = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count2++;
        
        XCTAssertNotNil(vaultItemMetadata);
        
        if ([vaultItemMetadata.summaryValues[@"key1"] isEqual:item1SummaryValues[@"key1"]] &&
            [vaultItemMetadata.summaryValues[@"key2"] isEqual:item1SummaryValues[@"key2"]] &&
            [vaultItemMetadata.summaryValues[@"key3"] isEqual:item1SummaryValues[@"key3"]])
        {
            itemFound2 = YES;
        }
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [completionHandlerCalled2 fulfill];
    }];
    
    // Note: May need a longer timeout if there's lots of items to enumerate. May depend on how many items added since test last run.
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        completionHandlerCalled2 = nil;
    }];
    
    XCTAssertTrue(itemFound2, "Item just deleted but should still be present in an enumeration from the server");
}



-(void)testGetLatestMetaDataItemFromIndex{
    [self resetKeychain];
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    // Create an item and store in vault
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                           value:item1Data];
    
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    __block QredoVaultItemMetadata *item1Metadata = nil;
    
    QredoVaultListener *listener = [[QredoVaultListener alloc] init];
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener];
    
    [vault putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
         XCTAssertNil(error, @"Error occurred during PutItem");
         item1Descriptor = newItemMetadata.descriptor;
         item1Metadata = newItemMetadata;
     }];
    
    ///wait for listener
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener.didReceiveVaultItemMetadataExpectation = nil;
    }];
   // [vault removeVaultObserver:listener];
    
    
    
    
    //create a second item and store in the vault
    
    
    __block QredoVaultItemDescriptor *item2Descriptor = nil;
    __block QredoVaultItemMetadata *item2Metadata = nil;
    QredoVaultListener *listener2 = [[QredoVaultListener alloc] init];
    listener2.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener2];
    

    [vault putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error, @"Error occurred during PutItem");
         item2Descriptor = newItemMetadata.descriptor;
         item2Metadata = newItemMetadata;
     }];
   
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener2.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
    //[vault removeVaultObserver:listener2];
    
    
    
    //we now have 2 items in the vault (server & index)
    //this is getting the first item
    __block QredoVaultItemMetadata *test1vaultItemMetadata=nil;
    __block XCTestExpectation *x1 = [self expectationWithDescription:@"get oldest item"];
    
    [vault getItemMetadataWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
        test1vaultItemMetadata = vaultItemMetadata;
        [x1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        x1 = nil;
    }];
    XCTAssertTrue([item1Metadata.descriptor isEqual:test1vaultItemMetadata.descriptor], @"Retrieved item should be first");
    
    
    
    //this is getting the second item
    __block QredoVaultItemMetadata *test2vaultItemMetadata=nil;
    __block XCTestExpectation *x2 = [self expectationWithDescription:@"get latest item1"];
    
    [vault getItemMetadataWithDescriptor:item2Descriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {        test2vaultItemMetadata = vaultItemMetadata;
        [x2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        x2 = nil;
    }];
    XCTAssertTrue([item2Metadata.descriptor isEqual:test2vaultItemMetadata.descriptor], @"Retrieved item should be second");
    
    
    
    //get the latest with first descriptor
    __block QredoVaultItemMetadata *test3vaultItemMetadata=nil;
    __block XCTestExpectation *x3 = [self expectationWithDescription:@"get latest item2"];
    
    [vault getLatestItemMetadataWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
        test3vaultItemMetadata = vaultItemMetadata;
        [x3 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        x3 = nil;
    }];
    
    XCTAssertTrue([item2Metadata.descriptor isEqual:test3vaultItemMetadata.descriptor], @"Retrieved item should be second");
    
    
    //get the latest with second descriptor
    __block QredoVaultItemMetadata *test4vaultItemMetadata=nil;
    __block XCTestExpectation *x4 = [self expectationWithDescription:@"get latest item3"];
    
    [vault getLatestItemMetadataWithDescriptor:item2Descriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
        test4vaultItemMetadata = vaultItemMetadata;
        [x4 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        x4 = nil;
    }];
    
    XCTAssertTrue([item2Metadata.descriptor isEqual:test4vaultItemMetadata.descriptor], @"Retrieved item should be second");
    [client closeSession];
}


-(void)testGetLatestMetaDataItemFromIndexAfterDelete{
    [self resetKeychain];
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    // Create an item and store in vault
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                           value:item1Data];
    
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    __block QredoVaultItemMetadata *item1Metadata = nil;
    
    QredoVaultListener *listener = [[QredoVaultListener alloc] init];
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener];
    
    
    [vault putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
         XCTAssertNil(error, @"Error occurred during PutItem");
         item1Descriptor = newItemMetadata.descriptor;
         item1Metadata = newItemMetadata;
     }];
    
    ///wait for listener
    
   
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
    //[vault removeVaultObserver:listener];
    
    
    
    
    //delete item
    __block QredoVaultItemDescriptor *deleteItemDescriptor = nil;
    QredoVaultListener *listener2 = [[QredoVaultListener alloc] init];
    listener2.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener2];
    
    [vault deleteItem:item1Metadata completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
        deleteItemDescriptor=newItemDescriptor;
    }];

    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener2.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
    //[vault removeVaultObserver:listener2];
    
    
    
    //we now have 2 items in the vault (server & index)
    //this is getting the first item
    __block QredoVaultItemMetadata *test1vaultItemMetadata=nil;
    __block XCTestExpectation *x1 = [self expectationWithDescription:@"get oldest item"];
    
    [vault getItemMetadataWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
        test1vaultItemMetadata = vaultItemMetadata;
        [x1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        x1 = nil;
    }];
    XCTAssertTrue([item1Metadata.descriptor isEqual:test1vaultItemMetadata.descriptor], @"Retrieved item should be first");
    
    
    
    //this is getting the second item
    __block QredoVaultItemMetadata *test2vaultItemMetadata=nil;
    __block XCTestExpectation *x2 = [self expectationWithDescription:@"get latest item1"];
    
    [vault getItemMetadataWithDescriptor:deleteItemDescriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
        test2vaultItemMetadata = vaultItemMetadata;
        [x2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        x2 = nil;
    }];
   
    XCTAssertNil(test2vaultItemMetadata,@"metadata of deleted item should retirve as nil");
    
    
    
    //get the latest with first descriptor
    __block QredoVaultItemMetadata *test3vaultItemMetadata=nil;
    __block XCTestExpectation *x3 = [self expectationWithDescription:@"get latest item2"];
    
    [vault getLatestItemMetadataWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
        test3vaultItemMetadata = vaultItemMetadata;
        [x3 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        x3 = nil;
    }];
    
    XCTAssertNil(test3vaultItemMetadata,@"Should be nil");
    
    
    //get the latest with second descriptor
    __block QredoVaultItemMetadata *test4vaultItemMetadata=nil;
    __block XCTestExpectation *x4 = [self expectationWithDescription:@"get latest item3"];
    
    [vault getLatestItemMetadataWithDescriptor:deleteItemDescriptor completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error) {
        test4vaultItemMetadata = vaultItemMetadata;
        [x4 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        x4 = nil;
    }];
    
     XCTAssertNil(test4vaultItemMetadata,@"Should be nil");
    [client closeSession];
    
}



-(void)testGetLatestItemFromIndexAfterDelete{
    [self resetKeychain];
    XCTAssertNotNil(client);
    [self authoriseClient];
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    // Create an item and store in vault
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                           value:item1Data];
    
    
    QredoVaultListener *listener = [[QredoVaultListener alloc] init];
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener];
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    __block QredoVaultItemMetadata *item1Metadata = nil;
    [vault putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)     {
         XCTAssertNil(error, @"Error occurred during PutItem");
         item1Descriptor = newItemMetadata.descriptor;
         item1Metadata = newItemMetadata;
     }];
    ///wait for listener
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
   
    
    
    
    
    //delete item
    
    QredoVaultListener *listener2 = [[QredoVaultListener alloc] init];
    listener2.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener2];
    __block QredoVaultItemDescriptor *deleteItemDescriptor = nil;
    [vault deleteItem:item1Metadata completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor, NSError *error) {
        deleteItemDescriptor=newItemDescriptor;
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener2.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
    
    
    
    
    //we now have 2 items in the vault (server & index)
    //this is getting the first item
    __block QredoVaultItem *test1vaultItem=nil;
    __block XCTestExpectation *x1 = [self expectationWithDescription:@"get oldest item"];
    
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        test1vaultItem = vaultItem;
        [x1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        x1 = nil;
    }];
    XCTAssertTrue([item1Metadata.descriptor isEqual:test1vaultItem.metadata.descriptor], @"Retrieved item should be first");
    
    
    
    //this is getting the second item
    __block QredoVaultItem *test2vaultItem=nil;
    __block XCTestExpectation *x2 = [self expectationWithDescription:@"get latest item1"];
    
    [vault getItemWithDescriptor:deleteItemDescriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        test2vaultItem = vaultItem;
        [x2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        x2 = nil;
    }];

    XCTAssertNil(test2vaultItem,@"Deleted item get should return nil");
    
    
    
    
    //get the latest with first descriptor
    __block QredoVaultItem *test3vaultItem=nil;
    __block XCTestExpectation *x3 = [self expectationWithDescription:@"get latest item2"];
    
    [vault getLatestItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        test3vaultItem = vaultItem;
        if (test3vaultItem){
            NSLog(@"we shouldnt be here!!");
        }
        [x3 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        x3 = nil;
    }];
    
    
    XCTAssertNil(test3vaultItem,@"Should be nil");
    
    
    //get the latest with second descriptor
    __block QredoVaultItem *test4vaultItem=nil;
    __block XCTestExpectation *x4 = [self expectationWithDescription:@"get latest item3"];
    
    [vault getLatestItemWithDescriptor:deleteItemDescriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        test4vaultItem = vaultItem;
        [x4 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        x4 = nil;
    }];
    
    XCTAssertNil(test4vaultItem,@"Should be nil");

    [client closeSession];
}



-(void)testGetLatestVaultItemFromIndex{
    [self resetKeychain];
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    // Create an item and store in vault
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    __block QredoVaultItemMetadata *item1Metadata = nil;
    __block XCTestExpectation *putItem1CompletedExpectation = [self expectationWithDescription:@"PutItem completion handler called"];
    [vault putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error, @"Error occurred during PutItem");
         item1Descriptor = newItemMetadata.descriptor;
         item1Metadata = newItemMetadata;
         [putItem1CompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        putItem1CompletedExpectation = nil;
    }];
    XCTAssertNotNil(item1Descriptor, @"Descriptor returned is nil");
    
    
    ///wait for listener
    
    QredoVaultListener *listener = [[QredoVaultListener alloc] init];
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
//    [vault removeVaultObserver:listener];
    
    
    

    //create a second item and store in the vault
    
    
    __block QredoVaultItemDescriptor *item2Descriptor = nil;
    __block QredoVaultItemMetadata *item2Metadata = nil;
    
    __block XCTestExpectation *putItem2CompletedExpectation = [self expectationWithDescription:@"PutItem completion handler called"];
    [vault putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error, @"Error occurred during PutItem");
         item2Descriptor = newItemMetadata.descriptor;
         item2Metadata = newItemMetadata;
         [putItem2CompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        putItem2CompletedExpectation = nil;
    }];
    XCTAssertNotNil(item2Descriptor, @"Descriptor returned is nil");
    
    
    
    
    QredoVaultListener *listener2 = [[QredoVaultListener alloc] init];
    listener2.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener2];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener2.didReceiveVaultItemMetadataExpectation = nil;
    }];
    
    [vault removeVaultObserver:listener2];


    
     //we now have 2 items in the vault (server & index)
    //this is getting the first item
    __block QredoVaultItem *test1vaultItem=nil;
    __block XCTestExpectation *x1 = [self expectationWithDescription:@"get oldest item"];

    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        test1vaultItem = vaultItem;
        [x1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        x1 = nil;
    }];
    XCTAssertTrue([item1Metadata.descriptor isEqual:test1vaultItem.metadata.descriptor], @"Retrieved item should be first");
    
    
    
    //this is getting the second item
    __block QredoVaultItem *test2vaultItem=nil;
    __block XCTestExpectation *x2 = [self expectationWithDescription:@"get latest item1"];
    
    [vault getItemWithDescriptor:item2Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        test2vaultItem = vaultItem;
        [x2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        x2 = nil;
    }];
    XCTAssertTrue([item2Metadata.descriptor isEqual:test2vaultItem.metadata.descriptor], @"Retrieved item should be second");
    
    
    
    //get the latest with first descriptor
    __block QredoVaultItem *test3vaultItem=nil;
    __block XCTestExpectation *x3 = [self expectationWithDescription:@"get latest item2"];
    
    [vault getLatestItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        test3vaultItem = vaultItem;
        [x3 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        x3 = nil;
    }];
    
    XCTAssertTrue([item2Metadata.descriptor isEqual:test3vaultItem.metadata.descriptor], @"Retrieved item should be second");
    
    
    //get the latest with second descriptor
    __block QredoVaultItem *test4vaultItem=nil;
    __block XCTestExpectation *x4 = [self expectationWithDescription:@"get latest item3"];
    
    [vault getLatestItemWithDescriptor:item2Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
        test4vaultItem = vaultItem;
        [x4 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        x4 = nil;
    }];
    
    XCTAssertTrue([item2Metadata.descriptor isEqual:test4vaultItem.metadata.descriptor], @"Retrieved item should be second");
    
}


//-(void)testGetLatestFromIndex{
//    //put some data
//    
//    XCTAssertNotNil(client);
//    QredoVault *vault = [client defaultVault];
//    XCTAssertNotNil(vault);
//    
//    __block int counter =0;
//    
//    NSData *item1Data = [self randomDataWithLength:1024];
//    NSDictionary *item1SummaryValues = @{@"key1": @0};
//    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues] value:item1Data];
//    
//    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
//    
//    __block QredoVaultItemMetadata *newItemMetadata = nil;
//    
//     [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *incomingMetadata, NSError *error) {
//         XCTAssertNil(error);
//         XCTAssertNotNil(incomingMetadata);
//         [testExpectation fulfill];
//         newItemMetadata = incomingMetadata;
//         counter++;
//     }];
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        // avoiding exception when 'fulfill' is called after timeout
//        testExpectation = nil;
//    }];
//
//    XCTAssertNotNil(newItemMetadata);
//    
//    //update the item with new versions
//    
//    
//    for (int i=1;i<10;i++){
//        QredoVaultItemMetadata *updateMetadata = newItemMetadata;
//        updateMetadata.summaryValues = @{@"key1": [NSNumber numberWithInt:i],
//                                         @"key2": @"updated"};
//
//        __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
//        
//          [vault updateItem:updateMetadata value:item1Data completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
//            XCTAssertNil(error);
//            XCTAssertNotNil(newItemMetadata);
//            [testExpectation fulfill];
//            counter++;
//
//        }];
//        
//       [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//            // avoiding exception when 'fulfill' is called after timeout
//            testExpectation = nil;
//        }];
//    }
//    
//    XCTAssertTrue(counter==10,@"Didnt import 10 items");
//    
//
//    //Just get the latest item from the Index
//    QredoVaultItemDescriptor *descriptor = [[QredoVaultItemDescriptor alloc] initWithSequenceId:nil
//                                                                                  sequenceValue:0
//                                                                                         itemId:item1.metadata.descriptor.itemId];
//    __block QredoVaultItem *latestVaultItemFromCache = nil;
//    
//     __block XCTestExpectation *getFromIndexExpectation = [self expectationWithDescription:@"get fromIndex"];
//    [vault getItemWithDescriptor:descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
//        XCTAssertNil(error);
//        XCTAssertNotNil(vaultItem);
//        latestVaultItemFromCache = vaultItem;
//        [getFromIndexExpectation fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        // avoiding exception when 'fulfill' is called after timeout
//        getFromIndexExpectation = nil;
//    }];
//    
//    
//    
//    
//    NSNumber *testVal = [latestVaultItemFromCache objectForMetadataKey:@"key1"];
//    
//    XCTAssertTrue([testVal isEqualToNumber:@9],@"Didnt get the latest value from the cache");
//    XCTAssert(latestVaultItemFromCache.metadata.origin == QredoVaultItemOriginCache,@"Metata data in vault item not set correctly");
//    
//  
//    
//    //disable the index
//    [client.defaultVault metadataCacheEnabled:NO];
//    [client.defaultVault valueCacheEnabled:NO];
//    
//
//    //get from the server - should report an error
//    __block XCTestExpectation *getFromServerExpectation = [self expectationWithDescription:@"get from Server"];
//    
//    [vault getItemWithDescriptor:descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
//        XCTAssert(error);
//        XCTAssertNil(vaultItem);
//        latestVaultItemFromCache = vaultItem;
//        [getFromServerExpectation fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
//        // avoiding exception when 'fulfill' is called after timeout
//        getFromServerExpectation = nil;
//    }];
//    
//    
//    
//    
//}



- (void)testPutItem{
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(newItemMetadata);
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
 
    
}


- (void)testGetSetShortcuts{
    
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    
    NSData *item1Data = [self randomDataWithLength:1024];
    
    NSString *testVal = @"testvalue";
    
    NSDictionary *dict = @{@"key1": testVal, @"key2": @"value2"};
    
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadataDictionary:dict value:item1Data];
    
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){

        XCTAssertTrue([testVal isEqualToString:[item1 objectForMetadataKey:@"key1"]],@"Failed to retrieve summary value using QredoItem");
        XCTAssertTrue([testVal isEqualToString:[newItemMetadata objectForMetadataKey:@"key1"]],@"Failed to retrieve summary value using QredoVaultItemMetadata");
        
        
        
         XCTAssertNil(error);
         XCTAssertNotNil(newItemMetadata);
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
    
}


-(void)testMultiplePutItem{
    for (int i=0;i<10;i++){
        [self testPutItem];
    }
}


- (void)testPutItemMultiple{
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);

    for (int i = 0; i < 3; i++)
    {
        NSData *item1Data = [self randomDataWithLength:1024];
        NSString *description = [NSString stringWithFormat:@"put item %d", i];
        NSDictionary *item1SummaryValues = @{@"key1": description,
                                             @"key2": @"value2",
                                             @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
        QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                                value:item1Data];
        
        __block XCTestExpectation *testExpectation = [self expectationWithDescription:description];
        [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
         {
             XCTAssertNil(error);
             XCTAssertNotNil(newItemMetadata);
             [testExpectation fulfill];
         }];
        [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
            // avoiding exception when 'fulfill' is called after timeout
            testExpectation = nil;
        }];
    }
}



-(void)testMenualGet{
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    NSDate* created = [QredoNetworkTime dateTime];
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                                                created: created
                                                                                                          summaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         item1Descriptor = newItemMetadata.descriptor;
         [testExpectation fulfill];
     }];
    
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];

    QredoVaultItemDescriptor *qvid = [[QredoVaultItemDescriptor alloc] initWithSequenceId:nil
                                                                            sequenceValue:0
                                                                                   itemId:item1Descriptor.itemId];
    

    
    
    testExpectation = [self expectationWithDescription:@"get item 1 with descriptor"];
    [vault getLatestItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         XCTAssertNotNil(vaultItem.metadata);
         XCTAssertNotNil(vaultItem.metadata.created);
         
         // the milliseconds will not be precisely the same due to conversion to QredoUTCTime
         NSTimeInterval timeInterval = [created timeIntervalSinceDate: vaultItem.metadata.created];
         XCTAssertTrue (timeInterval < 1);
         XCTAssertTrue([vaultItem.metadata.summaryValues containsDictionary:item1SummaryValues comparison:^BOOL(id a, id b) {
             return [a isEqual:b];
         }]);
         
         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];

}

- (void)testGettingItems
{
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
     NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    NSDate* created = [QredoNetworkTime dateTime];
  
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                                                created: created
                                                                                                                summaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         item1Descriptor = newItemMetadata.descriptor;
         [testExpectation fulfill];
     }];
    
    

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];

    testExpectation = [self expectationWithDescription:@"get item 1 with descriptor"];
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         XCTAssertNotNil(vaultItem.metadata);
         XCTAssertNotNil(vaultItem.metadata.created);
         
         // the milliseconds will not be precisely the same due to conversion to QredoUTCTime
         NSTimeInterval timeInterval = [created timeIntervalSinceDate: vaultItem.metadata.created];
         XCTAssertTrue (timeInterval < 1);
         XCTAssertTrue([vaultItem.metadata.summaryValues containsDictionary:item1SummaryValues comparison:^BOOL(id a, id b) {
             return [a isEqual:b];
         }]);

         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];

    testExpectation = [self expectationWithDescription:@"get item 1 metadata"];
    [vault getItemMetadataWithDescriptor:item1Descriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItemMetadata);
         
         NSTimeInterval timeInterval = [created timeIntervalSinceDate: vaultItemMetadata.created];
         XCTAssertTrue (timeInterval < 1);

         XCTAssertTrue([vaultItemMetadata.summaryValues containsDictionary:item1SummaryValues comparison:^BOOL(id a, id b) {
             return [a isEqual:b];
         }]);

         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    
    
    // Testing errors
    QredoVaultItemDescriptor *randomDescriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:[QredoQUID QUID] itemId:[QredoQUID QUID]];

    testExpectation = [self expectationWithDescription:@"get item with random descriptor"];
    [vault getItemWithDescriptor:randomDescriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNotNil(error);
         XCTAssertNil(vaultItem);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];

    testExpectation = [self expectationWithDescription:@"get item metadata with random descriptor"];
    [vault getItemMetadataWithDescriptor:randomDescriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
     {
         XCTAssertNotNil(error);
         XCTAssertNil(vaultItemMetadata);
         
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
}



- (void)testGettingItemsFromCache
{
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    [vault addMetadataIndexObserver];
    XCTAssertNotNil(vault);

    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};

    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                            value:item1Data];

    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"put item 1"];
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         item1Descriptor = newItemMetadata.descriptor;
         XCTAssertEqual(newItemMetadata.origin, QredoVaultItemOriginServer);
         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];

    
    testExpectation = [self expectationWithDescription:@"get item 1 with descriptor"];
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);

         XCTAssertTrue([vaultItem.metadata.summaryValues containsDictionary:item1SummaryValues comparison:^BOOL(id a, id b) {
             return [a isEqual:b];
         }]);

         XCTAssertEqual(vaultItem.metadata.origin, QredoVaultItemOriginCache);

         XCTAssert([vaultItem.value isEqualToData:item1Data]);

         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];

    __block QredoVaultItemMetadata *newMetadata = nil;
    testExpectation = [self expectationWithDescription:@"get item 1 metadata"];
    [vault getItemMetadataWithDescriptor:item1Descriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItemMetadata);

         XCTAssertEqual(vaultItemMetadata.origin, QredoVaultItemOriginCache);
         newMetadata = vaultItemMetadata;

         XCTAssertTrue([vaultItemMetadata.summaryValues containsDictionary:item1SummaryValues comparison:^BOOL(id a, id b) {
             return [a isEqual:b];
         }]);

         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];

    // Update item
    testExpectation = [self expectationWithDescription:@"update item"];
    __block QredoVaultItemMetadata *updatedItemMetadata = nil;
    NSData *updatedItemData = [@"updated value" dataUsingEncoding:NSUTF8StringEncoding];
    QredoVaultItem *updatedItem = [QredoVaultItem vaultItemWithMetadata:newMetadata
                                                                  value:updatedItemData];
    [vault putItem:updatedItem completionHandler:^(QredoVaultItemMetadata *itemMetadata, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(itemMetadata);

        XCTAssertEqual(itemMetadata.origin, QredoVaultItemOriginServer);
        updatedItemMetadata = itemMetadata;
        [testExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        testExpectation = nil;
    }];


    testExpectation = [self expectationWithDescription:@"get original metadata after update"];
    [vault getItemMetadataWithDescriptor:item1Descriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItemMetadata);

         XCTAssertEqual(vaultItemMetadata.origin, QredoVaultItemOriginServer);

         XCTAssertTrue([vaultItemMetadata.summaryValues containsDictionary:item1SummaryValues comparison:^BOOL(id a, id b) {
             return [a isEqual:b];
         }]);

         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];


    testExpectation = [self expectationWithDescription:@"get updated metadata after update"];
    [vault getItemMetadataWithDescriptor:updatedItemMetadata.descriptor
                       completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItemMetadata);

         XCTAssertEqual(vaultItemMetadata.origin, QredoVaultItemOriginCache);

         XCTAssertTrue([vaultItemMetadata.summaryValues containsDictionary:item1SummaryValues comparison:^BOOL(id a, id b) {
             return [a isEqual:b];
         }]);

         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];

    testExpectation = [self expectationWithDescription:@"get original item body (should not be in cache)"];
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);

         XCTAssertEqual(vaultItem.metadata.origin, QredoVaultItemOriginServer);

         XCTAssert([vaultItem.value isEqualToData:item1Data]);

         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];


    testExpectation = [self expectationWithDescription:@"get updated item body"];
    [vault getItemWithDescriptor:updatedItemMetadata.descriptor
               completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);

         XCTAssertEqual(vaultItem.metadata.origin, QredoVaultItemOriginCache);

         XCTAssert([vaultItem.value isEqualToData:updatedItemData]);

         [testExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    [client closeSession];
}

- (void)testEnumeration
{
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);

    __block NSError *error = nil;
    __block int count = 0;
    __block XCTestExpectation *testExpectation = [self expectationWithDescription:@"Enumerate"];
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;

    } completionHandler:^(NSError *errorBlock) {
        XCTAssertNil(errorBlock);
        error = errorBlock;
        [testExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testExpectation = nil;
    }];
    XCTAssertNil(error);
}




- (void)testEnumerationReturnsCreatedItem
{
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    // Create an item and store in vault
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                            value:item1Data];

    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    
    __block XCTestExpectation *putItemCompletedExpectation = [self expectationWithDescription:@"PutItem completion handler called"];
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error, @"Error occurred during PutItem");
         item1Descriptor = newItemMetadata.descriptor;

         [putItemCompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        putItemCompletedExpectation = nil;
    }];
    XCTAssertNotNil(item1Descriptor, @"Descriptor returned is nil");
    
    // Confirm the item is found in the vault
    __block XCTestExpectation *getItemCompletedExpectation = [self expectationWithDescription:@"GetItem completion handler called"];
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key1"], item1SummaryValues[@"key1"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key2"], item1SummaryValues[@"key2"]);
         XCTAssertEqualObjects(vaultItem.metadata.summaryValues[@"key3"], item1SummaryValues[@"key3"]);
         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         
         [getItemCompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        getItemCompletedExpectation = nil;
    }];

    // Confirm enumerate finds item we added
    __block int count = 0;
    __block BOOL itemFound = NO;
    __block XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];

    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;
        
        XCTAssertNotNil(vaultItemMetadata);
        
       if ([vaultItemMetadata.summaryValues[@"key1"] isEqual:item1SummaryValues[@"key1"]] &&
            [vaultItemMetadata.summaryValues[@"key2"] isEqual:item1SummaryValues[@"key2"]] &&
            [vaultItemMetadata.summaryValues[@"key3"] isEqual:item1SummaryValues[@"key3"]])
        {
            itemFound = YES;
        }
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [completionHandlerCalled fulfill];
    }];
    
    // Note: May need a longer timeout if there's lots of items to enumerate. May depend on how many items added since test last run.
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        completionHandlerCalled = nil;
    }];

    XCTAssertTrue(itemFound, "Item just created was not found during enumeration.");
    
    // Note: DH - Apparently server returns 50 items, so once 50 items created this test will fail.  Looks like it returns first 50 items, rather than latest 50 items.
    if (!itemFound && count == 50)
    {
        XCTFail(@"Created item was not found and 50 items were enumerated. Likely failure was due to server only returning oldest 50 items.");
    }
}

- (void)testEnumerationAbortsOnStop
{
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    // Create 2 items and store in vault (ensures there's more than 1 item in vault when enumerating
    NSData *item1Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    NSData *item2Data = [NSData qtu_dataWithRandomBytesOfLength:1024];
    NSDictionary *item2SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    
    QredoVaultItem *item2 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item2SummaryValues]
                                                            value:item2Data];

    __block XCTestExpectation *putItem1CompletedExpectation = [self expectationWithDescription:@"PutItem 1 completion handler called"];
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error, @"Error occurred during PutItem");
         XCTAssertNotNil(newItemMetadata, @"New item metadata for item 1 was nil");
         
         [putItem1CompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        putItem1CompletedExpectation = nil;
    }];
    
    __block XCTestExpectation *putItem2CompletedExpectation = [self expectationWithDescription:@"PutItem 2 completion handler called"];
    [vault putItem:item2 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error, @"Error occurred during PutItem");
         XCTAssertNotNil(newItemMetadata, @"New item metadata for item 2 was nil");
         
         [putItem2CompletedExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        putItem2CompletedExpectation = nil;
    }];

    // Confirm enumerate 'stop' aborts enumeration
    __block int count = 0;
    __block BOOL stopWasSet = NO;
    __block XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;
        
        XCTAssertNotNil(vaultItemMetadata);
        
        // If 1st item, then we set stop
        if (count == 1) {
            *stop = YES;
            stopWasSet = YES;
        }
        else {
            // Should not get here if 'stop' worked
            XCTFail(@"Enumerated more than 1 item, but stop had been set after 1st item");
        }
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [completionHandlerCalled fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        completionHandlerCalled = nil;
    }];
    
    XCTAssertTrue(stopWasSet, "Never set the 'stop' flag.");
    XCTAssertTrue(count == 1, "Enumerated more than 1 item, despite setting 'stop' after first item.");
}

- (void)testListener
{
    XCTAssertNotNil(client);
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);

    QredoVaultListener *listener = [[QredoVaultListener alloc] init];
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];

    [vault addVaultObserver:listener];
    
    // Create an item to ensure that there's data later than any current HWM
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2"};
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                            value:item1Data];
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         item1Descriptor = newItemMetadata.descriptor;
     }];

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener.didReceiveVaultItemMetadataExpectation = nil;
    }];
    XCTAssertNil(listener.error);
    XCTAssertNotNil(listener.receivedItems);
    XCTAssertTrue(listener.receivedItems.count > 0);


//    [vault removeVaultObserver:listener];
    [client closeSession];
}

- (void)testMultipleListeners
{
    XCTAssertNotNil(client);
    
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    QredoVaultListener *listener1 = [[QredoVaultListener alloc] init];
    listener1.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    
    [vault addVaultObserver:listener1];
    
    QredoVaultListener *listener2 = [[QredoVaultListener alloc] init];
    listener2.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    
    [vault addVaultObserver:listener2];
    
    // Create an item to ensure that there's data later than any current HWM
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2"};
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                                value:item1Data];
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         XCTAssertNil(error);
         item1Descriptor = newItemMetadata.descriptor;
     }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        listener1.didReceiveVaultItemMetadataExpectation = nil;
        listener2.didReceiveVaultItemMetadataExpectation = nil;
    }];
    XCTAssertNil(listener1.error);
    XCTAssertNotNil(listener1.receivedItems);
    XCTAssertTrue(listener1.receivedItems.count > 0);

    XCTAssertNil(listener2.error);
    XCTAssertNotNil(listener2.receivedItems);
    XCTAssertTrue(listener2.receivedItems.count > 0);

    
//    [vault removeVaultObserver:listener1];
//    [vault removeVaultObserver:listener2];
    
    
    [client closeSession];
    
}


- (void)testRemovingListenerDurringNotification
{
    XCTAssertNotNil(client);
    
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    NSMutableArray *listeners = [NSMutableArray new];
    
    for (int i = 0; i < 20; i++) {
        QredoVaultListenerWithEmptyImplementation *listener = [[QredoVaultListenerWithEmptyImplementation alloc] initWithVault:vault];
        [listeners addObject:listener];
    }
    
    
    __block BOOL keepNotifying = YES;
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        
        while (keepNotifying) {
            [vault notifyObservers:^(id<QredoVaultObserver> observer) {
                [observer qredoVault:vault didReceiveVaultItemMetadata:nil];
                [observer qredoVault:vault didFailWithError:nil];
            }];
        }
        
    });
    
    
    __block XCTestExpectation *allListnersRemovedExpectation = [self expectationWithDescription:@"All listners are removed"];

    
    [self removeLastListenerOrFinishWith:listeners allListnersRemovedExpectation:allListnersRemovedExpectation];
    
    int timeout = (int)[listeners count]*10;
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        allListnersRemovedExpectation = nil;
    }];
    
    keepNotifying = NO;
}

- (void)testMultipleRemovingListenerDurringNotification
{
    for (int i = 0; i < 10; i++) {
        [self testRemovingListenerDurringNotification];
    }
}

- (void)removeLastListenerOrFinishWith:(NSMutableArray *)listeners allListnersRemovedExpectation:(XCTestExpectation *)allListnersRemovedExpectation{
    QredoVaultListenerWithEmptyImplementation *listener = [listeners lastObject];
    if (listener) {
        
        [listeners removeObject:listener];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self removeLastListenerOrFinishWith:listeners allListnersRemovedExpectation:allListnersRemovedExpectation];
        });
        
    } else {
        
        [allListnersRemovedExpectation fulfill];
        
    }

}

- (void)testRemovingNotObservingListener
{
    XCTAssertNotNil(client);
    
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);
    
    QredoVaultListener *listener1 = [[QredoVaultListener alloc] init];
    [vault addVaultObserver:listener1];
    
    QredoVaultListener *listener2 = [[QredoVaultListener alloc] init];
    
    XCTAssertNoThrow([vault removeVaultObserver:listener2]);
    XCTAssertNoThrow([vault removeVaultObserver:listener1]);
}


- (void)testVaultItemMetadataAndMutableMetadata
{
    QredoVaultItemDescriptor *descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:[QredoQUID QUID] itemId:[QredoQUID QUID]];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2"};
    
    NSDate* created = [QredoNetworkTime dateTime];
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                                                      dataType:@"blob"
                                                                                       created:created
                                                                                 summaryValues:item1SummaryValues];
    
    QredoVaultItemMetadata *aCopy = [metadata copy];
    
    XCTAssertEqualObjects(aCopy.descriptor, metadata.descriptor);
    XCTAssertEqualObjects(aCopy.dataType, metadata.dataType);
    XCTAssertEqual(aCopy.accessLevel, metadata.accessLevel);
    XCTAssertEqualObjects(aCopy.summaryValues, metadata.summaryValues);
    
    QredoMutableVaultItemMetadata *aMutableCopy = [metadata mutableCopy];
    
    XCTAssertEqualObjects(aMutableCopy.descriptor, metadata.descriptor);
    XCTAssertEqualObjects(aMutableCopy.dataType, metadata.dataType);
    XCTAssertEqual(aMutableCopy.accessLevel, metadata.accessLevel);
    XCTAssertEqualObjects(aMutableCopy.summaryValues, metadata.summaryValues);
    
    
    
    NSDictionary *aMutableCopySummaryValues = @{@"key1": @"value1",
                                                @"key2": @"value2",
                                                @"key3": @"value3"};
    
    [aMutableCopy setSummaryValue:@"value3" forKey:@"key3"];
    
    XCTAssertEqualObjects(aMutableCopy.descriptor, metadata.descriptor);
    XCTAssertEqualObjects(aMutableCopy.dataType, metadata.dataType);
    XCTAssertEqual(aMutableCopy.accessLevel, metadata.accessLevel);
    XCTAssertEqualObjects(aMutableCopy.summaryValues, aMutableCopySummaryValues);
    
    QredoMutableVaultItemMetadata *mutableMetadata = [QredoMutableVaultItemMetadata vaultItemMetadataWithSummaryValues:nil];
    
    NSDictionary *mutableMetadataSummaryValues = @{@"key3": @"value3"};
    
    [mutableMetadata setSummaryValue:@"value3" forKey:@"key3"];
    
    XCTAssertEqualObjects(mutableMetadata.summaryValues, mutableMetadataSummaryValues);
}





@end
