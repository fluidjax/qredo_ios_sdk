//
//  ApplePushNotificationTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 30/01/2017.
//
//

#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "AppDelegate.h"
#import <Foundation/Foundation.h>
#import "QredoTestUtils.h"
#import "QredoPrivate.h"
#import "ConversationTests.h"
#import "QredoLoggerPrivate.h"
#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoNetworkTime.h"
#import "QredoXCTestListeners.h"

@import UserNotifications;

static  NSString* testMessage = @"this is a test message for push";

@interface ApplePushNotificationTests : QredoXCTestCase
@property (atomic) XCTestExpectation *didReceiveResponseExpectation;
@property (atomic) XCTestExpectation *didReceiveMessageExpectation;
@property (atomic) XCTestExpectation *didRecieveOtherPartyHasLeft;
@property (atomic) XCTestExpectation *didReceiveRendezvousExpectation;


@end

//Define the listener




@interface ApplePushTestConversationListener :NSObject <QredoConversationObserver>
@property ApplePushNotificationTests *test;
@property NSString *expectedMessageValue;
@property BOOL failed;
@property BOOL listening;
@property NSNumber *fulfilledtime;
@end


@implementation ApplePushTestConversationListener


-(void)qredoConversationOtherPartyHasLeft:(QredoConversation *)conversation {
    @synchronized(_test) {
        QLog(@"qredoConversation:didReceiveNewMessage:");
        
        if (_listening){
            if (_test.didRecieveOtherPartyHasLeft){
                QLog(@"really fullfilling");
                [_test.didRecieveOtherPartyHasLeft fulfill];
                _listening = NO;
            }
        }
    }
}


-(void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message {
    [_test.didReceiveResponseExpectation fulfill];
}

@end

//Main test class




@implementation ApplePushNotificationTests
    XCTestExpectation *waitForToken;
    AppDelegate *hostAppdelegate;
    NSData *apnToken;

- (void)setUp {
    [super setUp];
    apnToken = nil;
    hostAppdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    
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





-(void)appDelegateRequestAPNToken{
    
    __block XCTestExpectation *apnTokenExpectiation = [self expectationWithDescription:@"Wait for APN Token"];
    
    
    [hostAppdelegate registerForAPNTokenWithCompletion:^(NSError *error,NSData *token) {
        NSLog(@"Token registration complete %@", token);
        apnToken = token;
        [apnTokenExpectiation fulfill];
    }];
    
    
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        apnTokenExpectiation = nil;
    }];

    
    
    
;
}


-(void)testGood{
    [self appDelegateRequestAPNToken];
    XCTAssertTrue(1==1,@"good");
}



-(void)pause:(int)delay{
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:delay+1 handler:^(NSError * _Nullable error) {
        //
    }];
    
}


-(void)testSimplePush{
    NSLog(@"Completed setup");
    
    //resgiter with APNS
    [self appDelegateRequestAPNToken];

    
    //Client 1 create Rendezvous
    //Client 2 create Respond to Rendezvous - create Conversation
    //Client 1 Receive incoming conversation
    
    [self buildStack1];
    
    //inject the QredoClient into the TestApp
    hostAppdelegate.client = testClient1;

    
    XCTAssertNotNil(conversation1);
    XCTAssertNotNil(conversation2);
    
    
    ApplePushTestConversationListener *listener = [[ApplePushTestConversationListener alloc] init];
    listener.expectedMessageValue = testMessage;
    listener.test = self;
   
    [conversation1 addConversationObserver:listener withPushNotifications:apnToken];

    
    [self pause:5];
    
    
    //send a message on conversation2
    QredoConversationMessage *messageFrom2to1 = [[QredoConversationMessage alloc] initWithValue:[testMessage dataUsingEncoding:NSUTF8StringEncoding] summaryValues:nil];
    
    [conversation2 publishMessage:messageFrom2to1
                completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                      XCTAssertNil(error);
                    
                    
                }];
    
    self.didReceiveResponseExpectation = [self expectationWithDescription:@"published a message after listener started"];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        if (error){
            NSLog(@"Error sending mesage");
        }else{
            self.didReceiveResponseExpectation=nil;
        }
    }];
    [self pause:20];
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
