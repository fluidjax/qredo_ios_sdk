/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoRendezvousTests.h"
#import "QredoTestUtils.h"
#import "QredoRendezvousEd25519Helper.h"
#import "QredoClient.h"

#import <objc/runtime.h>

static NSString *const kRendezvousTestConversationType = @"test.chat";
static long long kRendezvousTestMaxResponseCount = 3;
static long long kRendezvousTestDurationSeconds = 600;

@interface RendezvousListener : NSObject <QredoRendezvousDelegate>

@property XCTestExpectation *expectation;

@end

@implementation RendezvousListener

- (void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    NSLog(@"Rendezvous listener (%p) notified via qredoRendezvous:didReceiveReponse:  Rendezvous (hashed) Tag: %@. Conversation details: Type:%@, ID:%@, HWM:%@", self, rendezvous.tag, conversation.metadata.type, conversation.metadata.conversationId, conversation.highWatermark);
    if (!self.expectation) {
        NSLog(@"No expectation configured.");
    }
    NSLog(@"Rendezvous listener (%p) fulfilling expectation (%p)", self, self.expectation);
    [self.expectation fulfill];
}

@end


void swizleMethodsForSelectorsInClass(SEL originalSelector, SEL swizzledSelector, Class class) {
    
    // When swizzling an instance method, use the following:
    //Class class = [self class];
    
    // When swizzling a class method, use the following:
    // Class class = object_getClass((id)self);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}


@interface QredoRendezvousEd25519CreateHelper (QredoRendezvousTests)
+ (void)swizleSigningMethod;
@end

@implementation QredoRendezvousEd25519CreateHelper (QredoRendezvousTests)

- (QredoRendezvousAuthSignature *)QredoRendezvousTests_signatureWithData:(NSData *)data error:(NSError **)error {
    
    QredoRendezvousAuthSignature *signature = [self QredoRendezvousTests_signatureWithData:data error:error];
    
    __block NSData *signatureData = nil;
    [signature
     ifX509_PEM:^(NSData *signature) {
         NSAssert(FALSE, @"Wrong signature type");
     } X509_PEM_SELFISGNED:^(NSData *signature) {
         NSAssert(FALSE, @"Wrong signature type");
     } ED25519:^(NSData *signature) {
         signatureData = signature;
     } RSA2048_PEM:^(NSData *signature) {
         NSAssert(FALSE, @"Wrong signature type");
     } RSA4096_PEM:^(NSData *signature) {
         NSAssert(FALSE, @"Wrong signature type");
     } other:^{
         NSAssert(FALSE, @"Wrong signature type");
     }];
    
    NSMutableData *forgedSignatureData = [signatureData mutableCopy];
    unsigned char *forgedSignatureDataBytes = [forgedSignatureData mutableBytes];
    forgedSignatureDataBytes[0] = ~forgedSignatureDataBytes[0];
    
    QredoRendezvousAuthSignature *forgedSignature = [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:forgedSignatureData];

    return forgedSignature;
    
}

+ (void)swizleSigningMethod {
    Class class = self;
    SEL origSEL = @selector(signatureWithData:error:);
    SEL newSEL = @selector(QredoRendezvousTests_signatureWithData:error:);
    swizleMethodsForSelectorsInClass(origSEL, newSEL, class);
}

@end


@interface QredoRendezvousTests ()
{
    QredoClient *client;
}

@end

@implementation QredoRendezvousTests

- (void)setUp {
    [super setUp];
    [self authoriseClient];
}

-(void)tearDown {
    [super tearDown];
    if (client) {
        [client closeSession];
    }
}

- (void)authoriseClient
{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[[QredoClientOptions alloc] initWithMQTT:self.useMQTT resetData:YES]
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

- (void)verifyRendezvous:(QredoRendezvous *)rendezvous randomTag:(NSString *)randomTag {
    
    NSLog(@"Verifying rendezvous");
    
    XCTAssert([rendezvous.configuration.conversationType isEqualToString:kRendezvousTestConversationType]);
    XCTAssertEqual(rendezvous.configuration.durationSeconds.longLongValue, kRendezvousTestDurationSeconds);
    XCTAssertEqual(rendezvous.configuration.maxResponseCount.longLongValue, kRendezvousTestMaxResponseCount);

    __block QredoClient *anotherClient = nil;

    NSLog(@"Creating 2nd client");
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[[QredoClientOptions alloc] initWithMQTT:self.useMQTT resetData:YES]
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
    
    // Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    NSLog(@"Created rendezvous listener (%p)", self);
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    NSLog(@"Listener expectation created: %@", listener.expectation);
    rendezvous.delegate = listener;
    [rendezvous startListening];

    // Give time for the subscribe/getResponses process to complete before we respond. Avoid any previous responses being included in the respondExpectation
    [NSThread sleepForTimeInterval:2];
    
    NSLog(@"Responding to Rendezvous");
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:randomTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        [respondExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [rendezvous stopListening];
    
    // Nil the listener expectation afterwards because have seen times when a different call to this method for the same Rendezvous has triggered fulfill twice, which throws an exception.  Wasn't a duplicate response, as it had a different ResponderPublicKey.
    listener.expectation = nil;
    
    // Making sure that we can enumerate responses
    NSLog(@"Enumerating conversations");
    __block BOOL found = false;
    __block XCTestExpectation *didEnumerateExpectation = [self expectationWithDescription:@"verify: enumerate conversation from loaded rendezvous"];
    [rendezvous enumerateConversationsWithBlock:^(QredoConversation *conversation, BOOL *stop) {
        XCTAssertNotNil(conversation);
        *stop = YES;
        found = YES;
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [didEnumerateExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        didEnumerateExpectation = nil;
    }];
    XCTAssertTrue(found);
    
    [anotherClient closeSession];
    
    // Remove the listener, to avoid any possibilty of the listener being held/called after exiting
    rendezvous.delegate = nil;
}

// TODO: DH - ensure that all tests (including in other files) are renamed to match new name of createXXXRendezvous

// TODO: DH - review this test - make to be an authenticated rendezvous
//- (void)testCreateAnonymousRendezvous_NoSigningHandler {
//    NSString *randomTag = [[QredoQUID QUID] QUIDString];
//
//    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:kRendezvousTestConversationType
//                                                                                                 durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
//                                                                                                maxResponseCount:[NSNumber numberWithLongLong:kRendezvousTestMaxResponseCount]];
//
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//
//    NSLog(@"Creating rendezvous");
//    [client createAnonymousRendezvousWithTag:randomTag
//                               configuration:configuration
//                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                               XCTAssertNil(error);
//                               XCTAssertNotNil(rendezvous);
//                               [createExpectation fulfill];
//                           }];
//    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//
//    __block XCTestExpectation *failCreateExpectation = [self expectationWithDescription:@"create rendezvous with the same tag"];
//
//    NSLog(@"Creating duplicate rendezvous");
//    [client createAnonymousRendezvousWithTag:randomTag
//                               configuration:configuration
//                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                               XCTAssertNotNil(error);
//                               XCTAssertNil(rendezvous);
//                               
//                               XCTAssertEqual(error.code, QredoErrorCodeRendezvousAlreadyExists);
//                               
//                               [failCreateExpectation fulfill];
//                           }];
//    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
//        failCreateExpectation = nil;
//    }];
//
//
//    // Enumerating stored rendezvous
//    __block XCTestExpectation *didFindStoredRendezvousMetadataExpecttion = [self expectationWithDescription:@"find stored rendezvous metadata"];
//    __block QredoRendezvousMetadata *rendezvousMetadataFromEnumeration = nil;
//
//    __block int count = 0;
//    NSLog(@"Enumerating rendezvous");
//    [client enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
//        if ([rendezvousMetadata.tag isEqualToString:randomTag]) {
//            rendezvousMetadataFromEnumeration = rendezvousMetadata;
//            count++;
//        }
//    } completionHandler:^(NSError *error) {
//        XCTAssertNil(error);
//        XCTAssertEqual(count, 1);
//        [didFindStoredRendezvousMetadataExpecttion fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
//        didFindStoredRendezvousMetadataExpecttion = nil;
//    }];
//
//    XCTAssertNotNil(rendezvousMetadataFromEnumeration);
//
//    // Fetching the full rendezvous object
//    __block XCTestExpectation *didFindStoredRendezvous = [self expectationWithDescription:@"find stored rendezvous"];
//    __block QredoRendezvous *rendezvousFromEnumeration = nil;
//
//    NSLog(@"Fetching rendezvous with metadata from enumeration");
//    [client fetchRendezvousWithMetadata:rendezvousMetadataFromEnumeration completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//        XCTAssertNil(error);
//        XCTAssertNotNil(rendezvous);
//        rendezvousFromEnumeration = rendezvous;
//        [didFindStoredRendezvous fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
//        didFindStoredRendezvous = nil;
//    }];
//
//
//    XCTAssertNotNil(rendezvousFromEnumeration);
//
//    NSLog(@"Verifying rendezvous from enumeration");
//    [self verifyRendezvous:rendezvousFromEnumeration randomTag:randomTag];
//
//    
//    NSLog(@"Fetching rendezvous with tag");
//    // Trying to load the rendezvous by tag, without enumeration
//    __block XCTestExpectation *didFetchExpectation = [self expectationWithDescription:@"fetch rendezvous from vault by tag"];
//    __block QredoRendezvous *rendezvousFromFetch = nil;
//    [client fetchRendezvousWithTag:randomTag completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//        XCTAssertNotNil(rendezvous);
//        XCTAssertNil(error);
//
//        rendezvousFromFetch = rendezvous;
//        [didFetchExpectation fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
//        didFetchExpectation = nil;
//    }];
//
//
//    XCTAssertNotNil(rendezvousFromFetch);
//    
//    NSLog(@"Verifying rendezvous from fetch");
//    [self verifyRendezvous:rendezvousFromFetch randomTag:randomTag];
//}

// TODO: DH - this will be renamed to one of the authenticated rendezvous option?
//- (void)testCreateRendezvous_NilSigningHandler {
//    NSString *randomTag = [[QredoQUID QUID] QUIDString];
//    
//    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:kRendezvousTestConversationType
//                                                                                                 durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
//                                                                                                maxResponseCount:[NSNumber numberWithLongLong:kRendezvousTestMaxResponseCount]];
//    
//    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
//    
//    NSLog(@"Creating rendezvous");
//    [client createRendezvousWithTag:randomTag
//                      configuration:configuration
//                     signingHandler:nil
//                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                      XCTAssertNil(error);
//                      XCTAssertNotNil(rendezvous);
//                      [createExpectation fulfill];
//                  }];
//    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
//        createExpectation = nil;
//    }];
//    
//    __block XCTestExpectation *failCreateExpectation = [self expectationWithDescription:@"create rendezvous with the same tag"];
//    
//    NSLog(@"Creating duplicate rendezvous");
//    [client createRendezvousWithTag:randomTag
//                      configuration:configuration
//                     signingHandler:nil
//                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//                      XCTAssertNotNil(error);
//                      XCTAssertNil(rendezvous);
//                      
//                      XCTAssertEqual(error.code, QredoErrorCodeRendezvousAlreadyExists);
//                      
//                      [failCreateExpectation fulfill];
//                  }];
//    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
//        failCreateExpectation = nil;
//    }];
//    
//    
//    // Enumerating stored rendezvous
//    __block XCTestExpectation *didFindStoredRendezvousMetadataExpecttion = [self expectationWithDescription:@"find stored rendezvous metadata"];
//    __block QredoRendezvousMetadata *rendezvousMetadataFromEnumeration = nil;
//    
//    __block int count = 0;
//    NSLog(@"Enumerating rendezvous");
//    [client enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
//        if ([rendezvousMetadata.tag isEqualToString:randomTag]) {
//            rendezvousMetadataFromEnumeration = rendezvousMetadata;
//            count++;
//        }
//    } completionHandler:^(NSError *error) {
//        XCTAssertNil(error);
//        XCTAssertEqual(count, 1);
//        [didFindStoredRendezvousMetadataExpecttion fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
//        didFindStoredRendezvousMetadataExpecttion = nil;
//    }];
//    
//    XCTAssertNotNil(rendezvousMetadataFromEnumeration);
//    
//    // Fetching the full rendezvous object
//    __block XCTestExpectation *didFindStoredRendezvous = [self expectationWithDescription:@"find stored rendezvous"];
//    __block QredoRendezvous *rendezvousFromEnumeration = nil;
//    
//    NSLog(@"Fetching rendezvous with metadata from enumeration");
//    [client fetchRendezvousWithMetadata:rendezvousMetadataFromEnumeration completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//        XCTAssertNil(error);
//        XCTAssertNotNil(rendezvous);
//        rendezvousFromEnumeration = rendezvous;
//        [didFindStoredRendezvous fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
//        didFindStoredRendezvous = nil;
//    }];
//    
//    
//    XCTAssertNotNil(rendezvousFromEnumeration);
//    
//    NSLog(@"Verifying rendezvous from enumeration");
//    [self verifyRendezvous:rendezvousFromEnumeration randomTag:randomTag];
//    
//    
//    NSLog(@"Fetching rendezvous with tag");
//    // Trying to load the rendezvous by tag, without enumeration
//    __block XCTestExpectation *didFetchExpectation = [self expectationWithDescription:@"fetch rendezvous from vault by tag"];
//    __block QredoRendezvous *rendezvousFromFetch = nil;
//    [client fetchRendezvousWithTag:randomTag completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
//        XCTAssertNotNil(rendezvous);
//        XCTAssertNil(error);
//        
//        rendezvousFromFetch = rendezvous;
//        [didFetchExpectation fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
//        didFetchExpectation = nil;
//    }];
//    
//    
//    XCTAssertNotNil(rendezvousFromFetch);
//    
//    NSLog(@"Verifying rendezvous from fetch");
//    [self verifyRendezvous:rendezvousFromFetch randomTag:randomTag];
//}

- (void)testCreateAndRespondAnonymousRendezvous {
    NSString *randomTag = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:kRendezvousTestConversationType
                                                                                                 durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
                                                                                                maxResponseCount:[NSNumber numberWithLongLong:kRendezvousTestMaxResponseCount]];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    NSLog(@"Creating rendezvous");
    [client createAnonymousRendezvousWithTag:randomTag
                               configuration:configuration
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(rendezvous);
                               createdRendezvous = rendezvous;
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    XCTAssertNotNil(createdRendezvous);

    NSLog(@"Verifying rendezvous");
    
    __block QredoClient *anotherClient = nil;
    
    NSLog(@"Creating 2nd client");
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[[QredoClientOptions alloc] initWithMQTT:self.useMQTT resetData:NO]
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
    
    // Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    NSLog(@"Created rendezvous listener (%p)", self);

    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    NSLog(@"Listener expectation created: %@", listener.expectation);
    createdRendezvous.delegate = listener;
    [createdRendezvous startListening];
    
    NSLog(@"Responding to Rendezvous");
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:randomTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        [respondExpectation fulfill];
    }];
    
    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
    [NSThread sleepForTimeInterval:5];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [createdRendezvous stopListening];
    
    [anotherClient closeSession];

}


- (void)common_createAndRespondRendezvousForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                     prefix:(NSString *)prefix
{
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       authenticationType:authenticationType
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       maxResponseCount:[NSNumber numberWithLongLong:kRendezvousTestMaxResponseCount]
       transCap:nil];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    NSLog(@"Creating rendezvous");
    [client createAuthenticatedRendezvousWithPrefix:prefix
                                 authenticationType:configuration.authenticationType
                                      configuration:configuration
                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                      
                                      XCTAssertNil(error);
                                      XCTAssertNotNil(rendezvous);
                                      createdRendezvous = rendezvous;
                                      [createExpectation fulfill];
                                  }];
    
    // Takes approx 10 seconds to generate RSA 4096 keypair, so ensure timeout is sufficient for all cases
    [self waitForExpectationsWithTimeout:15.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    XCTAssertNotNil(createdRendezvous);
    
    NSString *fullTag = createdRendezvous.tag;
    
    NSLog(@"Verifying rendezvous");
    
    __block QredoClient *anotherClient = nil;
    
    NSLog(@"Creating 2nd client");
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[[QredoClientOptions alloc] initWithMQTT:self.useMQTT
                                                                               resetData:NO]
                              completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  
                                  XCTAssertNil(error);
                                  XCTAssertNotNil(clientArg);
                                  anotherClient = clientArg;
                                  [clientExpectation fulfill];
                                  
                              }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
    // Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    NSLog(@"Created rendezvous listener (%p)", self);
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    NSLog(@"Listener expectation created: %@", listener.expectation);
    createdRendezvous.delegate = listener;
    [createdRendezvous startListening];
    
    NSLog(@"Responding to Rendezvous");
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:fullTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssertNil(error);
        [respondExpectation fulfill];
    }];
    
    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates
    // which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
    [NSThread sleepForTimeInterval:5];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [createdRendezvous stopListening];
    
    [anotherClient closeSession];
}

// TODO: DH - do other authenticated rendezvous types
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    
    [self common_createAndRespondRendezvousForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                                       prefix:randomPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix {
    
    NSString *emptyPrefix = @"";
    
    [self common_createAndRespondRendezvousForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                                       prefix:emptyPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    
    [self common_createAndRespondRendezvousForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
                                                                       prefix:randomPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix {
    
    NSString *emptyPrefix = @"";
    
    [self common_createAndRespondRendezvousForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
                                                                       prefix:emptyPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    
    [self common_createAndRespondRendezvousForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                                       prefix:randomPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix {
    
    NSString *emptyPrefix = @"";
    
    [self common_createAndRespondRendezvousForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                                       prefix:emptyPrefix];
}

- (void)testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix
{
    NSString *nilPrefix = nil; // Invalid, nil prefix
    NSString *expectedGeneratedPrefix = @""; // Nil prefix becomes empty prefix
    
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       authenticationType:QredoRendezvousAuthenticationTypeEd25519
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       maxResponseCount:[NSNumber numberWithLongLong:kRendezvousTestMaxResponseCount]
       transCap:nil];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    NSLog(@"Creating rendezvous");
    [client createAuthenticatedRendezvousWithPrefix:nilPrefix
                                 authenticationType:configuration.authenticationType
                                      configuration:configuration
                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                      
                                      XCTAssertNil(error);
                                      XCTAssertNotNil(rendezvous);
                                      createdRendezvous = rendezvous;
                                      [createExpectation fulfill];
                                  }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    
    XCTAssertNotNil(createdRendezvous);
    
    NSString *fullTag = createdRendezvous.tag;
    
    NSArray *splitTagParts = [[fullTag copy] componentsSeparatedByString:@"@"];
    XCTAssertNotNil(splitTagParts);
    NSUInteger separatorCount = splitTagParts.count - 1;
    XCTAssertTrue(separatorCount == 1);
    XCTAssertTrue([splitTagParts[0] isEqualToString:expectedGeneratedPrefix]);
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature
{
    NSString *randomPrefix = [[QredoQUID QUID] QUIDString];
    
    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc]
       initWithConversationType:kRendezvousTestConversationType
       authenticationType:QredoRendezvousAuthenticationTypeEd25519
       durationSeconds:[NSNumber numberWithLongLong:kRendezvousTestDurationSeconds]
       maxResponseCount:[NSNumber numberWithLongLong:kRendezvousTestMaxResponseCount]
       transCap:nil];
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [QredoRendezvousEd25519CreateHelper swizleSigningMethod];
    
    NSLog(@"Creating rendezvous");
    [client createAuthenticatedRendezvousWithPrefix:randomPrefix
                                 authenticationType:configuration.authenticationType
                                      configuration:configuration
                                  completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                      
                                      XCTAssertNil(error);
                                      XCTAssertNotNil(rendezvous);
                                      createdRendezvous = rendezvous;
                                      [createExpectation fulfill];
                                  }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        createExpectation = nil;
    }];
    [QredoRendezvousEd25519CreateHelper swizleSigningMethod];
    
    XCTAssertNotNil(createdRendezvous);
    
    NSString *fullTag = createdRendezvous.tag;
    
    NSLog(@"Verifying rendezvous");
    
    __block QredoClient *anotherClient = nil;
    
    NSLog(@"Creating 2nd client");
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"verify: create client"];
    [QredoClient authorizeWithConversationTypes:nil
                                 vaultDataTypes:@[@"blob"]
                                        options:[[QredoClientOptions alloc] initWithMQTT:self.useMQTT
                                                                               resetData:NO]
                              completionHandler:^(QredoClient *clientArg, NSError *error) {
                                  
                                  XCTAssertNil(error);
                                  XCTAssertNotNil(clientArg);
                                  anotherClient = clientArg;
                                  [clientExpectation fulfill];
                                  
                              }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
    // Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    NSLog(@"Created rendezvous listener (%p)", self);
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    NSLog(@"Listener expectation created: %@", listener.expectation);
    createdRendezvous.delegate = listener;
    [createdRendezvous startListening];
    
    NSLog(@"Responding to Rendezvous");
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:fullTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        XCTAssert(error);
        [respondExpectation fulfill];
    }];
    
    // Give time for the subscribe/getResponses process to process - they could internally produce duplicates
    // which we need to ensure don't surface to listener.  This needs to be done before waiting for expectations.
    [NSThread sleepForTimeInterval:5];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        respondExpectation = nil;
        listener.expectation = nil;
    }];
    
    [createdRendezvous stopListening];
    
    [anotherClient closeSession];
    
}

@end
