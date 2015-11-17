#import "ConversationWebSocketRespondTests.h"
#import "QredoTestUtils.h"
#import "QredoPrivate.h"

static NSString *const kMessageType = @"com.qredo.text";
static NSString *const kMessageTestValue = @"(1)hello, world";
static NSString *const kMessageTestValue2 = @"(2)another hello, world";

NSTimeInterval qtu_defaultTimeout = 30.0;

@interface ConversationMessageListener : NSObject <QredoConversationObserver>
@property __weak XCTestExpectation *didReceiveMessageExpectation;
@property NSString *expectedMessageValue;
@property BOOL failed;

@end

@implementation ConversationMessageListener

- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message
{
    // Can't use XCTAsset, because this class is not XCTestCase
    
    self.failed |= (message == nil);
    self.failed |= !([message.value isEqualToData:[self.expectedMessageValue dataUsingEncoding:NSUTF8StringEncoding]]);
    
    self.failed |= !([message.dataType isEqualToString:kMessageType]);
    
    [self.didReceiveMessageExpectation fulfill];
}

@end

@interface ConversationWebSocketRespondTests() <QredoRendezvousObserver>
{
    QredoClient *client;
    XCTestExpectation *didReceiveResponseExpectation;
    
    QredoConversation *creatorConversation;
}

@property NSString *conversationType;
@end

@implementation ConversationWebSocketRespondTests

- (void)setUp {
    [super setUp];
    self.conversationType = @"test.chat~";
    self.transportType = QredoClientOptionsTransportTypeWebSockets;
    [self authoriseClient];
}

-(void)tearDown {
    [super tearDown];
    if (client) {
        [client closeSession];
    }
}

- (QredoClientOptions *)clientOptionsWithResetData:(BOOL)resetData
{
    QredoClientOptions *clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    clientOptions.transportType = self.transportType;
    clientOptions.resetData = resetData;
    
    return clientOptions;
}

- (void)authoriseClient
{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    
    [QredoClient authorizeWithConversationTypes:@[self.conversationType]
                                 vaultDataTypes:nil
                                        options:[self clientOptionsWithResetData:YES]
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
    XCTAssertNotNil(client);
    XCTAssertNotNil(client.systemVault);
    XCTAssertNotNil(client.systemVault.vaultId);
}

// This test has frequently helped in triggering intermittent bugs
- (void)testConversationMultiple
{
    // TODO: DH - Sometimes an iteration of this test fails, so don't abort everything on this failing
    self.continueAfterFailure = YES;

    for (int i = 0; i < 30; i++)
    {        
        [self conversation];
    }
}

- (void)conversation
{

    [NSThread sleepForTimeInterval:5];
    
    NSString* fileContents = [NSString stringWithContentsOfFile:@"/tmp/multipletag.tmp" encoding:NSUTF8StringEncoding error:nil];
    NSArray* allLinedStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    self.randomTag = [allLinedStrings objectAtIndex:0];
    
    NSLog(@"randomTag: -%@-", self.randomTag);
    
    __block QredoRendezvous *rendezvous = nil;
    
    // Responding to the rendezvous
    __block XCTestExpectation *didRespondExpectation = [self expectationWithDescription:@"responded to rendezvous"];
    //    didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    [rendezvous addRendezvousObserver:self];
    
    //    __block QredoConversation *responderConversation = nil;
    // Definitely responding to an anonymous rendezvous, so nil trustedRootPems/crlPems is valid for this test
    [client respondWithTag:self.randomTag
           trustedRootPems:nil
                   crlPems:nil
         completionHandler:^(QredoConversation *conversation, NSError *error) {
             XCTAssertNil(error);
             XCTAssertNotNil(conversation);
             
             creatorConversation = conversation;
             
             [didRespondExpectation fulfill];
         }];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        didRespondExpectation = nil;
    }];
    
    [rendezvous removeRendezvousObserver:self];
    
    // Sending message
    XCTAssertNotNil(creatorConversation);
    
    
    [NSThread sleepForTimeInterval:3];
    
    __block XCTestExpectation *didPublishMessageExpectation = [self expectationWithDescription:@"published a message before listener started"];
    
    NSString *firstMessageText = kMessageTestValue;
    
    QredoConversationMessage *newMessage = [[QredoConversationMessage alloc] initWithValue:[firstMessageText dataUsingEncoding:NSUTF8StringEncoding]
                                                                                  dataType:kMessageType
                                                                             summaryValues:nil];
    
    [creatorConversation publishMessage:newMessage
                      completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                          XCTAssertNil(error);
                          XCTAssertNotNil(messageHighWatermark);
                          
                          [didPublishMessageExpectation fulfill];
                      }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didPublishMessageExpectation = nil;
    }];
    
    [NSThread sleepForTimeInterval:3];
    
    
    
    NSString *secondMessageText = kMessageTestValue2;
    
    newMessage = [[QredoConversationMessage alloc] initWithValue:[secondMessageText dataUsingEncoding:NSUTF8StringEncoding] dataType:kMessageType summaryValues:nil];
    didPublishMessageExpectation = [self expectationWithDescription:@"published a message after listener started"];
    
    [creatorConversation publishMessage:newMessage
                      completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                          XCTAssertNil(error);
                          XCTAssertNotNil(messageHighWatermark);
                          
                          [didPublishMessageExpectation fulfill];
                      }];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        didPublishMessageExpectation = nil;
    }];
}

// Rendezvous Delegate
- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    
    //    NSLog(@"QredoRendezvous: %@, creatorConversation: %@, conversation: %@", rendezvous, creatorConversation, conversation);
    creatorConversation = conversation;
    [didReceiveResponseExpectation fulfill];
}

@end
