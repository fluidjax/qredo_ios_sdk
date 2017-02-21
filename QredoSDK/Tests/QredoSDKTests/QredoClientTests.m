/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoTestUtils.h"

#import "NSDictionary+Contains.h"


@interface QredoClientTests :QredoXCTestCase

@end

@implementation QredoClientTests

-(void)setUp {
    [super setUp];
}


-(void)tearDown {
    //Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void)showVersions {
}


-(void)testLogging {
    [self testSuccessConnectToClient];
    [QredoLogger setLogLevel:QredoLogLevelVerbose];
    QredoLogError(@"Ignore this intentional error:   %@",^{ return @"generated error message from block"; } ());
    QredoLogWarning(@"Ignore this intentional warning: %@",^{ return @"generated error message from block"; } ());
    QredoLogInfo(@"Ignore this intentional info:    %@",^{ return @"generated error message from block"; } ());
    QredoLogDebug(@"Ignore this intentional debug:   %@",^{ return @"generated error message from block"; } ());
    QredoLogVerbose(@"Ignore this intentional verbose: %@",^{ return @"generated error message from block"; } ());
    [QredoLogger setLogLevel:QredoLogLevelNone];
}


-(void)testKeychainStorage{
    //test the storage of the Qredo Credentials in the keychain
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:@"testuser"
                          userSecret:[self randomPassword]
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       
                       client = clientArg;

                   
                       [client saveCredentialsInKeychain];
                       [clientExpectation fulfill];
                   }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    
    [client closeSession];
    
    
    __block XCTestExpectation *clientExpectation2 = [self expectationWithDescription:@"create client"];
    
    
    [QredoClient initializeFromKeychainCredentialsWithCompletionHandler:^(QredoClient *client2, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(client2);
        if ([client2 isClosed]==NO){
            NSLog(@"Retrieved a credential set from the keychain and establish a Qredo Client");
        }
        [clientExpectation2 fulfill];
    }];
     
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];

    
    
}


-(void)testDefaultClient {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:@"testuser"
                          userSecret:[self randomPassword]
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


-(void)testConnectAndCloseMultiple {
    for (int i = 0; i < 10; i++){
        [self testConnectAndClose];
    }
}


-(void)testConnectAndClose {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    
    __block QredoClient *client;
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:@"testuser"
                          userSecret:[self randomPassword]
                             options:nil
     
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       [clientExpectation fulfill];
                       client = clientArg;
                       
                       QLog(@"Version is  %@",[clientArg versionString]);
                       QLog(@"Build is    %@",[clientArg buildString]);
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    
    [client closeSession];
}


-(void)testSuccessConnectToClient {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:[self randomUsername]
                          userSecret:[self randomPassword]
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       //XCTAssertNil(error);
                       //XCTAssertNotNil(clientArg);
                       [clientExpectation fulfill];
                       
                       QLog(@"Version is  %@",[clientArg versionString]);
                       QLog(@"Build is    %@",[clientArg buildString]);
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
}


-(void)testFailingConnectToClient {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient initializeWithAppId:@"FAILINGSECRET"
                           appSecret:k_TEST_APPSECRET
                              userId:[self randomUsername]
                          userSecret:[self randomPassword]
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNotNil(error);
                       XCTAssertNil(clientArg);
                       [clientExpectation fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
}


@end
