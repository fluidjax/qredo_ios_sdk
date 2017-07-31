/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoRendezvousTests.h"
#import "QredoTestUtils.h"
#import "QredoRendezvousHelpers.h"
#import "QredoClient.h"
#import "QredoRawCrypto.h"
#import "QredoRendezvousCrypto.h"
#import "CryptoImplV1.h"
#import "QredoBase58.h"
#import "QredoLoggerPrivate.h"
#import "QredoPrivate.h"
#import "QredoNetworkTime.h"
#import "NSData+HexTools.h"

#import <objc/runtime.h>

static int kRendezvousTestDurationSeconds = 120; //2 minutes

@interface RendezvousListener :NSObject <QredoRendezvousObserver>

@property XCTestExpectation *expectation;
@property QredoConversation *incomingConversation;

@end

@implementation RendezvousListener


XCTestExpectation *timeoutExpectation;






-(void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation {
    if (self.expectation){
        self.incomingConversation = conversation;
        [self.expectation fulfill];
    }
}


@end


void swizleMethodsForSelectorsInClass(SEL originalSelector,SEL swizzledSelector,Class class) {
    //When swizzling an instance method, use the following:
    //Class class = [self class];
    
    //When swizzling a class method, use the following:
    //Class class = object_getClass((id)self);
    
    Method originalMethod = class_getInstanceMethod(class,originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class,swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod){
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod,swizzledMethod);
    }
}


@interface QredoRendezvousTests () {
}

@property (nonatomic) id<CryptoImpl> cryptoImpl;
@property (nonatomic) SecKeyRef privateKeyRef;
@property  NSString *randomlyCreatedTag;


@end

@implementation QredoRendezvousTests


-(void)setUp {
    [super setUp];
    //Want tests to abort if error occurrs
    self.continueAfterFailure = NO;
    //Trusted root refs are required for X.509 tests, and form part of the CryptoImpl
    self.cryptoImpl = [CryptoImplV1 sharedInstance];
    [self createRandomClients];
}


-(void)tearDown {
    [super tearDown];
    //Should remove any existing keys after finishing
}


-(void)testRendezvousSummaryValues {
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    NSDictionary *summaryValues = @{ @"item1":@"value1",@"item2":@"value2" };
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_MEDIUM_SECURITY
                                        duration:10000
                              unlimitedResponses:YES
                                   summaryValues:summaryValues
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNotNil(rendezvous.tag);
                                   XCTAssertNotNil(rendezvous);
                                   createdRendezvous = rendezvous;
                                   [createExpectation fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    
    
    XCTAssertNotNil(createdRendezvous,@"Didnt create rendezvous");
    
    
    NSDictionary *dict = createdRendezvous.metadata.summaryValues;
    XCTAssertTrue([[dict objectForKey:@"item2"] isEqualToString:@"value2"],@"Failed to store summary values in rendezvous");
    
    
    
    __block QredoRendezvousMetadata *retrievedMetadata = nil;
    __block XCTestExpectation *retrieveExpectation = [self expectationWithDescription:@"ret rendezvous"];
    
    
    [testClient1 enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata,BOOL *stop) {
        retrievedMetadata = rendezvousMetadata;
    }
                       completionHandler:^(NSError *error) {
                           [retrieveExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     retrieveExpectation = nil;
                                 }];
    
    
    
    NSDictionary *retDict = retrievedMetadata.summaryValues;
    XCTAssertTrue([[retDict objectForKey:@"item2"] isEqualToString:@"value2"],@"Failed to store summary values in rendezvous");
    
    
    
    //now update the summary values
    NSDictionary *modifiedDict = @{ @"modifiedKey":@"modifiedValue" };
    
    __block XCTestExpectation *modifyExpectation = [self expectationWithDescription:@"mod rendezvous"];
    [createdRendezvous updateRendezvousWithSummaryValues:modifiedDict
                                       completionHandler:^(NSError *error) {
                                           //rendezvous is updated
                                           [modifyExpectation fulfill];
                                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     retrieveExpectation = nil;
                                 }];
    
    XCTAssert([[createdRendezvous.metadata.summaryValues objectForKey:@"modifiedKey"] isEqualToString:@"modifiedValue"],@"Modify rendezvous summaryValues didnt work");
    
    
    
    //re-enumerate the vault and check the rendezvous stored
    
    __block XCTestExpectation *retrieve2Expectation = [self expectationWithDescription:@"ret rendezvous2"];
    
    __block QredoRendezvousMetadata *rendezvousMetadata2;
    
    [testClient1 enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata,BOOL *stop) {
        rendezvousMetadata2 = rendezvousMetadata;
    }
                       completionHandler:^(NSError *error) {
                           [retrieve2Expectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     retrieve2Expectation = nil;
                                 }];
    
    XCTAssert([[rendezvousMetadata2.summaryValues objectForKey:@"modifiedKey"] isEqualToString:@"modifiedValue"],@"Modify rendezvous summaryValues didnt work");
}


-(void)testReadableTags {
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_MEDIUM_SECURITY
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNotNil(rendezvous.tag);
                                   XCTAssertNotNil(rendezvous);
                                   createdRendezvous = rendezvous;
                                   [createExpectation fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    
    
    NSString *tag = createdRendezvous.tag;
    NSString *readableTag       = [QredoRendezvous tagToReadable:tag];
    NSString *readableTagDirect = createdRendezvous.readableTag;
    NSString *backToTag   = [QredoRendezvous readableToTag:readableTagDirect];
    
    XCTAssertTrue(tag.length == QREDO_MEDIUM_SECURITY * 2,@"Tag is the wrong length");
    XCTAssertTrue([readableTag isEqualToString:readableTagDirect],@"Tags should be the same");
    XCTAssertTrue([backToTag isEqualToString:tag],@"Tags should be the same");
}


-(void)testGenerateMasterKeyWithTag {
    QredoRendezvousCrypto *rendCrypto = [QredoRendezvousCrypto instance];
    
    [self measureBlock:^{
        [rendCrypto       masterKeyWithTag:@"123456789012345678901234567890"
                                     appId:@"123456789012345678901234567890"];
    }];
}


-(void)testGenerateMasterKeyWithTagAndAppId {
    QredoRendezvousCrypto *rendCrypto = [QredoRendezvousCrypto instance];
    NSString *tag   = @"ABC";
    NSString *appId = @"123";
    NSData *res = [rendCrypto masterKeyWithTag:tag appId:appId];
    NSData *testVal = [NSData dataWithHexString:@"b7dd94ba 22f5eba2 a1010144 00e65c11 0d3e69b7 098a5b88 9d44cea0 e96c944f"];
    
    XCTAssertTrue([testVal isEqualToData:res],@"Master Key derived from Tag is incorrect");
}




-(NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (int i = 0; i < len; i++){
        [randomString appendFormat:@"%C",[letters characterAtIndex:arc4random_uniform((int)[letters length])]];
    }
    
    return randomString;
}



-(void)verifyRendezvous:(QredoRendezvous *)rendezvous randomTag:(NSString *)randomTag {
    
    XCTAssertEqual(rendezvous.duration,kRendezvousTestDurationSeconds);
    testClient2 = nil;
    [self createRandomClient2];
    QredoClient *anotherClient = testClient2;
  
    
    //Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    [rendezvous addRendezvousObserver:listener];
    
    //Give time for the subscribe/getResponses process to complete before we respond. Avoid any previous responses being included in the respondExpectation
    [NSThread sleepForTimeInterval:2];
    
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    [anotherClient respondWithTag:randomTag
                completionHandler:^(QredoConversation *conversation,NSError *error) {
                    XCTAssertNil(error);
                    [respondExpectation fulfill];
                }];
    
    [self waitForExpectationsWithTimeout:20.0
                                 handler:^(NSError *error) {
                                     respondExpectation = nil;
                                     listener.expectation = nil;
                                 }];
    
    [rendezvous removeRendezvousObserver:listener];
    
    //Nil the listener expectation afterwards because have seen times when a different call to this method for the same Rendezvous has triggered fulfill twice, which throws an exception.  Wasn't a duplicate response, as it had a different ResponderPublicKey.
    listener.expectation = nil;
    
    //Making sure that we can enumerate responses
    __block BOOL found = false;
    __block XCTestExpectation *didEnumerateExpectation = [self expectationWithDescription:@"verify: enumerate conversation from loaded rendezvous"];
    [rendezvous enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        XCTAssertNotNil(conversationMetadata);
        *stop = YES;
        found = YES;
    }
                              completionHandler:^(NSError *error) {
                                  XCTAssertNil(error);
                                  [didEnumerateExpectation fulfill];
                              }];
    
    [self waitForExpectationsWithTimeout:10.0
                                 handler:^(NSError *error) {
                                     didEnumerateExpectation = nil;
                                 }];
    XCTAssertTrue(found);
    
    [anotherClient closeSession];
    
    //Remove the listener, to avoid any possibilty of the listener being held/called after exiting
    [rendezvous removeRendezvousObserver:listener];
}


-(void)testQuickCreateRandomRandezvous {
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(rendezvous.tag);
                                   XCTAssertNotNil(rendezvous);
                                   createdRendezvous = rendezvous;
                                   [createExpectation fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
}


-(void)testQuickCreateRendezvousExpiresAt {
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:100
                              unlimitedResponses:YES
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNil(error);
                                   
                                   long expires = [[rendezvous expiresAt] timeIntervalSince1970];
                                   long now     = [[QredoNetworkTime dateTime] timeIntervalSince1970];
                                   long timeUntilExpiry = expires - now;
                                   XCTAssert(timeUntilExpiry > 80 && timeUntilExpiry < 110,@"Expiry time not correctly set after creation %li",timeUntilExpiry);
                                   
                                   
                                   XCTAssertNotNil(rendezvous);
                                   createdRendezvous = rendezvous;
                                   
                                   [createExpectation fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
}


-(void)testQuickCreateRendezvousLongType {
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:kRendezvousTestDurationSeconds
                              unlimitedResponses:YES
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(rendezvous);
                                   XCTAssertTrue(rendezvous.duration == kRendezvousTestDurationSeconds,@"Duration not set");
                                   XCTAssertTrue(rendezvous.unlimitedResponses == YES,@"Unlimited Responses not set");
                                   
                                   
                                   
                                   createdRendezvous = rendezvous;
                                   [createExpectation fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
}


-(void)testQuickCreateRendezvousShortType {
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(rendezvous);
                                   createdRendezvous = rendezvous;
                                   [createExpectation fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
}


-(void)testCreateRendezvousAndGetResponses {
    self.continueAfterFailure = NO;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:kRendezvousTestDurationSeconds
                              unlimitedResponses:YES
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(rendezvous);
         createdRendezvous = rendezvous;
         [createExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    
    
    __block XCTestExpectation *enumerationExpectation = [self expectationWithDescription:@"enumerate responses"];
    
    [createdRendezvous enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
    }
                                     completionHandler:^(NSError *error) {
                                         XCTAssertNil(error);
                                         [enumerationExpectation fulfill];
                                     }];
    
    [self waitForExpectationsWithTimeout:2.0
                                 handler:^(NSError *error) {
                                     enumerationExpectation = nil;
                                 }];
}


-(void)testCreateAndFetchAnonymousRendezvous {
    __block NSString *randomTag = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    __block QredoRendezvousRef *rendezvousRef = nil;
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:kRendezvousTestDurationSeconds
                              unlimitedResponses:YES
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(rendezvous);
                                   
                                   XCTAssertNotNil(rendezvous.metadata);
                                   XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
                                   randomTag = rendezvous.tag;
                                   rendezvousRef = rendezvous.metadata.rendezvousRef;
                                   
                                   [createExpectation fulfill];
                               }];
    [self waitForExpectationsWithTimeout:20.0
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    
    __block XCTestExpectation *failCreateExpectation = [self expectationWithDescription:@"create rendezvous with the same tag"];
    
    [testClient1 createAnonymousRendezvousWithTag:randomTag
                                    duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                               summaryValues:nil
                           completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                               XCTAssertNotNil(error);
                               XCTAssertNil(rendezvous);
                               
                               XCTAssertEqual(error.code,QredoErrorCodeRendezvousAlreadyExists);
                               
                               [failCreateExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:20.0
                                 handler:^(NSError *error) {
                                     failCreateExpectation = nil;
                                 }];
    
    
    //Enumerating stored rendezvous
    __block XCTestExpectation *didFindStoredRendezvousMetadataExpecttion = [self expectationWithDescription:@"find stored rendezvous metadata"];
    __block QredoRendezvousMetadata *rendezvousMetadataFromEnumeration = nil;
    
    __block int count = 0;
    [testClient1 enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata,BOOL *stop) {
        if ([rendezvousMetadata.tag
             isEqualToString:randomTag]){
            rendezvousMetadataFromEnumeration = rendezvousMetadata;
            XCTAssertNotNil(rendezvousMetadata.rendezvousRef);
            count++;
        }
    }
                       completionHandler:^(NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertEqual(count,1);
                           [didFindStoredRendezvousMetadataExpecttion fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:20.0
                                 handler:^(NSError *error) {
                                     didFindStoredRendezvousMetadataExpecttion = nil;
                                 }];
    
    XCTAssertNotNil(rendezvousMetadataFromEnumeration);
    
    //Fetching the full rendezvous object
    __block XCTestExpectation *didFindStoredRendezvous = [self expectationWithDescription:@"find stored rendezvous"];
    __block QredoRendezvous *rendezvousFromEnumeration = nil;
    
    XCTAssertEqualObjects(rendezvousMetadataFromEnumeration.rendezvousRef.data,rendezvousRef.data);
    
    [testClient1 fetchRendezvousWithMetadata:rendezvousMetadataFromEnumeration
                      completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                          XCTAssertNil(error);
                          XCTAssertNotNil(rendezvous);
                          rendezvousFromEnumeration = rendezvous;
                          [didFindStoredRendezvous fulfill];
                      }];
    
    [self waitForExpectationsWithTimeout:20.0
                                 handler:^(NSError *error) {
                                     didFindStoredRendezvous = nil;
                                 }];
    
    XCTAssertNotNil(rendezvousFromEnumeration);
    
    [self verifyRendezvous:rendezvousFromEnumeration randomTag:randomTag];
    
    
    //Trying to load the rendezvous by tag, without enumeration
    __block XCTestExpectation *didFetchExpectation = [self expectationWithDescription:@"fetch rendezvous from vault by tag"];
    __block QredoRendezvous *rendezvousFromFetch = nil;
    [testClient1 fetchRendezvousWithRef:rendezvousRef
                 completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                     XCTAssertNotNil(rendezvous);
                     XCTAssertNil(error);
                     
                     rendezvousFromFetch = rendezvous;
                     [didFetchExpectation fulfill];
                 }];
    
    [self waitForExpectationsWithTimeout:20.0
                                 handler:^(NSError *error) {
                                     didFetchExpectation = nil;
                                 }];
    
    
    XCTAssertNotNil(rendezvousFromFetch);
    
    [self verifyRendezvous:rendezvousFromFetch randomTag:randomTag];
}


-(void)testCreateDuplicateAndFetchAnonymousRendezvous {
    __block NSString *randomTag = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvousRef *rendezvousRef = nil;
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:kRendezvousTestDurationSeconds
                              unlimitedResponses:YES
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error)
     {
         XCTAssertNil(error);
         XCTAssertNotNil(rendezvous);
         rendezvousRef = rendezvous.metadata.rendezvousRef;
         randomTag = rendezvous.tag;
         [createExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    
    __block XCTestExpectation *failCreateExpectation = [self expectationWithDescription:@"create rendezvous with the same tag"];
    
    [testClient1 createAnonymousRendezvousWithTag:randomTag
                                    duration:kRendezvousTestDurationSeconds
                          unlimitedResponses:YES
                                    summaryValues:nil
                           completionHandler:^(QredoRendezvous *rendezvous,NSError *error)
     {
         XCTAssertNotNil(error);
         XCTAssertNil(rendezvous);
         
         XCTAssertEqual(error.code,QredoErrorCodeRendezvousAlreadyExists);
         
         [failCreateExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     failCreateExpectation = nil;
                                 }];
    
    XCTAssertNotNil(rendezvousRef);
    
    
    //Enumerating stored rendezvous
    __block XCTestExpectation *didFindStoredRendezvousMetadataExpecttion = [self expectationWithDescription:@"find stored rendezvous metadata"];
    __block QredoRendezvousMetadata *rendezvousMetadataFromEnumeration = nil;
    
    __block int count = 0;
    [testClient1 enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata,BOOL *stop) {
        if ([rendezvousMetadata.tag
             isEqualToString:randomTag]){
            rendezvousMetadataFromEnumeration = rendezvousMetadata;
            count++;
        }
    }
                       completionHandler:^(NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertEqual(count,1);
                           [didFindStoredRendezvousMetadataExpecttion fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:10.0
                                 handler:^(NSError *error) {
                                     didFindStoredRendezvousMetadataExpecttion = nil;
                                 }];
    
    XCTAssertNotNil(rendezvousMetadataFromEnumeration);
    
    //Fetching the full rendezvous object
    __block XCTestExpectation *didFindStoredRendezvous = [self expectationWithDescription:@"find stored rendezvous"];
    __block QredoRendezvous *rendezvousFromEnumeration = nil;
    
    [testClient1 fetchRendezvousWithMetadata:rendezvousMetadataFromEnumeration
                      completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                          XCTAssertNil(error);
                          XCTAssertNotNil(rendezvous);
                          rendezvousFromEnumeration = rendezvous;
                          [didFindStoredRendezvous fulfill];
                      }];
    
    [self waitForExpectationsWithTimeout:2.0
                                 handler:^(NSError *error) {
                                     didFindStoredRendezvous = nil;
                                 }];
    
    
    XCTAssertNotNil(rendezvousFromEnumeration);
    
    [self verifyRendezvous:rendezvousFromEnumeration randomTag:randomTag];
    
    
    //Trying to load the rendezvous by tag, without enumeration
    __block XCTestExpectation *didFetchExpectation = [self expectationWithDescription:@"fetch rendezvous from vault by tag"];
    __block QredoRendezvous *rendezvousFromFetch = nil;
    [testClient1 fetchRendezvousWithRef:rendezvousRef
                 completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                     XCTAssertNotNil(rendezvous);
                     XCTAssertNil(error);
                     
                     rendezvousFromFetch = rendezvous;
                     [didFetchExpectation fulfill];
                 }];
    
    [self waitForExpectationsWithTimeout:2.0
                                 handler:^(NSError *error) {
                                     didFetchExpectation = nil;
                                 }];
    
    
    XCTAssertNotNil(rendezvousFromFetch);
    
    [self verifyRendezvous:rendezvousFromFetch randomTag:randomTag];
}



//-(void)testMultiplePublicKeyPersistence {
//    for (int i=0;i<100;i++){
//        [self testPublicKeyPersistence];
//    }
//}
    

-(void)testPublicKeyPersistence {
    
    self.continueAfterFailure = YES;
    
    //Created CLIENTS
    __block QredoClient *clientPersistent1;
    __block QredoClient *clientPersistent2;
    
    __block QredoClient *clientPersistent3;
    __block QredoClient *clientPersistent4;
    
    
    
    NSString *client1Password = [self randomPassword];
    NSString *client2Password = [self randomPassword];
    
    NSString *client1User = [self randomUsername];
    NSString *client2User = [self randomUsername];
    
    
    
    
    __block XCTestExpectation *clientExpectation1 = [self expectationWithDescription:@"create client1"];
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:client1User
                          userSecret:client1Password
                             options:self.clientOptions
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       clientPersistent1 = clientArg;
                       [clientExpectation1 fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation1 = nil;
                                 }];
    
    
    
    
    XCTAssertNotNil(clientPersistent1,@"Shouldnt be nil");
    
    
    __block XCTestExpectation *clientExpectation2 = [self expectationWithDescription:@"create client2"];
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:client2User
                          userSecret:client2Password
                             options:self.clientOptions
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       clientPersistent2 = clientArg;
                       [clientExpectation2 fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation2 = nil;
                                 }];
    
    
    XCTAssertNotNil(clientPersistent2,@"Shouldnt be nil");
    
    
    //open new clients and see if the public keys are still there for the conversations
    __block XCTestExpectation *clientExpectation3 = [self expectationWithDescription:@"create client1"];
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:client1User
                          userSecret:client1Password
                             options:self.clientOptions
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       clientPersistent3 = clientArg;
                       [clientExpectation3 fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation3 = nil;
                                 }];
    
    
    
    XCTAssertNotNil(clientPersistent3,@"Shouldnt be nil");
    
    __block XCTestExpectation *clientExpectation4 = [self expectationWithDescription:@"create client2"];
    
    [QredoClient initializeWithAppId:k_TEST_APPID
                           appSecret:k_TEST_APPSECRET
                              userId:client2User
                          userSecret:client2Password
                             options:self.clientOptions
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       clientPersistent4 = clientArg;
                       [clientExpectation4 fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation4 = nil;
                                 }];
    
    
    XCTAssertNotNil(clientPersistent4,@"Shouldnt be nil");
    
    
    //Create Rendezvous
    __block NSString *randomTag = nil;
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [clientPersistent1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                                   duration:kRendezvousTestDurationSeconds
                                         unlimitedResponses:YES
                                              summaryValues:nil
                                          completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                              XCTAssertNil(error);
                                              XCTAssertNotNil(rendezvous);
                                              randomTag = rendezvous.tag;
                                              createdRendezvous = rendezvous;
                                              [createExpectation fulfill];
                                          }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    
    
    //Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    [createdRendezvous addRendezvousObserver:listener];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertNotNil(createdRendezvous);
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    
    
    [NSThread sleepForTimeInterval:1];
    
    
    //complete build rendezvous & listener for response
    
    __block QredoConversation *client2Conversation;
    
    
    [clientPersistent2 respondWithTag:randomTag
                    completionHandler:^(QredoConversation *conversation,NSError *error) {
                        XCTAssertNil(error);
                        [respondExpectation fulfill];
                        client2Conversation = conversation;
                    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     respondExpectation = nil;
                                     listener.expectation = nil;
                                 }];
    
    
    
    QredoConversation *client1Conversation = listener.incomingConversation;
    
    
    
    XCTAssertNotNil(client1Conversation);
    XCTAssertNotNil(client2Conversation);
    
    NSString *client1Myingerprint     = [client1Conversation showMyFingerPrint];
    NSString *client1RemoteFingerprint   = [client1Conversation showRemoteFingerPrint];
    
    NSString *client2MyFingerprint     = [client2Conversation showMyFingerPrint];
    NSString *client2TheirFingerprint   = [client2Conversation showRemoteFingerPrint];
    
    
    XCTAssertTrue([client1Myingerprint isEqualToString:client2TheirFingerprint],@"fingerprints dont match");
    XCTAssertTrue([client1RemoteFingerprint isEqualToString:client2MyFingerprint],@"fingerprints dont match");
    
    
    
    
    __block XCTestExpectation *conversationEnumExpectation = [self expectationWithDescription:@"conversationEnumExpectation"];
    [createdRendezvous enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        [clientPersistent1                    fetchConversationWithRef:conversationMetadata.conversationRef
                                                     completionHandler:^(QredoConversation *conversation,NSError *error) {
                                                         XCTAssertNotNil([conversation showMyFingerPrint],@"finger print shoud not be nil");
                                                         XCTAssertNotNil([conversation showRemoteFingerPrint],@"finger print shoud not be nil");
                                                     }];
    }
                                     completionHandler:^(NSError *error) {
                                         [conversationEnumExpectation fulfill];
                                         XCTAssertNil(error);
                                     }];
    
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     conversationEnumExpectation = nil;
                                 }];
    
    [createdRendezvous removeRendezvousObserver:listener];
    [clientPersistent1 closeSession];
    [clientPersistent2 closeSession];
    
    
    
    
    __block QredoRendezvous *previousRendezvous = nil;
    
    __block XCTestExpectation *fetchRendezvous = [self expectationWithDescription:@"create client2"];
    
    
    [clientPersistent3 fetchRendezvousWithTag:randomTag
                            completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                previousRendezvous = rendezvous;
                                [fetchRendezvous fulfill];
                                XCTAssertNotNil(rendezvous);
                            }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     fetchRendezvous = nil;
                                 }];
    
    
    
    //enumerate the client and see if we have the first conversation
    [NSThread sleepForTimeInterval:5];
    
    __block QredoConversation *conv = nil;
    __block QredoConversationMetadata *convMeta = nil;
    __block XCTestExpectation *previousConversationEnumExpectation = [self expectationWithDescription:@"conversationEnumExpectation"];
    
    [previousRendezvous enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        convMeta = conversationMetadata;
        [clientPersistent3                     fetchConversationWithRef:conversationMetadata.conversationRef
                                                      completionHandler:^(QredoConversation *conversation,NSError *error) {
                                                          conv = conversation;
                                                      }];
    }
                                      completionHandler:^(NSError *error) {
                                          [previousConversationEnumExpectation fulfill];
                                          XCTAssertNil(error);
                                      }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     previousConversationEnumExpectation = nil;
                                 }];
    
    XCTAssertNotNil(conv);
    
    //enumerate the client4 and see if we have the first conversation
    
    __block QredoConversation *conv4 = nil;
    __block XCTestExpectation *previousConversationEnumExpectation4 = [self expectationWithDescription:@"conversationEnumExpectation"];
    [clientPersistent4 enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        [clientPersistent4                    fetchConversationWithRef:conversationMetadata.conversationRef
                                                     completionHandler:^(QredoConversation *conversation,NSError *error) {
                                                         conv4 = conversation;
                                                     }];
    }
                                     completionHandler:^(NSError *error) {
                                         [previousConversationEnumExpectation4 fulfill];
                                         XCTAssertNil(error);
                                     }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     previousConversationEnumExpectation4 = nil;
                                 }];
    
    XCTAssertNotNil(conv4);
}


-(void)testFingerPrintsAndTrafficLights {
    __block NSString *randomTag = nil;
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:kRendezvousTestDurationSeconds
                              unlimitedResponses:YES
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(rendezvous);
                                   randomTag = rendezvous.tag;
                                   createdRendezvous = rendezvous;
                                   [createExpectation fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    
    //Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    [createdRendezvous addRendezvousObserver:listener];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertNotNil(createdRendezvous);
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    
    
    [NSThread sleepForTimeInterval:1];
    
    
    //complete build rendezvous & listener for response
    
    __block QredoConversation *client2Conversation;
    
    
    [testClient2 respondWithTag:randomTag
          completionHandler:^(QredoConversation *conversation,NSError *error) {
              XCTAssertNil(error);
              [respondExpectation fulfill];
              client2Conversation = conversation;
          }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     respondExpectation = nil;
                                     listener.expectation = nil;
                                 }];
    
    
    
    QredoConversation *client1Conversation = listener.incomingConversation;
    
    
    
    
    
    XCTAssertNotNil(client1Conversation);
    XCTAssertNotNil(client2Conversation);
    
    
    
    NSString *client1Myingerprint       = [client1Conversation showMyFingerPrint];
    NSString *client1RemoteFingerprint   = [client1Conversation showRemoteFingerPrint];
    
    
    NSString *client2MyFingerprint     = [client2Conversation showMyFingerPrint];
    NSString *client2TheirFingerprint   = [client2Conversation showRemoteFingerPrint];
    
    
    
    XCTAssertTrue([client1Myingerprint isEqualToString:client2TheirFingerprint],@"fingerprints dont match");
    XCTAssertTrue([client1RemoteFingerprint isEqualToString:client2MyFingerprint],@"fingerprints dont match");
    
    
    
    
    __block XCTestExpectation *conversationEnumExpectation = [self expectationWithDescription:@"conversationEnumExpectation"];
    [createdRendezvous enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        [testClient1                    fetchConversationWithRef:conversationMetadata.conversationRef
                                          completionHandler:^(QredoConversation *conversation,NSError *error) {
                                              XCTAssertNotNil([conversation showMyFingerPrint],@"finger print shoud not be nil");
                                              XCTAssertNotNil([conversation showRemoteFingerPrint],@"finger print shoud not be nil");
                                          }];
    }
                                     completionHandler:^(NSError *error) {
                                         [conversationEnumExpectation fulfill];
                                         XCTAssertNil(error);
                                     }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     conversationEnumExpectation = nil;
                                 }];
    
    
    
    
    
    XCTAssertTrue([client1Conversation authTrafficLight] == QREDO_RED,@"unauth'd should be red");
    XCTAssertTrue([client2Conversation authTrafficLight] == QREDO_RED,@"unauth'd should be red");
    
    
    //check local finger print
    __block XCTestExpectation *localFingerprintCheck1 = [self expectationWithDescription:@"fingerprintcheck1"];
    [client1Conversation otherPartyHasMyFingerPrint:^(NSError *error) {
        XCTAssertNil(error,@"error should be nil");
        XCTAssertTrue([client1Conversation authTrafficLight] == QREDO_AMBER,@"auth'd should be green");
        XCTAssertTrue([client2Conversation authTrafficLight] == QREDO_RED,@"unauth'd should be red");
        [localFingerprintCheck1 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     localFingerprintCheck1 = nil;
                                 }];
    
    
    
    
    
    
    //check local finger print
    __block XCTestExpectation *localFingerprintCheck2 = [self expectationWithDescription:@"fingerprintcheck2"];
    [client1Conversation iHaveRemoteFingerPrint:^(NSError *error) {
        XCTAssertNil(error,@"error should be nil");
        XCTAssertTrue([client1Conversation authTrafficLight] == QREDO_GREEN,@"auth'd should be green");
        XCTAssertTrue([client2Conversation authTrafficLight] == QREDO_RED,@"auth'd should be green");
        [localFingerprintCheck2 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     localFingerprintCheck2 = nil;
                                 }];
    
    
    
    
    
    
    [createdRendezvous removeRendezvousObserver:listener];
}


-(void)testCreateAndRespondAnonymousRendezvousPreCreate {
    __block NSString *randomTag = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    __block QredoRendezvous *createdRendezvous = nil;
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:kRendezvousTestDurationSeconds
                              unlimitedResponses:YES
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(rendezvous);
                                   randomTag = rendezvous.tag;
                                   createdRendezvous = rendezvous;
                                   [createExpectation fulfill];
                               }];
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    
    //Listening for responses and respond from another client
    RendezvousListener *listener = [[RendezvousListener alloc] init];
    [createdRendezvous addRendezvousObserver:listener];
    [NSThread sleepForTimeInterval:0.1];
    XCTAssertNotNil(createdRendezvous);
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"verify: respond to rendezvous"];
    
    
    [NSThread sleepForTimeInterval:1];
    
    
    //complete build rendezvous & listener for response
    
    
    
    
    
    [testClient2 respondWithTag:randomTag
          completionHandler:^(QredoConversation *conversation,NSError *error) {
              XCTAssertNil(error);
              [respondExpectation fulfill];
          }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     respondExpectation = nil;
                                     listener.expectation = nil;
                                 }];
    
    [createdRendezvous removeRendezvousObserver:listener];
}


-(QredoRendezvousRef *)createRendezvousWithDuration:(int)testDuration {
    __block NSString *randomTag = nil;
    
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    __block QredoRendezvousRef *rendezvousRef = nil;
    
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                        duration:testDuration
                              unlimitedResponses:NO
                                   summaryValues:nil
                               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(rendezvous);
                                   
                                   XCTAssertNotNil(rendezvous.metadata);
                                   XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
                                   randomTag = rendezvous.tag;
                                   rendezvousRef = rendezvous.metadata.rendezvousRef;
                                   
                                   [createExpectation fulfill];
                               }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    self.randomlyCreatedTag = randomTag;
    return rendezvousRef;
}


-(void)testActivateExpiredRendezvous {
    int testDuration = 1;
    
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:1];
    
    XCTAssertNotNil(rendezvousRef);
    
    
    //now sleep until the rendezvous expires
    [NSThread sleepForTimeInterval:2];
    
    
    //check that it has expired
    //responding to the expired rendezvous should fail
    __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"respond to  rendezvous"];
    
    
    [testClient1 respondWithTag:self.randomlyCreatedTag
         completionHandler:^(QredoConversation *conversation,NSError *error) {
             XCTAssert(error.code == QredoErrorCodeRendezvousUnknownResponse);
             [respondExpectation fulfill];
         }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     respondExpectation = nil;
                                 }];
    
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    
    //now activate the rendezvous
    [testClient1 activateRendezvousWithRef:rendezvousRef
                             duration:1000
                    completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                        //check the responses
                        XCTAssertNil(error);
                        XCTAssertNotNil(rendezvous);
                        
                        XCTAssertNotNil(rendezvous.metadata);
                        XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
                        
                        //ensure that the response count is unlimited and the duration is what we passed in
                        XCTAssertTrue(rendezvous.unlimitedResponses == YES);
                        XCTAssertTrue(rendezvous.duration == 1000);
                        
                        XCTAssert([self.randomlyCreatedTag
                                   isEqualToString:rendezvous.metadata.tag]);
                        
                        [createActivateExpectation fulfill];
                    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createActivateExpectation = nil;
                                 }];
}


-(void)testActivateExpiredRendezvousAndFetchFromNewRef {
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:1];
    
    XCTAssertNotNil(rendezvousRef);
    
    //now sleep until the rendezvous expires
    [NSThread sleepForTimeInterval:2];
    
    //check that it has expired
    //responding to the expired rendezvous should fail
     __block XCTestExpectation *respondExpectation = [self expectationWithDescription:@"respond to  rendezvous"];
    
    [testClient1 respondWithTag:self.randomlyCreatedTag
         completionHandler:^(QredoConversation *conversation,NSError *error) {
             XCTAssert(error.code == QredoErrorCodeRendezvousUnknownResponse,@"Error is %@",error);
             [respondExpectation fulfill];
         }];
    
   
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     respondExpectation = nil;
                                 }];

    
    
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    //now activate the rendezvous
    [testClient1 activateRendezvousWithRef:rendezvousRef
                             duration:1000
                    completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                        //check the responses
                        XCTAssertNil(error);
                        XCTAssertNotNil(rendezvous);
                        
                        XCTAssertNotNil(rendezvous.metadata);
                        XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
                        QredoRendezvousRef *newRendezvousRef = rendezvous.metadata.rendezvousRef;
                        
                        [testClient1  fetchRendezvousWithRef:newRendezvousRef
                                      completionHandler:^(QredoRendezvous *activatedRendezvous,NSError *error) {
                                          XCTAssertNil(error,@"Error %@",error);
                                          XCTAssertNotNil(activatedRendezvous);
                                          XCTAssertNotNil(activatedRendezvous.metadata);
                                          XCTAssertNotNil(activatedRendezvous.metadata.rendezvousRef);
                                          
                                          XCTAssertTrue(activatedRendezvous.unlimitedResponses == YES);
                                          
                                          XCTAssertTrue(activatedRendezvous.duration == 1000);
                                          
                                          XCTAssert([self.randomlyCreatedTag
                                                     isEqualToString:rendezvous.metadata.tag]);
                                      }];
                        
                        [createActivateExpectation fulfill];
                    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createActivateExpectation = nil;
                                 }];
}


-(void)testActivateUnexpiredRendezvous {
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    
    XCTAssertNotNil(rendezvousRef);
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    
    //now activate the rendezvous
    [testClient1 activateRendezvousWithRef:rendezvousRef
                             duration:1000
                    completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                        //check the responses
                        XCTAssertNil(error);
                        XCTAssertNotNil(rendezvous);
                        
                        XCTAssertNotNil(rendezvous.metadata);
                        XCTAssertNotNil(rendezvous.metadata.rendezvousRef);
                        XCTAssertTrue(rendezvous.unlimitedResponses == YES);
                        XCTAssertTrue(rendezvous.duration == 1000);
                        XCTAssert([self.randomlyCreatedTag
                                   isEqualToString:rendezvous.metadata.tag]);
                        
                        
                        [createActivateExpectation fulfill];
                    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createActivateExpectation = nil;
                                 }];
}


-(void)testActivateUnknownRendezvous {
    //create an invalid rendezvousRef
    QredoRendezvousRef *rendezvousRef = [self createUnknownRendezvousRef];
    
    XCTAssertNotNil(rendezvousRef);
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    //now activate the rendezvous.
    [testClient1 activateRendezvousWithRef:rendezvousRef
                             duration:1000
                    completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                        //check the response. it should return an error since the rendezvous cannot be found
                        XCTAssertNotNil(error);
                        XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
                        
                        [createActivateExpectation fulfill];
                    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createActivateExpectation = nil;
                                 }];
}


-(void)testActivateNilRendezvous {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    QredoRendezvousRef *rendezvousRef = NULL;
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    [QredoLogger setLogLevel:QredoLogLevelNone];
    
    
    //now activate the rendezvous
    [testClient1 activateRendezvousWithRef:rendezvousRef
                             duration:1000
                    completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                        //check the responses. we expect an error
                        XCTAssertNotNil(error);
                        XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
                        
                        [createActivateExpectation fulfill];
                    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createActivateExpectation = nil;
                                 }];
}


-(void)testActivateUnexpiredRendezvousNilCompletionHandler {
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    
    XCTAssertNotNil(rendezvousRef);
    
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    @try {
        //activate the rendezvous with a nil completion handler
        [testClient1 activateRendezvousWithRef:rendezvousRef duration:1000 completionHandler:nil];
    } @catch (NSException *e){
        //we are expecting an error. check it's the right one
        XCTAssert([e.reason isEqualToString:@"CompletionHandlerisNil"]);
        [createActivateExpectation fulfill];
    }
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createActivateExpectation = nil;
                                 }];
}


-(void)testActivateInvalidDuration {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    XCTAssertNotNil(rendezvousRef);
    
    __block XCTestExpectation *createActivateExpectation = [self expectationWithDescription:@"activate rendezvous"];
    
    
    //now activate the rendezvous
    [testClient1 activateRendezvousWithRef:rendezvousRef
                             duration:-201
                    completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                        //check the responses
                        XCTAssertNotNil(error);
                        XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
                        [createActivateExpectation fulfill];
                    }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createActivateExpectation = nil;
                                 }];
}


-(void)testDeactivateRendezvous {
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    
    XCTAssertNotNil(rendezvousRef);
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate rendezvous"];
    
    
    //now deactivate the rendezvous
    [testClient1 deactivateRendezvousWithRef:rendezvousRef
                      completionHandler:^(NSError *error) {
                          //
                          //check the response. Should just complete with no error
                          XCTAssertNil(error);
                          
                          [deactivateExpectation fulfill];
                      }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     deactivateExpectation = nil;
                                 }];
}


-(void)testDeactivateExpiredRendezvous {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:1];
    XCTAssertNotNil(rendezvousRef);
    
    //now sleep until the rendezvous expires
    [NSThread sleepForTimeInterval:2];
    
    
    //check that it has expired
    //responding to the expired rendezvous should fail
    [testClient1 respondWithTag:self.randomlyCreatedTag
         completionHandler:^(QredoConversation *conversation,NSError *error) {
             //
             XCTAssert(error.code == QredoErrorCodeRendezvousUnknownResponse);
         }];
    
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate rendezvous"];
    
    
    //now deactivate the rendezvous
    [testClient1 deactivateRendezvousWithRef:rendezvousRef
                      completionHandler:^(NSError *error) {
                          //
                          //check the response. Should just complete with no error
                          XCTAssertNil(error);
                          
                          [deactivateExpectation fulfill];
                      }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     deactivateExpectation = nil;
                                 }];
}


-(void)testDeactivateAndRespondToRendezvous {
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:300];
    
    XCTAssertNotNil(rendezvousRef);
    
    
    //should not be able to respond to a deactivated rendezvous
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate rendezvous"];
    
    
    [testClient1 deactivateRendezvousWithRef:rendezvousRef
                      completionHandler:^(NSError *error) {
                          //
                          //check the response. Should just complete with no error
                          XCTAssertNil(error);
                          
                          //responding to the deactivated rendezvous should fail
                          [testClient1 respondWithTag:self.randomlyCreatedTag
                               completionHandler:^(QredoConversation *conversation,NSError *error) {
                                   //
                                   XCTAssert(error.code == QredoErrorCodeRendezvousUnknownResponse);
                               }];
                          
                          [deactivateExpectation fulfill];
                      }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     deactivateExpectation = nil;
                                 }];
}


-(void)testDeactivateRendezvousNilCompletionHandler {
    QredoRendezvousRef *rendezvousRef = [self createRendezvousWithDuration:20000];
    
    XCTAssertNotNil(rendezvousRef);
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate rendezvous nil completion handler"];
    
    @try {
        //now deactivate the rendezvous
        [testClient1 deactivateRendezvousWithRef:rendezvousRef completionHandler:nil ];
    } @catch (NSException *e){
        //we are expecting an error. check it's the right one
        XCTAssert([e.reason isEqualToString:@"CompletionHandlerisNil"]);
        [deactivateExpectation fulfill];
    }
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     deactivateExpectation = nil;
                                 }];
}


-(void)testDeactivateNilRendezvous {
    [QredoLogger setLogLevel:QredoLogLevelNone];
    QredoRendezvousRef *rendezvousRef = nil;
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate nil rendezvous"];
    
    
    //now deactivate the rendezvous
    [testClient1 deactivateRendezvousWithRef:rendezvousRef
                      completionHandler:^(NSError *error) {
                          //check the responses. we expect an error
                          XCTAssertNotNil(error);
                          XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
                          
                          [deactivateExpectation fulfill];
                      }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     deactivateExpectation = nil;
                                 }];
}


-(void)testDeactivateUnknownRendezvous {
    QredoRendezvousRef *newRef = [self createUnknownRendezvousRef];
    
    XCTAssertNotNil(newRef);
    
    
    __block XCTestExpectation *deactivateExpectation = [self expectationWithDescription:@"deactivate unknown rendezvous"];
    
    
    //now deactivate the rendezvous
    [testClient1 deactivateRendezvousWithRef:newRef
                      completionHandler:^(NSError *error) {
                          //check the responses. we expect an error. for this test it will be QredoErrorCodeRendezvousInvalidData
                          XCTAssertNotNil(error);
                          XCTAssert(error.code == QredoErrorCodeRendezvousInvalidData);
                          [deactivateExpectation fulfill];
                      }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     deactivateExpectation = nil;
                                 }];
}


-(QredoRendezvousRef *)createUnknownRendezvousRef {
    QredoVault *vault = [testClient1 systemVault];
    
    NSDictionary *item1SummaryValues = @{ @"name":@"Joe Bloggs" };
    QredoVaultItem *item1 =  [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                             value:[@"item name" dataUsingEncoding:NSUTF8StringEncoding]];
    
    __block XCTestExpectation *createRendezvousRefExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    __block QredoRendezvousRef *rendezvousRef = nil;
    
    [vault putItem:item1
 completionHandler:
     ^(QredoVaultItemMetadata *newVaultItemMetadata,NSError *error)
     {
         rendezvousRef = [[QredoRendezvousRef alloc] initWithVaultItemDescriptor:newVaultItemMetadata.descriptor
                                                                           vault:vault];
         
         [createRendezvousRefExpectation fulfill];
     }];
    
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout
                                 handler:^(NSError *error) {
                                     createRendezvousRefExpectation = nil;
                                 }];
    
    return rendezvousRef;
}


@end
