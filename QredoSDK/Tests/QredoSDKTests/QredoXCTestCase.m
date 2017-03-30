/* HEADER GOES HERE */
#import "QredoXCTestCase.h"
#import "Qredo.h"
#import "MasterConfig.h"
#import "QredoPrivate.h"
#import "QredoXCTestListeners.h"

@import ObjectiveC;


static const int testTimeOut = 30;


@implementation QredoXCTestCase


-(void)setUp {
    [super setUp];
    [QredoLogger colour:NO];
    [QredoLogger setLogLevel:QREDO_DEBUG_LEVEL];

    
    //Here we determine which Server & Credentials are used in all the tests
    //(except for the special Server Tests - which test Dev, Live & Test server specifically)
    
    self.clientOptions = [[QredoClientOptions alloc] initTest];
    self.clientOptions .serverURL         = TEST_SERVER_URL;
    self.clientOptions .useHTTP           = TEST_USE_HTTP;
    self.clientOptions .useHTTP           = TEST_USE_HTTP;
    self.clientOptions .appGroup          = TEST_APP_GROUP;
    self.clientOptions .keyChainGroup     = TEST_KEYCHAIN_GROUP;

    k_TEST_APPID        = TEST_SERVER_APP_ID;
    k_TEST_APPSECRET    = TEST_SERVER_APP_SECRET;
    
    k_TEST_USERID       = TEST_SERVER_USERID;
    k_TEST_USERSECRET   = TEST_SERVER_USERSECRET;
    
    k_TEST_USERID2      = TEST_SERVER_USERID2;
    k_TEST_USERSECRET2  = TEST_SERVER_USERSECRET2;
    
    
    NSAssert(k_TEST_APPID,@"Invalid AppID in");
    NSAssert(k_TEST_APPSECRET,@"Invalid k_TEST_APPSECRET in");
    
}




-(void)tearDown {
    //client
    [testClient1 closeSession];
    [testClient2 closeSession];
    
    testClient1Password = nil;
    testClient2Password = nil;
    
    testClient1User = nil;
    testClient2User = nil;
    
    
    //rendezvous
    rendezvous1 = nil;
    rendezvous1Tag = nil;
    
    
    //conversation
    conversation1 = nil;
    conversation2 = nil;
    conversationHWM = nil;
    
    [super tearDown];
}


-(void)setLogLevel {
    /*  Available debug levels
     [QredoLogger setLogLevel:QredoLogLevelNone];
     [QredoLogger setLogLevel:QredoLogLevelError];
     [QredoLogger setLogLevel:QredoLogLevelWarning];
     [QredoLogger setLogLevel:QredoLogLevelInfo];
     [QredoLogger setLogLevel:QredoLogLevelDebug];
     [QredoLogger setLogLevel:QredoLogLevelVerbose];
     [QredoLogger setLogLevel:QredoLogLevelInfo];
     */
    [QredoLogger setLogLevel:QredoLogLevelError];
}


-(void)loggingOff {
    [QredoLogger setLogLevel:QredoLogLevelNone];
}


-(void)loggingOn {
    [self setLogLevel];
}


-(void)resetKeychain {
    [self deleteAllKeysForSecClass:kSecClassGenericPassword];
    [self deleteAllKeysForSecClass:kSecClassInternetPassword];
    [self deleteAllKeysForSecClass:kSecClassCertificate];
    [self deleteAllKeysForSecClass:kSecClassKey];
    [self deleteAllKeysForSecClass:kSecClassIdentity];
}


-(void)deleteAllKeysForSecClass:(CFTypeRef)secClass {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:(__bridge id)secClass forKey:(__bridge id)kSecClass];
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)dict);
    NSAssert(result == noErr || result == errSecItemNotFound,@"Error deleting keychain data (%ld)",(long)result);
}


-(NSData *)randomDataWithLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity:length];
    
    for (unsigned int i = 0; i < length; i++){
        NSInteger randomBits = arc4random();
        [mutableData appendBytes:(void *)&randomBits length:1];
    }
    
    return mutableData;
}


-(NSString *)randomPassword {
    return [self randomStringWithLength:32];
}


-(NSString *)randomUsername {
    return [self randomStringWithLength:32];
}





-(NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (int i = 0; i < len; i++){
        [randomString appendFormat:@"%C",[letters characterAtIndex:arc4random_uniform((int)[letters length])]];
    }
    
    return randomString;
}


///////////////////////////////////////////////////////////////////////
//Wrapper Methods


-(void)createFixedClients {
    [self createFixedClient1];
    [self createFixedClient2];
}

-(void)createRandomClients {
    [self createRandomClient1];
    [self createRandomClient2];
}




-(void)createRandomClient1 {
    testClient1User     = [self randomUsername];
    testClient1Password = [self randomPassword];
    
    
    testClient1 = [self createClientWithAppID:k_TEST_APPID
                                    appSecret:k_TEST_APPSECRET
                                       userId:testClient1User
                                   userSecret:testClient1Password
                              ];
    
}


-(void)createRandomClient2 {
    testClient2User     = [self randomUsername];
    testClient2Password = [self randomPassword];
    
    testClient2 = [self createClientWithAppID:k_TEST_APPID
                                    appSecret:k_TEST_APPSECRET
                                       userId:testClient2User
                                   userSecret:testClient2Password
                   ];
    
}



-(void)createFixedClient1 {
    testClient1 = [self createClientWithAppID:k_TEST_APPID
                                    appSecret:k_TEST_APPSECRET
                                       userId:k_TEST_USERID
                                   userSecret:k_TEST_USERSECRET];
                   
}


-(void)createFixedClient2 {
    testClient2 = [self createClientWithAppID:k_TEST_APPID
                                    appSecret:k_TEST_APPSECRET
                                       userId:k_TEST_USERID2
                                   userSecret:k_TEST_USERSECRET2];

}


///////////////////////////////////////////////////////////////////////
//Core Methods


-(QredoClient *)createClientWithAppID:(NSString *)appId
                            appSecret:(NSString *)appSecret
                            userId:(NSString *)userId
                            userSecret:(NSString *)userSecret{

    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client"];
    __block QredoClient *client;
    
    
    [QredoClient initializeWithAppId:appId
                           appSecret:appSecret
                              userId:userId
                          userSecret:userSecret
                             options:self.clientOptions
                   completionHandler:^(QredoClient *clientArg,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(clientArg);
                       client = clientArg;
                       [clientExpectation fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     clientExpectation = nil;
                                 }];
    XCTAssertNotNil(client);
    XCTAssertNotNil(client.systemVault);
    XCTAssertNotNil(client.systemVault.vaultId);
    return client;
}



-(void)createRendezvous {
    __block QredoRendezvous *newRendezvous = nil;
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create rendezvous"];
    
    [testClient1 createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                             duration:600
                                   unlimitedResponses:YES
                                        summaryValues:nil
                                    completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                        XCTAssertNil(error);
                                        XCTAssertNotNil(rendezvous);
                                        newRendezvous = rendezvous;
                                        [createExpectation fulfill];
                                    }];
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    XCTAssertNotNil(newRendezvous);
    rendezvous1Tag = newRendezvous.tag;
    XCTAssertNotNil(rendezvous1Tag);
    rendezvous1 = newRendezvous;
}


-(QredoConversation *)simpleRespondToRendezvous:(NSString *)tag {
    //simply respond to the rendezvous on client 1 with client 2
    
    __block QredoConversation *newConversation = nil;
    __block XCTestExpectation *createExpectation = [self expectationWithDescription:@"create conversation"];
    
    [testClient2 respondWithTag:tag
              completionHandler:^(QredoConversation *conversation,NSError *error) {
                  XCTAssertNil(error);
                  XCTAssertNotNil(conversation);
                  newConversation = conversation;
                  [createExpectation fulfill];
              }];
    
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     createExpectation = nil;
                                 }];
    
    XCTAssertNotNil(newConversation);
    return newConversation;
}


-(void)respondToRendezvous {
    //Repspond to rendezvous on Client2 and wait for the listener on Client1 to get notified of the new Conversation
    //testClient1 - gets conversation1
    //testClient2 - gets conversation2
    __block XCTestExpectation *waitForConversation2;
    
    
    //Listening for responses and respond from another client
    TestRendezvousListener *listener = [[TestRendezvousListener alloc] init];
    
    XCTAssertNotNil(rendezvous1);
    
    [rendezvous1 addRendezvousObserver:listener]; //listen for incoming conversations on rendezvous
    
    [self pauseForListenerToRegister];
    
    listener.expectation = [self expectationWithDescription:@"verify: receive listener event for the loaded rendezvous"];
    
    [testClient2 respondWithTag:rendezvous1Tag
              completionHandler:^(QredoConversation *conversation,NSError *error) {
                  XCTAssertNil(error);
                  XCTAssertNotNil(conversation);
                  conversation2 = conversation;
                  [waitForConversation2 fulfill];
              }];
    
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     listener.expectation = nil;
                                 }];
    
    
    //at this point we have the incoming conversation, but if conversation2 is still nil, we need to wait for it also - the order of creation is not know
    if (!conversation2){
        waitForConversation2 = [self expectationWithDescription:@"wait for conversation 2"];
        [self waitForExpectationsWithTimeout:testTimeOut
                                     handler:^(NSError *error) {
                                         waitForConversation2 = nil;
                                     }];

        
        
    }
    

    
    
    conversation1 = listener.incomingConversation;
    [rendezvous1 removeRendezvousObserver:listener];
    XCTAssertNotNil(conversation1);
    XCTAssertNotNil(conversation2);
}


-(void)pauseForListenerToRegister{
    [NSThread sleepForTimeInterval:WAIT_FOR_LISTENER_TO_PROCESS_DELAY];
}


-(void)sendConversationMessageFrom1to2 {
    [self sendMessageFrom:conversation1 to:conversation2];
}


-(void)sendConversationMessageFrom2to1 {
    [self sendMessageFrom:conversation2 to:conversation1];
}


-(QredoConversationHighWatermark*)sendMessageFrom:(QredoConversation *)fromConversation to:(QredoConversation *)toConversation {
    //send a message from ClientA to ClientB
    NSString *message = @"test message";
    
    TestConversationMessageListener *listener = [[TestConversationMessageListener alloc] init];
    
    listener.expectation = [self expectationWithDescription:@"wait for incoming message"];
    listener.expectedMessageValue = message;
    listener.listening = YES;
    
    [toConversation addConversationObserver:listener];
    [self pauseForListenerToRegister];
    
    
    __block QredoConversationHighWatermark *hwm = nil;
    QredoConversationMessage *qredoMessage = [[QredoConversationMessage alloc] initWithValue:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                                               summaryValues:nil];
    
    [fromConversation publishMessage:qredoMessage
                   completionHandler:^(QredoConversationHighWatermark *messageHighWatermark,NSError *error) {
                       XCTAssertNil(error);
                       XCTAssertNotNil(messageHighWatermark);
                       conversationHWM = messageHighWatermark;
                   }];
    
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                 }];
    return conversationHWM;
}


-(int)countConversationsOnRendezvous:(QredoRendezvous *)rendezvous {
    __block XCTestExpectation *countConvExpectation = [self expectationWithDescription:@"count conversation"];
    __block int count = 0;
    
    [rendezvous enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        XCTAssertNotNil(conversationMetadata);
        count++;
    }
                              completionHandler:^(NSError *error) {
                                  [countConvExpectation fulfill];
                                  XCTAssertNil(error);
                              }];
    
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];
    
    return count;
}


-(int)countConversationsOnClient:(QredoClient *)client {
    __block XCTestExpectation *countConvExpectation = [self expectationWithDescription:@"count conversation"];
    __block int count = 0;
    
    [client enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        XCTAssertNotNil(conversationMetadata);
        count++;
    }
                          completionHandler:^(NSError *error) {
                              [countConvExpectation fulfill];
                              XCTAssertNil(error);
                          }];
    
    
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];
    
    return count;
}


/* Vault */
-(QredoVaultItemMetadata *)createVaultItem {
    QredoVault *vault = testClient1.defaultVault;
    
    NSString *testString = @"my test string";
    
    NSData *item1Data = [QredoUtils randomBytesOfLength:64];
    NSDictionary *item1SummaryValues = @{ @"key1":testString };
    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                           value:item1Data];
    
    
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    __block QredoVaultItemMetadata *item1Metadata = nil;
    
    TestVaultListener *listener = [[TestVaultListener alloc] init];
    
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener];
    
    [vault putItem:item
 completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
     XCTAssertNil(error,@"Error occurred during PutItem");
     item1Descriptor = newItemMetadata.descriptor;
     item1Metadata = newItemMetadata;
 }];
    
    
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     listener.didReceiveVaultItemMetadataExpectation = nil;
                                 }];
    
    XCTAssertNotNil(item1Descriptor);
    XCTAssertNotNil(item1Metadata);
    
    NSString *val = [item1Metadata objectForMetadataKey:@"key1"];
    XCTAssertTrue([val isEqualToString:testString],@"Incorrect metadata string");
    
    return item1Metadata;
}





-(QredoVaultItemMetadata *)updateVaultItem:(QredoVaultItem *)originalItem {
    QredoVault *vault = testClient1.defaultVault;
    
    NSString *testString = @"changed test";
    NSDictionary *item1SummaryValues = @{ @"key1":testString };
    QredoMutableVaultItemMetadata *updatedMetadata = [originalItem.metadata mutableCopy];
    
    [updatedMetadata setSummaryValue:testString forKey:@"key1"];
    
    
    
    
    TestVaultListener *listener = [[TestVaultListener alloc] init];
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener];
    
    
    __block QredoVaultItemMetadata *updatedItemMetadata = nil;
    
    
    [vault updateItem:updatedMetadata
                value:originalItem.value
    completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
        XCTAssertNotNil(newItemMetadata);
        updatedItemMetadata = newItemMetadata;
    }];
    
    
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     listener.didReceiveVaultItemMetadataExpectation = nil;
                                 }];
    
    XCTAssertNotNil(updatedItemMetadata);
    
    QredoVaultItemDescriptor *oldDescriptor = originalItem.metadata.descriptor;
    QredoVaultItemDescriptor *newDescriptor = updatedItemMetadata.descriptor;
    
    
    
    XCTAssertFalse([oldDescriptor isEqual:newDescriptor],@"Descriptors are the same");
    return updatedItemMetadata;
}


-(QredoVaultItemDescriptor *)deleteVaultItem:(QredoVaultItemMetadata *)originalMetadata {
    QredoVault *vault = testClient1.defaultVault;
    
    __block QredoVaultItemDescriptor *deleteItemDescriptor = nil;
    
    TestVaultListener *listener = [[TestVaultListener alloc] init];
    
    listener.didReceiveVaultItemMetadataExpectation = [self expectationWithDescription:@"Received the VaultItemMetadata"];
    [vault addVaultObserver:listener];
    
    
    [vault deleteItem:originalMetadata
    completionHandler:^(QredoVaultItemDescriptor *newItemDescriptor,NSError *error) {
        deleteItemDescriptor = newItemDescriptor;
    }];
    
    
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     listener.didReceiveVaultItemMetadataExpectation = nil;
                                 }];
    return deleteItemDescriptor;
}


-(int)countEnumAllVaultItemsOnServer {
    return [self countEnumAllVaultItemsOnServerFromWatermark:QredoVaultHighWatermarkOrigin];
}


-(int)countEnumAllVaultItemsOnServerFromWatermark:(QredoVaultHighWatermark *)highWatermark {
    QredoVault *vault = testClient1.defaultVault;
    __block int count = 0;
    __block NSMutableArray *enumArray = [[NSMutableArray alloc] init];
    __block XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    
    
    [vault enumerateVaultItemsAllVersionsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop) {
        count++;
    }
                                              since:highWatermark
                                  completionHandler:^(NSError *error) {
                                      [completionHandlerCalled fulfill];
                                      completionHandlerCalled = nil;
                                  }];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     completionHandlerCalled = nil;
                                 }];
    
    return count;
}


-(QredoVaultItem *)getVaultItem:(QredoVaultItemDescriptor *)descriptor {
    QredoVault *vault = testClient1.defaultVault;
    __block QredoVaultItem *returnVaultItem = nil;
    __block XCTestExpectation *completeExpectation = [self expectationWithDescription:@"getVaultItem"];
    
    
    [vault getItemWithDescriptor:descriptor
               completionHandler:^(QredoVaultItem *vaultItem,NSError *error) {
                   XCTAssertNil(error);
                   XCTAssertNotNil(vaultItem);
                   returnVaultItem = vaultItem;
                   [completeExpectation fulfill];
               }];
    [self waitForExpectationsWithTimeout:testTimeOut
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     completeExpectation = nil;
                                 }];
    
    return returnVaultItem;
}


/* Index */
-(int)countMetadataItemsInIndex {
    return 0;
}



-(void)buildFixedCredentialStack1 {
    [self createFixedClients];
    [self createRendezvous];
    [self respondToRendezvous];
}



-(void)buildStack1 {
    [self createRandomClients];
    [self createRendezvous];
    [self respondToRendezvous];
}


-(void)buildStack2 {
    [self createRandomClients];
    [self createRendezvous];
    [self respondToRendezvous];
    [self sendConversationMessageFrom1to2];
    [self sendConversationMessageFrom2to1];
}



@end
