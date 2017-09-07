/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoTestUtils.h"
#import "QredoPrivate.h"
#import "MasterConfig.h"
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
    //NSLog(@"Options New %@",optionsNew);
    XCTAssertTrue([optionsNew.appGroup isEqualToString:options.appGroup]);
    
}




-(void)testTestClient {
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:k_TEST_USERID
                          userSecret:[self randomPassword]
                             options:self.clientOptions
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                      
                       client = clientArg;
                       
                       QredoLogInfo(@"Version is  %@",[clientArg versionString]);
                       QredoLogInfo(@"Build is    %@",[clientArg buildString]);
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
