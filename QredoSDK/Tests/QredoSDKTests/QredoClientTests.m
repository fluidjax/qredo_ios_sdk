/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoTestUtils.h"
#import "QredoPrivate.h"

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



-(void)testUserDefaultsStorageOfCredentials{
    NSString *appGroup = @"group.com.qredo.ChrisPush1";
    [QredoClient setAppGroup:appGroup];
    
    
    [QredoClient deleteCredentialsInUserDefaults];
    XCTAssertTrue([QredoClient hasCredentialsInUserDefaults]==NO,@"UserDefault credentials should be empty");
    
    NSString *pass = [self randomPassword];

    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    

    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:@"testuser"
                          userSecret:pass
                            appGroup:appGroup
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       
                       client = clientArg;
                       [client saveCredentialsInUserDefaults];
                       XCTAssertTrue([QredoClient hasCredentialsInUserDefaults]==YES,@"UserDefault credentials should not be empty");
                       [clientExpectation fulfill];
                   }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    
    XCTAssertTrue([QredoClient hasCredentialsInUserDefaults]==YES,@"UserDefault credentials should not be empty");
    
    
    NSDictionary *credentials = [QredoClient retrieveCredentialsUserDefaults];
    NSLog(@"CREDENTIAL ARE %@", credentials);
    XCTAssert([[credentials objectForKey:@"D"] isEqualToString:pass],@"Credentials not saved & retrieved correctly");
    

    
    //Check store credentials
    
    __block XCTestExpectation *clientExpectation2 = [self expectationWithDescription:@"create client"];
    
    
    [QredoClient initializeFromUserDefaultCredentialsWithCompletionHandler:^(QredoClient *client2, NSError *error) {
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
    
    XCTAssertTrue([QredoClient hasCredentialsInUserDefaults],@"There should be items in the userdefaults");
    [QredoClient deleteCredentialsInUserDefaults];
    XCTAssertFalse([QredoClient hasCredentialsInUserDefaults],@"There shouldn't be items in the userdefaults");

    
    

}

-(void)testKeychainStorage{
    //test the storage of the Qredo Credentials in the keychain
    
    [QredoClient setKeyChainGroup:@"com.qredo.ChrisPush1"];
    
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    
    [QredoClient deleteCredentialsInKeychain];
    XCTAssertFalse([QredoClient hasCredentialsInKeychain],@"There shouldn't be items in the keychain");    
    
    
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
    
    
    XCTAssertTrue([QredoClient hasCredentialsInKeychain],@"There should be items in the keychain");

    
    
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

    XCTAssertTrue([QredoClient hasCredentialsInKeychain],@"There should be items in the keychain");
    [QredoClient deleteCredentialsInKeychain];
    XCTAssertFalse([QredoClient hasCredentialsInKeychain],@"There shouldn't be items in the keychain");

    
    
    
    
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
