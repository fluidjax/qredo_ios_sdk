#import "ConversationWebSocketCreateTests.h"
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

@interface ConversationWebSocketCreateTests() <QredoRendezvousObserver>
{
    QredoClient *client;
    XCTestExpectation *didReceiveResponseExpectation;
    
    QredoConversation *creatorConversation;
}

@property NSString *conversationType;
@end

@implementation ConversationWebSocketCreateTests

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
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
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
    
    for (int i = 0; i < 3; i++)
    {        
        [self conversation];
    }
}

- (void)conversation
{
    self.randomTag = [[QredoQUID QUID] QUIDString];
    
    NSError *error;
    BOOL succeed = [self.randomTag writeToFile:@"/tmp/multipletag.tmp" atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!succeed){
        NSLog(@"%@", error);
    } else {
        NSLog(@"-%@-", self.randomTag);
    }
    
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"test.chat~" durationSeconds:@120 isUnlimitedResponseCount:NO];
    
    __block QredoRendezvous *rendezvous = nil;
    
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    [client createAnonymousRendezvousWithTag:self.randomTag
                               configuration:configuration
                           completionHandler:^(QredoRendezvous *_rendezvous, NSError *error) {
                               XCTAssertNil(error);
                               XCTAssertNotNil(_rendezvous);
                               
                               rendezvous = _rendezvous;
                               
                               [createExpectation fulfill];
                           }];
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        createExpectation = nil;
    }];
    
    didReceiveResponseExpectation = [self expectationWithDescription:@"received response in the creator's delegate"];
    
    [rendezvous addRendezvousObserver:self];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        didReceiveResponseExpectation = nil;
    }];
    
    [rendezvous removeRendezvousObserver:self];
    
    ConversationMessageListener *listener = [[ConversationMessageListener alloc] init];
    listener.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message published before listening"];
    listener.expectedMessageValue = kMessageTestValue;
    
    [creatorConversation addConversationObserver:listener];
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        listener.didReceiveMessageExpectation = nil;
    }];
    XCTAssertFalse(listener.failed);
    
    [NSThread sleepForTimeInterval:2];
    
    listener.didReceiveMessageExpectation = [self expectationWithDescription:@"received the message published after listening"];
    listener.expectedMessageValue = kMessageTestValue2;
    
    [self waitForExpectationsWithTimeout:qtu_defaultTimeout handler:^(NSError *error) {
        listener.didReceiveMessageExpectation = nil;
    }];
    
    [creatorConversation removeConversationObserver:listener];
}

// Rendezvous Delegate
- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    
    //    NSLog(@"QredoRendezvous: %@, creatorConversation: %@, conversation: %@", rendezvous, creatorConversation, conversation);
    creatorConversation = conversation;
    [didReceiveResponseExpectation fulfill];
}

@end
