//
//  MultiPageMessageTest.m
//  QredoSDK
//
//  Created by Christopher Morris on 20/11/2015.
//
//

#import <XCTest/XCTest.h>
#import "Qredo.h"

@interface MultiPageMessageTest : XCTestCase

@end

@implementation MultiPageMessageTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

-(NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}


-(void)testPaging{
    
    __block QredoClient *client1;
    __block QredoClient *client2;
    
    //create client1
    __block XCTestExpectation *client1Expectation = [self expectationWithDescription:@"Create Client 1"];
    [QredoClient initializeWithAppSecret:@"appSecret"
                                  userId:@"user1"
                              userSecret:@"password1"
                                 options:nil
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           // handle error, store client in property
                           if (error)                                  {
                               NSLog(@"Authorize failed with error: %@", error.localizedDescription);
                               return;
                           }
                           client1 = clientArg;
                           [client1Expectation fulfill];
                       }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        client1Expectation = nil;
    }];
    
    //create client2
    __block XCTestExpectation *client2Expectation = [self expectationWithDescription:@"Create Client 2"];
    [QredoClient initializeWithAppSecret:@"appSecret"
                                  userId:@"user2"
                              userSecret:@"password2"
                                 options:nil
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           // handle error, store client in property
                           if (error)                                  {
                               NSLog(@"Authorize failed with error: %@", error.localizedDescription);
                               return;
                           }
                           client2 = clientArg;
                           [client2Expectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        client2Expectation = nil;
    }];
    
    //create conversation
    
    QredoRendezvousConfiguration *rendezvousConfiguration =
    [[QredoRendezvousConfiguration alloc] initWithConversationType: @"com.qredo.epiq"
                                                   durationSeconds: 0
                                          isUnlimitedResponseCount: true ];
    
    
    __block XCTestExpectation *createRendezvous1Expectation = [self expectationWithDescription:@"Create rendezvous 1"];
    __block QredoRendezvous *testRendezvous = nil;
    NSString *tagName = [self randomStringWithLength:32];
                                           
    [client1 createAnonymousRendezvousWithTag:tagName configuration:rendezvousConfiguration completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        XCTAssertNotNil(rendezvous);
        testRendezvous = rendezvous;
        [createRendezvous1Expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        createRendezvous1Expectation = nil;
    }];

    
    //respond to rendezvous by tag
    __block QredoConversation *testConversation=nil;
    __block XCTestExpectation *respondeToConversation1 = [self expectationWithDescription:@"Respond to Conversation1"];
    [client2  respondWithTag:tagName
                  completionHandler:^(QredoConversation *conversation, NSError *error) {
                      XCTAssertNotNil(conversation);
                      testConversation = conversation;
                      [respondeToConversation1 fulfill];
                      
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
         respondeToConversation1 = nil;
    }];

    
    
    
    //static int MAXMESSAGES = 60;
    
    for (int i=0;i<4;i++){
        NSString *message = [[NSString alloc] initWithFormat:@"test message %i",i];
        NSDictionary *messageSummaryValues = @{@"data": @"data"};
        
        
        QredoConversationMessage *conversationMessage = [[QredoConversationMessage alloc] initWithValue:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                                                           dataType: @"com.qredo.plaintext"
                                                                                      summaryValues: messageSummaryValues];
    
    
        __block XCTestExpectation *postExpectation = [self expectationWithDescription:@"post message"];
        
        [testConversation publishMessage: conversationMessage completionHandler: ^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
            XCTAssertNil(error);
            XCTAssertNotNil(messageHighWatermark);
            [postExpectation fulfill];
            NSLog(@"Sent message");
        }];
        
        [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
            postExpectation = nil;
        }];
    }
    
    
    
    //retrieve messages to test paging
    __block XCTestExpectation *retrievePosts = [self expectationWithDescription:@"retrievePosts"];
    
    __block int count=0;
    
    [testConversation enumerateSentMessagesUsingBlock:^(QredoConversationMessage *message, BOOL *stop) {
        count++;
        NSString *messageText = [[NSString alloc] initWithData: message.value encoding: NSUTF8StringEncoding];
        NSLog(@"%i - %@",count, messageText);
    } since:nil completionHandler:^(NSError *error) {
        [retrievePosts fulfill];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        retrievePosts = nil;
    }];

    XCTAssertTrue(count==20,"Failure to retieve 20 messages");
    
    
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
