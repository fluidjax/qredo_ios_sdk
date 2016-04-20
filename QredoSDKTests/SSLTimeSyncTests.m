//
//  SSLTimeSyncTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 20/04/2016.
//
//

#import <XCTest/XCTest.h>
#import "SSLTimeSyncServer.h"

@interface SSLTimeSyncTests : XCTestCase

@end

@implementation SSLTimeSyncTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    //we assume that the local clock on the testing machine is set correctly
    
    [SSLTimeSyncServer start];
    NSDate *now = [NSDate date];
    NSDate *unsyncedDate = [SSLTimeSyncServer dateTEST];
    
    NSLog(@"Now         %@",now);
    NSLog(@"Unsynced    %@",unsyncedDate);
    
    [NSThread sleepForTimeInterval:5];
    
    NSDate *syncedDate = [SSLTimeSyncServer dateTEST];
    NSLog(@"Synced    %@",syncedDate);
    
    NSTimeInterval synced = [syncedDate timeIntervalSinceDate:now];
    //this value is 33 (test offset) + sleep 5 seconds, + time take to do HTTPS get request
    XCTAssertTrue(synced>35 && synced<45,@"The date from the server is too different to the local date");
    
    
}



@end
