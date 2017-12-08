/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <XCTest/XCTest.h>
#import "QredoNetworkTime.h"

@interface SSLTimeSyncTests :XCTestCase

@end

@implementation SSLTimeSyncTests

-(void)setUp {
    [super setUp];
    //Put setup code here. This method is called before the invocation of each test method in the class.
}


-(void)tearDown {
    //Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


//-(void)testExampleMultiple{
//for (int i=0;i<100;i++){
//NSLog(@"Count %i",i);
//[self testExample];
//}
//}

-(void)testExample {
    //we assume that the local clock on the testing machine is set correctly
    
    [QredoNetworkTime start];
    NSDate *now = [NSDate date];
    NSDate *unsyncedDate = [QredoNetworkTime dateTEST];
    
    NSLog(@"Now         %@",now);
    NSLog(@"Unsynced    %@",unsyncedDate);
    
    [NSThread sleepForTimeInterval:5];
    
    NSDate *syncedDate = [QredoNetworkTime dateTEST];
    NSLog(@"Synced    %@",syncedDate);
    
    NSTimeInterval synced = [syncedDate timeIntervalSinceDate:now];
    //this value is 33 (test offset) + sleep 5 seconds, + time take to do HTTPS get request
    XCTAssertTrue(synced > 20 && synced < 45,@"The date from the server is too different to the local date");
}


@end
