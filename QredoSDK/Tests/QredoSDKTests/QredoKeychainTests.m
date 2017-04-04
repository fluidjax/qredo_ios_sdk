/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "QredoVaultTests.h"
#import "Qredo.h"
#import "QredoTestUtils.h"
#import "NSDictionary+Contains.h"
#import "QredoVaultPrivate.h"
#import "SSLTimeSyncServer.h"
#import "QredoLocalIndex.h"
#import "QredoLocalIndexDataStore.h"


@interface QredoKeychainTests : XCTestCase

@end

@implementation QredoKeychainTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}




-(void)addVaultItem:(QredoClient*)client{
    QredoVault *vault = [client defaultVault];
    XCTAssertNotNil(vault);


    NSData *item1Data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1"};
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


-(QredoClient*)makeClient:(NSString*)password{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    __block QredoClient *client = nil;
    
    [QredoClient initializeWithAppId:k_APPID
                           appSecret:k_APPSECRET
                              userId:k_USERID
                          userSecret:password
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
    return client;
}




-(void)testTemp{
    //this test create a client and puts 1 item in it
    //then changes the userSecure (ie. user changes password)
    //it moves the keychain from the old to the new
    //check that the new user credentials can access the 1 item.
    
    [QredoLogger setLogLevel:QredoLogLevelVerbose];
    NSString  *password2 = @"pass55";
    QredoClient *client2 = [self makeClient:password2];
    
    
    //get vault item from server
    __block int count =0;
    __block XCTestExpectation *testEnumExpectation = [self expectationWithDescription:@"test enum"];
    
    [client2.defaultVault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        QredoVaultItemMetadata *meta = vaultItemMetadata;
        NSString *value = [meta objectForMetadataKey:@"key1"];
        
        count++;
    } completionHandler:^(NSError *error) {
        [testEnumExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testEnumExpectation = nil;
    }];
    

}

-(void)testChangeUserSecure{
    //this test create a client and puts 1 item in it
    //then changes the userSecure (ie. user changes password)
    //it moves the keychain from the old to the new
    //check that the new user credentials can access the 1 item.

    [QredoLogger setLogLevel:QredoLogLevelVerbose];
//    NSString  *password1 = [QredoTestUtils randomPassword];
//    NSString  *password2 = [QredoTestUtils randomPassword];
//    
    NSString  *password1 = @"pass55";
    NSString  *password2 = @"pass66";

    

    QredoClient *client1 = [self makeClient:password1];
    XCTAssertNotNil(client1);
    NSInteger before1 = [client1.defaultVault.localIndex count];
    if (before1==0)[self addVaultItem:client1];
    before1 = [client1.defaultVault.localIndex count];
    XCTAssert(before1==1,@"Client 1 vault should have 1 items");
    [client1 closeSession];

    
    //move the keychain
    NSError *error=nil;
    [QredoClient changeUserCredentialsAppId:k_APPID
                                     userId:k_USERID
                             fromUserSecure:password1
                               toUserSecure:password2
                                      error:&error];
    
    
    
    //check client 2 for 1 item from server
    QredoClient *client2 = [self makeClient:password2];
    NSInteger afterMove = [client2.defaultVault.localIndex count];
    XCTAssert(afterMove==1,@"Client 2 should have 1 item copied from the old client");
    
    
    
    
    //get vault item from server
    __block int count =0;
    __block XCTestExpectation *testEnumExpectation = [self expectationWithDescription:@"test enum"];
    
    [client2.defaultVault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        QredoVaultItemMetadata *meta = vaultItemMetadata;
        NSString *value = [meta objectForMetadataKey:@"key1"];
        
        count++;
    } completionHandler:^(NSError *error) {
        [testEnumExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        testEnumExpectation = nil;
    }];

    
    
    
}



@end
