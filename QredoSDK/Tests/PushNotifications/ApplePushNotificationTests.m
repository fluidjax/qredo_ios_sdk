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
#import "MasterConfig.h"

@import UserNotifications;


@interface ApplePushNotificationTests : QredoXCTestCase
@property (atomic) XCTestExpectation *didReceiveResponseExpectation;
@property (atomic) XCTestExpectation *didReceiveMessageExpectation;
@property (atomic) XCTestExpectation *didRecieveOtherPartyHasLeft;
@property (atomic) XCTestExpectation *didReceiveRendezvousExpectation;
@end



@interface ApplePushTestConversationListener :NSObject <QredoConversationObserver>
@property ApplePushNotificationTests *test;
@property NSString *expectedMessageValue;
@property BOOL failed;
@property BOOL listening;
@property NSNumber *fulfilledtime;
@end


@implementation ApplePushTestConversationListener

-(void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message {
    [_test.didReceiveResponseExpectation fulfill];
}

@end




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
}

- (void)tearDown {
    [super tearDown];
}


-(void)testPushServiceExtensionin{
    [self appDelegateRequestAPNToken];
    [self setupPushStack];
    NSString* smallTestMessage = @"This is a test (encrypted) message for Push Tests";
    
    NSLog(@"CLOSE THE APP");
    [self pause:5];
    NSLog(@"Continuing");    
    
    [self sendMessageAndWaitForPushNotificationWithMessage:smallTestMessage];
    
    XCTAssert(hostAppdelegate.qredoPushMessage.messageType == QREDO_PUSH_CONVERSATION_MESSAGE,@"Message Type should be 1 = conversation:");
    XCTAssert([hostAppdelegate.qredoPushMessage.sequenceValue isEqualToNumber:@1],@"Sequence Value should be 1 - this is first message in a new conversation");
    XCTAssert([hostAppdelegate.qredoPushMessage.incomingMessageText isEqualToString:smallTestMessage],@"Message should be the smallTestMessage string");
    XCTAssertNotNil(hostAppdelegate.qredoPushMessage.conversation,@"Conversation should not be nil");
    XCTAssertNotNil(hostAppdelegate.qredoPushMessage.conversationRef,@"ConversationRef should be looked up from incoming QueueID");
}



-(void)configureClientOptions{
    QredoClientOptions *options = [[QredoClientOptions alloc] initDefault]; //this is actually init Test because its is swizzled in testing
    options.pushToken       = apnToken;
    self.clientOptions = options;
    NSLog(@"OPTIONS %@", self.clientOptions);
}



-(void)testLargePayloadPush{
    [self appDelegateRequestAPNToken];
    [self configureClientOptions];
    [self setupPushStack];
    
  
    NSString *largeTestString = [NSString stringWithFormat:@"This is a large test string for Push messages %@",[self randomStringWithLength:10000]];
    [self sendMessageAndWaitForPushNotificationWithMessage:largeTestString];
    
    XCTAssert(hostAppdelegate.qredoPushMessage.messageType == QREDO_PUSH_CONVERSATION_MESSAGE,@"Message Type should be 1 = conversation:");
    XCTAssert([hostAppdelegate.qredoPushMessage.sequenceValue isEqualToNumber:@1],@"Sequence Value should be 1 - this is first message in a new conversation");
    XCTAssertNil(hostAppdelegate.qredoPushMessage.conversationMessage,@"Message should be nil - its too big for a push notification");
    XCTAssertNotNil(hostAppdelegate.qredoPushMessage.conversation,@"Conversation should not be nil");
    XCTAssertNotNil(hostAppdelegate.qredoPushMessage.conversationRef,@"ConversationRef should be looked up from incoming QueueID");
}


-(void)testSmallPayloadPush{
    [self appDelegateRequestAPNToken];
    [self setupPushStack];
    NSString* smallTestMessage = @"This is a test (encrypted) message for Push Tests";
    [self sendMessageAndWaitForPushNotificationWithMessage:smallTestMessage];
    
    XCTAssert(hostAppdelegate.qredoPushMessage.messageType == QREDO_PUSH_CONVERSATION_MESSAGE,@"Message Type should be 1 = conversation:");
    XCTAssert([hostAppdelegate.qredoPushMessage.sequenceValue isEqualToNumber:@1],@"Sequence Value should be 1 - this is first message in a new conversation");
    XCTAssert([hostAppdelegate.qredoPushMessage.incomingMessageText isEqualToString:smallTestMessage],@"Message should be the smallTestMessage string");
    XCTAssertNotNil(hostAppdelegate.qredoPushMessage.conversation,@"Conversation should not be nil");
    XCTAssertNotNil(hostAppdelegate.qredoPushMessage.conversationRef,@"ConversationRef should be looked up from incoming QueueID");
}


-(void)testSmallPayloadPushNoClient{
    [self appDelegateRequestAPNToken];
    [self setupPushStack];
    hostAppdelegate.client = nil; //remove client reference
    NSString* smallTestMessage = @"This is a test (encrypted) message for Push Tests";
    [self sendMessageAndWaitForPushNotificationWithMessage:smallTestMessage];

    XCTAssertNotNil(hostAppdelegate.qredoPushMessage.alert,@"Should have an alert from the APN");
    XCTAssert(hostAppdelegate.qredoPushMessage.messageType == QREDO_PUSH_CONVERSATION_MESSAGE,@"Message Type should be 1 = conversation:");
    XCTAssertNotNil(hostAppdelegate.qredoPushMessage.queueId,@"Queue should not be nil");
    XCTAssertNil(hostAppdelegate.qredoPushMessage.conversation,@"Conversation should be nil");
    XCTAssertNil(hostAppdelegate.qredoPushMessage.incomingMessageText,@"Shouldn't be able to decode message text as its encrypted, and no client");
    XCTAssertNotNil(hostAppdelegate.qredoPushMessage.conversationRef,@"ConversationRef should be looked up from incoming QueueID");
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
    
}



-(void)pause:(int)delay{
    XCTestExpectation *expectation = [self expectationWithDescription:@"High Expectations"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:delay+1 handler:^(NSError * _Nullable error) {
        //
    }];
    expectation=nil;
    
    
}

-(void)setupPushStack{
  
    [self buildFixedCredentialStack1];
    //inject the QredoClient into the TestApp
    hostAppdelegate.client = testClient1;
    XCTAssertNotNil(conversation1);
    XCTAssertNotNil(conversation2);
}


-(void)sendMessageAndWaitForPushNotificationWithMessage:(NSString*)message{
    ApplePushTestConversationListener *listener = [[ApplePushTestConversationListener alloc] init];
    listener.expectedMessageValue = message;
    listener.test = self;
    [conversation1 addConversationObserver:listener withPushNotifications:apnToken];

    
    
    //send a message on conversation2
    QredoConversationMessage *messageFrom2to1 = [[QredoConversationMessage alloc] initWithValue:[message dataUsingEncoding:NSUTF8StringEncoding] summaryValues:nil];
    
    [conversation2 publishMessage:messageFrom2to1
                completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                    XCTAssertNil(error);
                }];
    
    self.didReceiveResponseExpectation = [self expectationWithDescription:@"published a message after listener started"];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        self.didReceiveResponseExpectation=nil;
    }];
    
    self.didReceiveResponseExpectation=nil;
    
    
    
    NSLog(@"Waiting");
    [self pause:20];
        NSLog(@"end Waiting");
    if (hostAppdelegate.testsPassed==NO){
        XCTFail(@"Push Tests failed in App Delegate");
    }
}


//-(void)requestNotificationToken{
//    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
//    UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge;
//
//    [center requestAuthorizationWithOptions:options
//                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
//                              if (!granted) {
//                                  NSLog(@"Something went wrong");
//                              }else{
//                                  [[UIApplication sharedApplication] registerForRemoteNotifications];
//                              }
//                              
//                          }];
//
//    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
//    content.categoryIdentifier = @"christest";
//    
//    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:10 repeats:NO];
//    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Test local Message" content:content trigger:trigger];
//    
//    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (error) {
//                NSLog(@"Notification creation Error");
//            }else{
//                NSLog(@"Notification creation Done");
//                
//            }
//            
//        });
//    }];
//}
//
//
//-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
//    NSString  *token_string = [[[[deviceToken description]    stringByReplacingOccurrencesOfString:@"<"withString:@""]
//                                stringByReplacingOccurrencesOfString:@">" withString:@""]
//                               stringByReplacingOccurrencesOfString: @" " withString: @""];
//    NSLog(@"DeviceID:%@", token_string);
//}



@end
