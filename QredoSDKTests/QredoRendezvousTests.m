/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoTestConfiguration.h"

static NSString *const kRendezvousTestConversationType = @"test.chat";
static long long kRendezvousTestMaxResponseCount = 3;
static long long kRendezvousTestDurationSeconds = 600;

@interface RendezvousListener : NSObject <QredoRendezvousDelegate>

@property XCTestExpectation *expectation;

@end

@implementation RendezvousListener

- (void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    [self.expectation fulfill];
}

@end

@interface QredoRendezvousTests : XCTestCase
{
    NSURL *serviceURL;
    QredoClient *client;
}

@end

@implementation QredoRendezvousTests

- (void)setUp {
    [super setUp];
    serviceURL = [NSURL URLWithString:QREDO_SERVICE_URL];

    client = [[QredoClient alloc] initWithServiceURL:serviceURL];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)verifyRendezvous:(QredoRendezvous *)rendezvous randomTag:(NSString *)randomTag {
    XCTAssert([rendezvous.configuration.conversationType isEqualToString:kRendezvousTestConversationType]);
    XCTAssertEqual(rendezvous.configuration.durationSeconds.longLongValue, kRendezvousTestDurationSeconds);
    XCTAssertEqual(rendezvous.configuration.maxResponseCount.longLongValue, kRendezvousTestMaxResponseCount);


    // Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    listener.expectation = [self expectationWithDescription:@"receive listener event for the loaded rendezvous"];
    rendezvous.delegate = listener;
    [rendezvous startListening];
    
    QredoClient *anotherClient = [[QredoClient alloc] initWithServiceURL:serviceURL];
    [anotherClient respondWithTag:randomTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    [rendezvous stopListening];
    
    // Making sure that we can enumerate responses
    XCTestExpectation *didEnumerateExpectation = [self expectationWithDescription:@"enumerate conversation from loaded rendezvous"];
    [rendezvous enumerateConversationsWithBlock:^(QredoConversation *conversation, BOOL *stop) {
        XCTAssertNotNil(conversation);
        [didEnumerateExpectation fulfill];
        *stop = YES;
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testCreateRendezvous {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:kRendezvousTestConversationType
                                                                                                 durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
                                                                                                maxResponseCount:[NSNumber numberWithLongLong:kRendezvousTestMaxResponseCount]];

    XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];

    [client createRendezvousWithTag:randomTag
                      configuration:configuration
                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                      XCTAssertNil(error);
                      XCTAssertNotNil(rendezvous);
                      [createExpectation fulfill];
                  }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTestExpectation *failCreateExpectation = [self expectationWithDescription:@"create rendezvous with the same tag"];

    [client createRendezvousWithTag:randomTag
                      configuration:configuration
                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                      XCTAssertNotNil(error);
                      XCTAssertNil(rendezvous);

                      XCTAssertEqual(error.code, QredoErrorCodeRendezvousAlreadyExists);

                      [failCreateExpectation fulfill];
                  }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    // Enumerating stored rendezvous
    XCTestExpectation *didFindStoredRendezvousMetadata = [self expectationWithDescription:@"find stored rendezvous metadata"];
    __block QredoRendezvousMetadata *rendezvousMetadataFromEnumeration = nil;

    __block count = 0;
    [client enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
        if ([rendezvousMetadata.tag isEqualToString:randomTag]) {
            rendezvousMetadataFromEnumeration = rendezvousMetadata;
            count++;
        }
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(count, 1);
        [didFindStoredRendezvousMetadata fulfill];
    }];

    [self waitForExpectationsWithTimeout:200.0 handler:nil];

    XCTAssertNotNil(rendezvousMetadataFromEnumeration);
    XCTAssertNotNil(didFindStoredRendezvousMetadata);


    // Fetching the full rendezvous object
    XCTestExpectation *didFindStoredRendezvous = [self expectationWithDescription:@"find stored rendezvous"];
    __block QredoRendezvous *rendezvousFromEnumeration = nil;

    [client fetchRendezvousWithMetadata:rendezvousMetadataFromEnumeration completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(rendezvous);
        rendezvousFromEnumeration = rendezvous;
        [didFindStoredRendezvous fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTAssertNotNil(rendezvousFromEnumeration);

    [self verifyRendezvous:rendezvousFromEnumeration randomTag:randomTag];

    // Trying to load the rendezvous by tag, without enumeration
    XCTestExpectation *didFetchExpectation = [self expectationWithDescription:@"fetch rendezvous from vault by tag"];
    __block QredoRendezvous *rendezvousFromFetch = nil;
    [client fetchRendezvousWithTag:randomTag completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        XCTAssertNotNil(rendezvous);
        XCTAssertNil(error);

        rendezvousFromFetch = rendezvous;
        [didFetchExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTAssertNotNil(rendezvousFromFetch);
    
    [self verifyRendezvous:rendezvousFromFetch randomTag:randomTag];
}


@end
