//
//  ApplePushNotificationTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 30/01/2017.
//
//

#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
@import UserNotifications;

@interface ApplePushNotificationTests : QredoXCTestCase

@end

@implementation ApplePushNotificationTests
    XCTestExpectation *waitForToken;


- (void)setUp {
    [super setUp];
    
#if (TARGET_OS_SIMULATOR)
    XCTFail(@"Can't run Push tests in simulator");
    exit(0);
#endif

    
//    waitForToken = [self expectationWithDescription:@"waitForToken"];
//    [self requestNotificationToken];
//    
//    [self waitForExpectationsWithTimeout:30
//                                 handler:^(NSError *error) {
//                                     waitForToken = nil;
//                                 }];

    
    
}

- (void)tearDown {
    [super tearDown];
}


-(void)testGood{
    XCTAssertTrue(1==1,@"good");
}



-(void)testSimplePush{
    NSLog(@"Completed setup");
    //resgiter with APNS
    //Client 1 create Rendezvous
    //Client 2 create Respond to Rendezvous - create Conversation
    //Client 1 Receive incoming conversation
    //Client 1 subscribe to conversation with Push
    //Client 2 Send a message on conversation
    //Client 1 Gets push notification
    
    
    
}


-(void)requestNotificationToken{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge;
    
    
    [center requestAuthorizationWithOptions:options
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              if (!granted) {
                                  NSLog(@"Something went wrong");
                              }else{
                                  [[UIApplication sharedApplication] registerForRemoteNotifications];
                              }
                              
                          }];
    
    

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.categoryIdentifier = @"christest";
    
    
    
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:10 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Test local Message" content:content trigger:trigger];
    
    
    
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"Notification creation Error");
            }else{
                NSLog(@"Notification creation Done");
                
            }
            
        });
    }];
}


-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSString  *token_string = [[[[deviceToken description]    stringByReplacingOccurrencesOfString:@"<"withString:@""]
                                stringByReplacingOccurrencesOfString:@">" withString:@""]
                               stringByReplacingOccurrencesOfString: @" " withString: @""];
    NSLog(@"DeviceID:%@", token_string);
}



@end
