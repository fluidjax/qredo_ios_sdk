/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoTestConfiguration.h"


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

@interface RendezvousListenerTests : XCTestCase <QredoRendezvousDelegate>
{
    NSURL *serviceURL;
    QredoClient *client;
    XCTestExpectation *didReceiveResponseExpectation;

    QredoConversation *creatorConversation;
}


@end

@implementation RendezvousListenerTests

- (void)setUp {
    [super setUp];
    serviceURL = [NSURL URLWithString:QREDO_HTTP_SERVICE_URL];

    client = [[QredoClient alloc] initWithServiceURL:serviceURL];
}


- (void)testRendezvousResponder {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"test.chat" durationSeconds:@600 maxResponseCount:@1];

    __block QredoRendezvous *rendezvous = nil;

    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];

    [client createRendezvousWithTag:randomTag
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
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];

    rendezvous.delegate = self;

    [rendezvous startListening];

    QredoClient *anotherClient = [[QredoClient alloc] initWithServiceURL:serviceURL];
    NSLog(@"Responding from another client");
    __block QredoConversation *responderConversation = nil;
    [anotherClient respondWithTag:randomTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        NSLog(@"Received response completion handler");
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
}

- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    creatorConversation = conversation;
    [didReceiveResponseExpectation fulfill];
}


@end
