#import <UIKit/UIKit.h>
#import "QredoXCTestCase.h"
#import <XCTest/XCTest.h>
#import "QredoRendezvousCrypto.h"
#import "QredoCrypto.h"
#import "CryptoImpl.h"
#import "CryptoImplV1.h"
#import "NSData+ParseHex.h"

#import <XCTest/XCTest.h>

@interface SystemVaultTests : QredoXCTestCase
@end


@interface SystemVaultTests ()
{
    QredoClient *client;
    NSString *savedPassword;
    NSString *savedUsername;
    
}

@end

@implementation SystemVaultTests

- (void)setUp {
    [super setUp];
    savedPassword = @"testpassword1";
    savedUsername = @"testuser1";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}





-(void)testPutIntoSystemVault{
   //create a known client
    [self createClient:savedPassword user:savedUsername];
    [self createRendezvous];
}



-(void)testListentOnSystemVault{
   client = [self createClient:savedPassword user:savedUsername];
    
    for (int i=0;i<10000;i++){
        NSLog(@"Index Size on System vault is %i",client.systemVault.indexSize);
        [NSThread sleepForTimeInterval:1.0f];
    }
    
    
}



- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
