//
//  MultiPageMessageTest.m
//  QredoSDK
//
//  Created by Christopher Morris on 20/11/2015.
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
static int PAGING_SIZE = 2;  //server is set to 2, but 1 control message means only 1 actual data record returned
static int PAGING_SIZE_MODIFIER = 5; //added to PAGING_SIZE to make the enumerations bigger than a page
static int CONTROL_MESSAGE =1;




/* 
 Summary of enumerate methods
 
    You should only run these tests when the server has a restricted number for the page size (eg.<5)
    The default page size is 50
 
 
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
    
    for (int i=0;i<PAGING_SIZE+PAGING_SIZE_MODIFIER;i++){
        NSString *message = [[NSString alloc] initWithFormat:@"test message %i",i];
        NSDictionary *messageSummaryValues = @{@"data": @"data"};
        QredoConversationMessage *conversationMessage = [[QredoConversationMessage alloc]
                                                         initWithValue:[message dataUsingEncoding:NSUTF8StringEncoding]
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
    __block XCTestExpectation *retrievePosts1 = [self expectationWithDescription:@"retrievePosts"];
    __block int messageCount1=0;
    [testConversation enumerateAllSentMessagesUsingBlock:^(QredoConversationMessage *message, BOOL *stop) {
        NSString *messageText = [[NSString alloc] initWithData: message.value encoding: NSUTF8StringEncoding];
        NSLog(@"%@", messageText);
        messageCount1++;
    } since:nil completionHandler:^(NSError *error) {
        NSLog(@"Retrieved all the messages");
        [retrievePosts1 fulfill];
    }];
     
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        retrievePosts1 = nil;
    }];
    
    XCTAssertTrue(messageCount1==PAGING_SIZE+PAGING_SIZE_MODIFIER,"Failure to retieve messages using Non Paged method - enumerateAllSentMessagesUsingBlock");

    
    
    //Enumerate the message using the page method
    __block XCTestExpectation *retrievePosts2 = [self expectationWithDescription:@"retrievePosts"];
    __block int messageCount2=0;
    [testConversation enumerateSentMessagesUsingBlock:^(QredoConversationMessage *message, BOOL *stop) {
        NSString *messageText = [[NSString alloc] initWithData: message.value encoding: NSUTF8StringEncoding];
        NSLog(@"%@", messageText);
        messageCount2++;
    } since:nil completionHandler:^(NSError *error) {
        NSLog(@"Retrieved all the messages");
        [retrievePosts2 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        retrievePosts2 = nil;
    }];
    
    XCTAssertTrue(messageCount2==PAGING_SIZE-CONTROL_MESSAGE,"Failure to retieve messages using Paged method - enumerateSentMessagesUsingBlock");


}


-(void)testPagedRendezvous{
    
    for (int i=0;i<PAGING_SIZE+PAGING_SIZE_MODIFIER;i++){
        NSLog(@"Create rendezvous %i",i);
        NSString *randomTag = [[QredoQUID QUID] QUIDString];
        [self createRendezvousOnClient:client1 withTag:randomTag];
    }
    
    //enumerate the rendezvous using PAGED
    __block XCTestExpectation *didEnumerateComplete1 = [self expectationWithDescription:@"didEnumerateComplete"];
    __block int count1 = 0;
    
    [client1 enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
        XCTAssertNotNil(rendezvousMetadata.rendezvousRef);
        count1++;
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [didEnumerateComplete1 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) {
        didEnumerateComplete1 = nil;
    }];
    XCTAssertTrue(count1==PAGING_SIZE-CONTROL_MESSAGE,"Failure to retrieve correct number of rendezvous using Paged Method - enumerateRendezvousWithBlock");
    
    //enumerate the rendezvous using ALL
    __block XCTestExpectation *didEnumerateComplete2 = [self expectationWithDescription:@"didEnumerateComplete2"];
    __block int count2 = 0;
    
    [client1 enumerateAllRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
        XCTAssertNotNil(rendezvousMetadata.rendezvousRef);
        NSLog(@"TAG = %@",rendezvousMetadata.tag);
        count2++;
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [didEnumerateComplete2 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) {
        didEnumerateComplete2 = nil;
    }];
    

    
    XCTAssertTrue(count2==PAGING_SIZE+PAGING_SIZE_MODIFIER,"Failure to retrieve correct number of rendezvous using Non Paged Method - enumerateAllRendezvousWithBlock");
    
    
}


-(void)testPagedConversations{
    XCTAssertNotNil(client1);
    XCTAssertNotNil(client2);

    NSString *tagName = [self randomStringWithLength:32];
    [self createRendezvousOnClient:client1 withTag:tagName];
    
    
    for (int i=0;i<PAGING_SIZE+PAGING_SIZE_MODIFIER;i++){
        incomingConversation = nil;
        QredoConversation *newConversation=nil;
        newConversation = [self createConversationOnClient:client2 withTag:tagName];
        [self createMessageOnConversation:newConversation];
    }
    
    //enumerate conversations on client
    __block int count1 =0;
    __block XCTestExpectation *enumeateConv1 = [self expectationWithDescription:@"Enumerate conversations on client"];
    
    [client2 enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata, BOOL *stop) {
        count1++;
    } completionHandler:^(NSError *error) {
        NSLog(@"Enumerated %i conversations", count1);
        [enumeateConv1 fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        enumeateConv1 = nil;
    }];
    XCTAssertTrue(count1==PAGING_SIZE-CONTROL_MESSAGE,@"Failed to enumerate all the new messages");
    
    
    
    //enumerate all conversations on client
    __block int count2 =0;
    __block XCTestExpectation *enumeateConv2 = [self expectationWithDescription:@"Enumerate conversations on client"];
    
    [client2 enumerateAllConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata, BOOL *stop) {
        count2++;
    } completionHandler:^(NSError *error) {
        NSLog(@"Enumerated %i conversations", count2);
        [enumeateConv2 fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        // avoiding exception when 'fulfill' is called after timeout
        enumeateConv2 = nil;
    }];
    XCTAssertTrue(count2==PAGING_SIZE+PAGING_SIZE_MODIFIER,@"Failed to enumerate all the new messages");
    
}


-(void)testPagedVaultItems{
    QredoVault *vault = [client1 defaultVault];
    XCTAssertNotNil(vault);


   for (int i=0;i<PAGING_SIZE+PAGING_SIZE_MODIFIER;i++){
    
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
   }
    
    // Confirm enumerate finds item we added
    __block int count1 =0;
    __block XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    
    
    [vault enumerateAllVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count1++;
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [completionHandlerCalled fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        completionHandlerCalled = nil;
    }];

    XCTAssertTrue(count1==PAGING_SIZE+PAGING_SIZE_MODIFIER,@"Failed to enumerate ALL the vault items");
    
    
    // Confirm enumerate finds item we added
    __block int count2 =0;
    __block XCTestExpectation *completionHandlerCalled2 = [self expectationWithDescription:@"EnumerateVaultItems completion handler called without paging"];
    
    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count2++;
    } completionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [completionHandlerCalled2 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        completionHandlerCalled2 = nil;
    }];
    
    //Vault doesnt use control message - so quantity is the same as page size
    XCTAssertTrue(count2==PAGING_SIZE,@"Failed to enumerate all the vault items using PAGING");
    
    
}


#pragma mark 
#pragma mark Utility Methods

-(void)authoriseClient{
    //Create two clients each with their own new random vaults
    
    __block XCTestExpectation *clientExpectation = [self expectationWithDescription:@"create client1"];
    NSString  *randomPass = [self randomStringWithLength:32];
    
    [QredoClient initializeWithAppSecret:@"cafebabe"
                                  userId:@"testUserId"
                              userSecret:randomPass
                                 options:nil
                       completionHandler:^(QredoClient *clientArg, NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(clientArg);
                           client1 = clientArg;
                           [clientExpectation fulfill];
                       }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        clientExpectation = nil;
    }];
    
    __block XCTestExpectation *client2Expectation = [self expectationWithDescription:@"create client2"];
    NSString  *randomPass2 = [self randomStringWithLength:32];
    
    [QredoClient initializeWithAppSecret:@"cafebabe"
                                  userId:@"testUserId"
                              userSecret:randomPass2
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
//        incomingConversation = conversation;
//        [incomingConversationExpectation fulfill];
}


- (void)setUp {
    [super setUp];
    [self authoriseClient];
}

- (void)tearDown {
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
                   [incomingConversationExpectation fulfill];
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
    QredoRendezvousConfiguration *rendezvousConfiguration =  [[QredoRendezvousConfiguration alloc]
                                                              initWithConversationType:@"com.qredo.epiq"
                                                                       durationSeconds:0
                                                              isUnlimitedResponseCount:true];
    
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
