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


-(void)testQredoClientOptionsNSCoding{
    QredoClientOptions *options = [[QredoClientOptions alloc] initTest];
    options.appGroup = @"test1";
    
    NSData *optionsCoded = [NSKeyedArchiver archivedDataWithRootObject:options];
    
    QredoClientOptions *optionsNew = (QredoClientOptions*) [NSKeyedUnarchiver unarchiveObjectWithData:optionsCoded];
    
    
    NSLog(@"Options New %@",optionsNew);
    XCTAssertTrue([optionsNew.appGroup isEqualToString:options.appGroup]);
    
}

-(void)testUserDefaultsStorageOfCredentials{
    NSString *appGroup = @"group.com.qredo.ChrisPush1";
    
    [QredoClient deleteCredentialsInUserDefaultsAppGroup:appGroup];
    XCTAssertTrue([QredoClient hasCredentialsInUserDefaultsAppGroup:appGroup]==NO,@"UserDefault credentials should be empty");
    
    NSString *pass = [self randomPassword];

    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    

    QredoClientOptions *options = [[QredoClientOptions alloc] initTest];
    options.appGroup = appGroup;
    
    
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:@"testuser"
                          userSecret:pass
                             options:options
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       
                       client = clientArg;
                       [client saveCredentialsInUserDefaults];
                       XCTAssertTrue([QredoClient hasCredentialsInUserDefaultsAppGroup:appGroup]==YES,@"UserDefault credentials should not be empty");
                       [clientExpectation fulfill];
                   }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    
    XCTAssertTrue([QredoClient hasCredentialsInUserDefaultsAppGroup:appGroup]==YES,@"UserDefault credentials should not be empty");
    
    
    NSDictionary *credentials = [QredoClient retrieveCredentialsUserDefaultsAppGroup:appGroup];
    NSLog(@"CREDENTIAL ARE %@", credentials);
    XCTAssert([[credentials objectForKey:@"QD"] isEqualToString:pass],@"Credentials not saved & retrieved correctly");
    

    
    //Check store credentials
    
    __block XCTestExpectation *clientExpectation2 = [self expectationWithDescription:@"create client"];
    
    
    [QredoClient  initializeFromUserDefaultCredentialsInAppGroup:appGroup
                                           withCompletionHandler:^(QredoClient *client2, NSError *error) {
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
    
    XCTAssertTrue([QredoClient hasCredentialsInUserDefaultsAppGroup:appGroup],@"There should be items in the userdefaults");
    [QredoClient deleteCredentialsInUserDefaultsAppGroup:appGroup];
    XCTAssertFalse([QredoClient hasCredentialsInUserDefaultsAppGroup:appGroup],@"There shouldn't be items in the userdefaults");

    
    

}

-(void)testKeychainStorage{
    //test the storage of the Qredo Credentials in the keychain
    
    NSString *keyChainGroup = @"com.qredo.ChrisPush1";
    
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    
    [QredoClient deleteCredentialsInKeychainGroup:keyChainGroup];
    XCTAssertFalse([QredoClient hasCredentialsInKeychainGroup:keyChainGroup],@"There shouldn't be items in the keychain");
    
    
    QredoClientOptions *options = [[QredoClientOptions alloc] initTest];
    options.keyChainGroup = keyChainGroup;
    

    
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:@"testuser"
                          userSecret:[self randomPassword]
                             options:options
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
    
    
    XCTAssertTrue([QredoClient hasCredentialsInKeychainGroup:keyChainGroup],@"There should be items in the keychain");

    
    
    __block XCTestExpectation *clientExpectation2 = [self expectationWithDescription:@"create client"];
    
    
    [QredoClient initializeFromKeychainCredentialsInGroup:keyChainGroup
                                    withCompletionHandler:^(QredoClient *client2, NSError *error) {
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

    XCTAssertTrue([QredoClient hasCredentialsInKeychainGroup:keyChainGroup],@"There should be items in the keychain");
    [QredoClient deleteCredentialsInKeychainGroup:keyChainGroup];
    XCTAssertFalse([QredoClient hasCredentialsInKeychainGroup:keyChainGroup],@"There shouldn't be items in the keychain");

    
    
    
    
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
