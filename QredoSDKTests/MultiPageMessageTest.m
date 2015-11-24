//
//  MultiPageMessageTest.m
//  QredoSDK
//
//  Created by Christopher Morris on 20/11/2015.
//
//

#import <XCTest/XCTest.h>
#import "Qredo.h"

@interface MultiPageMessageTest : XCTestCase <QredoRendezvousObserver>

@end

@implementation MultiPageMessageTest

QredoClient *client1;
QredoClient *client2;
XCTestExpectation *incomingConversationExpectation;
QredoConversation *incomingConversation;
static int PAGING_SIZE = 5;



/* 
 Summary of enumerate methods
 
 Source Files of methods                             Status/notes                                   Which method tests functionality
 ----------------------------------------------------------------------------------------------------------------------------------
 
 Qredo.h - QredoClient
        enumerateAllRendezvousWithBlock         DONE uses enumerateAllVaultItemsUsingBlock      test Method testPagedRendezvous
 
 Qredo.h - QredoClient (Rendezvous)
        enumerateAllConversationsWithBlock      DONE uses enumerateAllVaultItemsUsingBlock
 
 QredoConversation - QredoConversation
        enumerateAllReceivedMessagesUsingBlock  DONE                                            test testPagedMessages
        enumerateAllSentMessagesUsingBlock      DONE                                            test testPagedMessages
 
 QredoRendezvous -
        enumerateConversationsWithBlock
        enumerateConversationsWithBlock         enumerateAllConversationsWithBlock              test testPagedConversations
 
QredoVault
        2x enumerateAllVaultItemsUsingBlock     DONE - user vaultServerAccess (below)           test testMultiplePagedVaultItems

QredoVaulServerAccess
        enumerateAllVaultItemsUsingBlock        DONE

 */
 



-(void)testPagedMessages{
    //create conversation
     NSString *tagName = [self randomStringWithLength:32];
    [self createRendezvousOnClient:client1 withTag:tagName];
    
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
    
    
    for (int i=0;i<PAGING_SIZE;i++){
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
    
    
    //Enumerate the message using the all in one (not paged method)
    __block XCTestExpectation *retrievePosts = [self expectationWithDescription:@"retrievePosts"];
    __block int messageCount=0;
    [testConversation enumerateAllSentMessagesUsingBlock:^(QredoConversationMessage *message, BOOL *stop) {
        NSString *messageText = [[NSString alloc] initWithData: message.value encoding: NSUTF8StringEncoding];
        NSLog(@"%@", messageText);
        messageCount++;
    } since:nil completionHandler:^(NSError *error) {
        NSLog(@"Retrieved all the messages");
        [retrievePosts fulfill];
    }];
     
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        retrievePosts = nil;
    }];
    
    XCTAssertTrue(messageCount==PAGING_SIZE,"Failure to retieve messages using Non Paged method - enumerateAllSentMessagesUsingBlock");
    
    //Enumerate the messages using the paged methods
    __block int count=0;
    __block QredoConversationHighWatermark *highWater = QredoConversationHighWatermarkOrigin;
    __block int pageSize=0;
    int lastCount=0;
    do{
        lastCount=count;
         __block XCTestExpectation *retrievePosts = [self expectationWithDescription:@"retrievePosts"];
        
        [testConversation enumerateSentMessagesUsingBlock:^(QredoConversationMessage *message, BOOL *stop) {
                        count++;
                        if (count>=pageSize)pageSize=count;
                        NSString *messageText = [[NSString alloc] initWithData: message.value encoding: NSUTF8StringEncoding];
                        NSLog(@"%i - %@",count, messageText);
                        highWater = message.highWatermark;
                    }
                    since:highWater
                    completionHandler:^(NSError *error) {
                                    [retrievePosts fulfill];
                    }];

        [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
            retrievePosts = nil;
        }];
    }while (count!=lastCount);
    XCTAssertTrue(count==PAGING_SIZE,"Failure to retieve messages using Paged method - enumerateSentMessagesUsingBlock");
    
    //Enumerate the received message using the all in one (not paged method)
    XCTAssertNotNil(incomingConversation,@"Primary client has no incoming conversation from client2's rendezvous publish");
    __block XCTestExpectation *recievedMessage = [self expectationWithDescription:@"recievedMessage"];
    __block int messageCountReceived=0;
    
    [incomingConversation enumerateAllReceivedMessagesUsingBlock:^(QredoConversationMessage *message, BOOL *stop) {
        NSString *messageText = [[NSString alloc] initWithData: message.value encoding: NSUTF8StringEncoding];
        NSLog(@"%@", messageText);
        messageCountReceived++;
    } since:nil completionHandler:^(NSError *error) {
        NSLog(@"Retrieved all the messages");
        [recievedMessage fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        recievedMessage = nil;
    }];
    
    XCTAssertTrue(messageCountReceived==PAGING_SIZE,"Failure to retieve recieved messages  using - enumerateAllSentMessagesUsingBlock");
}

-(void)testPagedRendezvous{
    for (int i=0;i<PAGING_SIZE;i++){
        NSLog(@"Create rendezvous %i",i);
        NSString *randomTag = [[QredoQUID QUID] QUIDString];
        [self createRendezvousOnClient:client1 withTag:randomTag];
    }
    
    //enumerate the rendezvous
    __block XCTestExpectation *didEnumerateComplete = [self expectationWithDescription:@"didEnumerateComplete"];
    __block int count = 0;
    
    [client1 enumerateAllRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
        XCTAssertNotNil(rendezvousMetadata.rendezvousRef);
        count++;
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(count, PAGING_SIZE);
        NSLog(@"Enumerated %i rendezvous", PAGING_SIZE);
        [didEnumerateComplete fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) {
        didEnumerateComplete = nil;
    }];
}


-(void)testPagedConversations{
    XCTAssertNotNil(client1);
    XCTAssertNotNil(client2);

    for (int i=0;i<PAGING_SIZE;i++){
        //create conversations
        NSLog(@"Iteration %i",i);
        
        NSString *tagName = [self randomStringWithLength:32];
        incomingConversation = nil;
        QredoConversation *newConversation=nil;
        
        [self createRendezvousOnClient:client1 withTag:tagName];
        newConversation = [self createConversationOnClient:client2 withTag:tagName];
        
        if (newConversation){
           [self createMessageOnConversation:incomingConversation];
           [self createMessageOnConversation:newConversation];
        }else{
            NSLog(@"Failed to get a conversation");
        }
    }
    
    //enumerate all conversations on client
    __block int count =0;
    __block XCTestExpectation *enumeateConv = [self expectationWithDescription:@"Enumerate conversations on client"];
    
    [client1 enumerateAllConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata, BOOL *stop) {
        count++;
    } completionHandler:^(NSError *error) {
        NSLog(@"Enumerated %i conversations", count);
        [enumeateConv fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        enumeateConv = nil;
    }];
    XCTAssertTrue(count==PAGING_SIZE,@"Failed to enumerate all the new messages");
}


-(void)testPagedVaultItems{
    for (int i=0;i<110;i++){
        NSLog(@"Iteration %i",i);
        [self enumerateVaultItems:i];
    }
}


- (void)enumerateVaultItems:(int)i{
    XCTAssertNotNil(client1);
    QredoVault *vault = [client1 defaultVault];
    XCTAssertNotNil(vault);
    
    // Create an item and store in vault
    NSString *testString = [NSString stringWithFormat:@"DATA %i",i];
    NSString *keyValue = [NSString stringWithFormat:@"KEYVALUE %i",i];
    
    NSData* item1Data = [testString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *item1SummaryValues = @{@"key1": keyValue,
                                         @"key2": @"value2",
                                         @"key3": @"value3"};
    
    QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithDataType:@"blob"
                                                                                                            accessLevel:0
                                                                                                          summaryValues:item1SummaryValues]
                                                                                                                  value:item1Data];
    __block QredoVaultItemDescriptor *item1Descriptor = nil;
    __block XCTestExpectation *putItemCompletedExpectation = [self expectationWithDescription:@"PutItem completion handler called"];
    
    [vault putItem:item1 completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
         XCTAssertNil(error, @"Error occurred during PutItem");
         item1Descriptor = newItemMetadata.descriptor;
         [putItemCompletedExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        putItemCompletedExpectation = nil;
    }];
    XCTAssertNotNil(item1Descriptor, @"Descriptor returned is nil");
    
    // Confirm the item is found in the vault
    __block XCTestExpectation *getItemCompletedExpectation = [self expectationWithDescription:@"GetItem completion handler called"];
    __block int getCount =0;
    [vault getItemWithDescriptor:item1Descriptor completionHandler:^(QredoVaultItem *vaultItem, NSError *error){
         getCount++;
         XCTAssertNil(error);
         XCTAssertNotNil(vaultItem);
         XCTAssert([vaultItem.value isEqualToData:item1Data]);
         [getItemCompletedExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        getItemCompletedExpectation = nil;
    }];
    
    // Confirm enumerate finds item we added
    __block BOOL itemFound = NO;
    __block XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    
    
    [vault enumerateAllVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        XCTAssertNotNil(vaultItemMetadata);
        if ([vaultItemMetadata.summaryValues[@"key1"] isEqual:keyValue]){
            itemFound = YES;
        }
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [completionHandlerCalled fulfill];
    }];
    
    // Note: May need a longer timeout if there's lots of items to enumerate. May depend on how many items added since test last run.
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        completionHandlerCalled = nil;
    }];
    
    XCTAssertTrue(itemFound, "Item just created was not found during enumeration.");
}


#pragma mark 
#pragma mark Utility Methods

-(void)authoriseClient{
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client1"];
    NSString  *randomPass = [self randomStringWithLength:32];
    
    [QredoClient initializeWithAppSecret:@"testAppSecret"                 //provided by qredo
                                  userId:@"testUserId"    //user email or username etc
                              userSecret:randomPass   //user entered password
                                 options:nil
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           client1 = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        clientExpectation = nil;
    }];
    
    
    __block XCTestExpectation *client2Expectation = [self expectationWithDescription:@"create client2"];
    NSString  *randomPass2 = [self randomStringWithLength:32];
    
    [QredoClient initializeWithAppSecret:@"testAppSecret"                 //provided by qredo
                                  userId:@"testUserId"    //user email or username etc
                              userSecret:randomPass2   //user entered password
                                 options:nil
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           client2 = clientArg;
                           [client2Expectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        client2Expectation = nil;
    }];
    
    
}



-(void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Incoming conversation");
        incomingConversation = conversation;
        [incomingConversationExpectation fulfill];
    });
    
    
}

- (void)setUp {
    [super setUp];
    [self authoriseClient];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



-(QredoConversation*)createConversationOnClient:(QredoClient*)qredoClient withTag:(NSString*)tagName{
    //respond to rendezvous by tag
    incomingConversationExpectation = [self expectationWithDescription:@"Wait for incoming Conversation"];
    
    __block QredoConversation *newConversation = nil;
    [qredoClient  respondWithTag:tagName
               completionHandler:^(QredoConversation *conversation, NSError *error) {
                   XCTAssertNotNil(conversation);
                   newConversation = conversation;
               }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        incomingConversationExpectation=nil;
    }];
    XCTAssertNotNil(newConversation);
    return newConversation;
}


-(QredoConversationHighWatermark*)createMessageOnConversation:(QredoConversation*)conversation{
    XCTAssertNotNil(conversation);
    __block QredoConversationHighWatermark *newMessageHighWatermark = nil;
    
    NSString *message = [[NSString alloc] initWithFormat:@"test message"];
    NSDictionary *messageSummaryValues = @{@"data": @"data"};
    QredoConversationMessage *conversationMessage = [[QredoConversationMessage alloc] initWithValue:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                                                           dataType: @"com.qredo.plaintext"
                                                                                      summaryValues: messageSummaryValues];
    
    __block XCTestExpectation *postExpectation = [self expectationWithDescription:@"post message"];
    
    [conversation publishMessage: conversationMessage completionHandler: ^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(messageHighWatermark);
        newMessageHighWatermark = messageHighWatermark;
        [postExpectation fulfill];
        NSLog(@"Sent message");
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        postExpectation = nil;
    }];
    
    return newMessageHighWatermark;
    
}


-(QredoRendezvous*)createRendezvousOnClient:(QredoClient*)qredoClient withTag:(NSString*)tagName{
    //create rendezvous
    QredoRendezvousConfiguration *rendezvousConfiguration =
    [[QredoRendezvousConfiguration alloc] initWithConversationType: @"com.qredo.epiq"
                                                   durationSeconds: 0
                                          isUnlimitedResponseCount: true ];
    
    
    __block XCTestExpectation *createRendezvous1Expectation = [self expectationWithDescription:@"Create rendezvous 1"];
    __block QredoRendezvous *newRendezvous = nil;
    
    [qredoClient createAnonymousRendezvousWithTag:tagName configuration:rendezvousConfiguration completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        XCTAssertNotNil(rendezvous);
        newRendezvous = rendezvous;
        [createRendezvous1Expectation fulfill];
        [newRendezvous addRendezvousObserver:self];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        createRendezvous1Expectation = nil;
    }];
    return newRendezvous;
}


-(NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}


@end
