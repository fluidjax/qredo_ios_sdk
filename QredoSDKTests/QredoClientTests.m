//
//  QredoClientTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 11/12/2015.
//
//

#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoTestUtils.h"
#import "NSDictionary+Contains.h"
#import "QredoVaultPrivate.h"


@interface QredoClientTests : XCTestCase

@end

@implementation QredoClientTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}




-(void)testSuccessConnectToClient{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppSecret:@"cafebabe"
                                  userId:@"testuser"
                              userSecret:[QredoTestUtils randomPassword]
                                 options:nil
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
}

-(void)testFailingConnectToClient{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppSecret:@"FAILINGSECRET"
                                  userId:@"testuser"
                              userSecret:[QredoTestUtils randomPassword]
                                 options:nil
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNotNil(error);
                           XCTAssertNil(clientArg);
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
}



@end
