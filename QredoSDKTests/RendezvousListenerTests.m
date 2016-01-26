/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoTestConfiguration.h"
#import "QredoTestUtils.h"
#import "QredoQUID.h"

// The purpose of this test is to cover all edge cases in the rendezvous listener:
// - receiving response
// - reaching maximum number of responders
// - timeout
// - starting/stopping listening
// - resetHighwatermark
// - persisting highwatermark
// - releasing references after stopListening

// It may also cover responder's edge cases:
// - responding to non-existing tag

@interface RendezvousListenerTests : QredoXCTestCase <QredoRendezvousObserver>
{
    QredoClient *client;
    XCTestExpectation *didReceiveResponseExpectation;

    QredoConversation *creatorConversation;
}

@property (nonatomic) QredoClientOptionsTransportType transportType;

@end

@implementation RendezvousListenerTests

- (void)setUp {
    [super setUp];

    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];

    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:[QredoTestUtils randomPassword]
                                 options:[QredoClientOptions qtu_clientOptionsWithTransportType:self.transportType resetData:YES]
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  XCTAssertNil(error);
                                  XCTAssertNotNil(clientArg);
                                  client = clientArg;
                                  [clientExpectation fulfill];
                              }];

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
}

-(void)tearDown {
    [super tearDown];
    if (client) {
        [client closeSession];
    }
}

- (void)testRendezvousResponder {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"test.chat" durationSeconds:@600 isUnlimitedResponseCount:NO];

    __block QredoRendezvous *rendezvous = nil;

    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];

    [client createAnonymousRendezvousWithTag:randomTag
                      configuration:configuration
                  completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                      XCTAssertNil(error);
                      XCTAssertNotNil(_rendezvous);

                      rendezvous = _rendezvous;

                      [createExpectation fulfill];
                  }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        createExpectation = nil;
    }];



    // Responding to the rendezvous


    __block QredoClient *anotherClient = nil;

    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];


    [QredoClient initializeWithAppSecret:k_APPSECRET
                                  userId:k_USERID
                              userSecret:[QredoTestUtils randomPassword]
                                       options:[QredoClientOptions qtu_clientOptionsWithTransportType:self.transportType resetData:YES]
                             completionHandler:^(QredoClient *clientArg, NSError *error) {
                                 XCTAssertNil(error);
                                 XCTAssertNotNil(clientArg);
                                 anotherClient = clientArg;
                                 [clientExpectation fulfill];
                             }];
    
                           
                           
                           

    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];


    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];

    [rendezvous addRendezvousObserver:self];
    
    __block QredoConversation *responderConversation = nil;
    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    [anotherClient respondWithTag:randomTag
                  trustedRootPems:nil
                          crlPems:nil
                completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(conversation);

        responderConversation = conversation;

        [didRespondExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        didRespondExpectation = nil;
        didReceiveResponseExpectation = nil;
    }];

    // Sending message
    XCTAssertNotNil(responderConversation);
    
    [rendezvous removeRendezvousObserver:self];
    
    [anotherClient closeSession];
}

- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    creatorConversation = conversation;
    [didReceiveResponseExpectation fulfill];
}


@end
