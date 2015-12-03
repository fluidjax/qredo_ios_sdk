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

@interface QredoIndexVaultTests : XCTestCase

@end

@implementation QredoIndexVaultTests

QredoClient *client1;

- (void)setUp {
    [super setUp];
    [self authoriseClient];
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


-(void)testIndexPut{
    XCTAssertNotNil(client1);
    QredoVault *vault = [client1 defaultVault];
    XCTAssertNotNil(vault);
    
    
    NSData *item1Data = [self randomDataWithLength:1024];
    NSDictionary *item1SummaryValues = @{@"key1": @"value1",
                                         @"key2": @"value2",
                                         @"key3": [[NSData qtu_dataWithRandomBytesOfLength:16] description]};
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                                            accessLevel:0
                                                                                                          summaryValues:item1SummaryValues]
                                                            value:item1Data];
    
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
    

   // NSBundle *bundle = [QredoIndexVaultTests getBundle];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"mom"];

    
    
    QredoLocalIndex *qredoLocalIndex = [QredoLocalIndex sharedQredoLocalIndexTEST:modelURL];
    [qredoLocalIndex putItemWithMetadata:createdItemMetaData];

}



@end
