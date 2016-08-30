//
//  QredoClientTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 11/12/2015.
//
//

#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoTestUtils.h"

#import "NSDictionary+Contains.h"


@interface QredoClientTests : QredoXCTestCase

@end

@implementation QredoClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void)showVersions{

}





-(void)testLogging{
    [self testSuccessConnectToClient];
    [QredoLogger setLogLevel:QredoLogLevelVerbose];
    QredoLogError  (@"Ignore this intentional error:   %@", ^{ return @"generated error message from block"; }());
    QredoLogWarning(@"Ignore this intentional warning: %@", ^{ return @"generated error message from block"; }());
    QredoLogInfo   (@"Ignore this intentional info:    %@", ^{ return @"generated error message from block"; }());
    QredoLogDebug  (@"Ignore this intentional debug:   %@", ^{ return @"generated error message from block"; }());
    QredoLogVerbose(@"Ignore this intentional verbose: %@", ^{ return @"generated error message from block"; }());
    [QredoLogger setLogLevel:QredoLogLevelNone];
}


-(void)testDefaultClient{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:@"testuser"
                          userSecret:[self randomPassword]
                   completionHandler:^(QredoClient *clientArg, NSError *error) {
                       
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       [clientExpectation fulfill];
                       client = clientArg;
                       
                       QLog(@"Version is  %@",[clientArg versionString]);
                       QLog(@"Build is    %@",[clientArg buildString]);
                       
                       
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
    [client closeSession];
}






-(void)testConnectAndCloseMultiple{
    for (int i=0;i<10;i++){
        [self testConnectAndClose];
    }
}


-(void)testConnectAndClose{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
   

    __block QredoClient *client;
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:@"testuser"
                          userSecret:[self randomPassword]
                             options:nil

                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           [clientExpectation fulfill];
                           client = clientArg;
                           
                           QLog(@"Version is  %@",[clientArg versionString]);
                           QLog(@"Build is    %@",[clientArg buildString]);
                           
                           
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
    [client closeSession];


}


-(void)testSuccessConnectToClient{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:k_TEST_USERID
                          userSecret:[self randomPassword]
                   completionHandler:^(QredoClient *clientArg, NSError *error) {
                        //   XCTAssertNil(error);
                         //  XCTAssertNotNil(clientArg);
                           [clientExpectation fulfill];
                           
                           QLog(@"Version is  %@",[clientArg versionString]);
                           QLog(@"Build is    %@",[clientArg buildString]);
                           
                           
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
}

-(void)testFailingConnectToClient{
    [QredoLogger setLogLevel:QredoLogLevelNone];
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:@"FAILINGSECRET"
                           appSecret:k_TEST_APPSECRET
                              userId:k_TEST_USERID
                          userSecret:[self randomPassword]
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
