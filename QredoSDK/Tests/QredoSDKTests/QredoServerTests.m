//
//  QredoServerTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 30/03/2017.
//
//

#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "MasterConfig.h"
#import "QredoTestUtils.h"


@interface QredoServerTests :QredoXCTestCase

@end

@implementation QredoServerTests :QredoXCTestCase


-(void)setUp {
    [super setUp];
}


-(void)testLiveServer {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    self.clientOptions = [[QredoClientOptions alloc] initLive];
    
    [QredoClient initializeWithAppId:LIVE_SERVER_APP_ID
                           appSecret:LIVE_SERVER_APP_SECRET
                              userId:k_TEST_USERID
                          userSecret:[self randomPassword]
                             options:self.clientOptions
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       client = clientArg;
                       QLog(@"Version is  %@",[clientArg versionString]);
                       QLog(@"Build is    %@",[clientArg buildString]);
                       [clientExpectation fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    [client closeSession];
}

-(void)testDevServer {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    self.clientOptions = [[QredoClientOptions alloc] initDev];
    
    [QredoClient initializeWithAppId:DEV_SERVER_APP_ID
                           appSecret:DEV_SERVER_APP_SECRET
                              userId:k_TEST_USERID
                          userSecret:[self randomPassword]
                             options:self.clientOptions
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       client = clientArg;
                       QLog(@"Version is  %@",[clientArg versionString]);
                       QLog(@"Build is    %@",[clientArg buildString]);
                       [clientExpectation fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    [client closeSession];
}


-(void)testTestServer {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    self.clientOptions = [[QredoClientOptions alloc] initTest];
    
    [QredoClient initializeWithAppId:TEST_SERVER_APP_ID
                           appSecret:TEST_SERVER_APP_SECRET
                              userId:k_TEST_USERID
                          userSecret:[self randomPassword]
                             options:self.clientOptions
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       client = clientArg;
                       QLog(@"Version is  %@",[clientArg versionString]);
                       QLog(@"Build is    %@",[clientArg buildString]);
                       [clientExpectation fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    [client closeSession];
}



@end
