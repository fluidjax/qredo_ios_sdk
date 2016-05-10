//
//  TestFrameworkTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 10/05/2016.
//
//

#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"


@interface TestFrameworkTests : QredoXCTestCase

@end

@implementation TestFrameworkTests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



-(void)testStack1{
    [self buildStack1];
}


-(void)testStack2{
    [self buildStack2];
}



@end
