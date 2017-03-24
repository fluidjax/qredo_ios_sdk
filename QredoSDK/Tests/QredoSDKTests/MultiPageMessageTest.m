/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoTestUtils.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"


@interface MultiPageMessageTest :QredoXCTestCase <QredoRendezvousObserver>
@end

@implementation MultiPageMessageTest

XCTestExpectation *incomingConversationExpectation;
QredoConversation *incomingConversation;
static int PAGING_SIZE = 2;  //server is set to 2, but 1 control message means only 1 actual data record returned
static int PAGING_SIZE_MODIFIER = 5; //added to PAGING_SIZE to make the enumerations bigger than a page


/*
 Summary of enumerate methods
 
 You should only run these tests when the server has a restricted number for the page size (eg.<5)
 The default page size is 50
 
 */

-(void)setUp{
    [super setUp];
    [self createRandomClients];
}


-(void)testPagedMessages {
    //create conversation
    
    NSString *tagName = [self randomStringWithLength:32];
    
    [self createRendezvousOnClient:testClient1 withTag:tagName];
    
    //respond to rendezvous by tag
    __block QredoConversation *testConversation = nil;
    __block XCTestExpectation *respondeToConversation1 = [self expectationWithDescription:@"Respond to Conversation1"];
    [testClient2 respondWithTag:tagName
          completionHandler:^(QredoConversation *conversation,NSError *error) {
              XCTAssertNotNil(conversation);
              testConversation = conversation;
              [respondeToConversation1 fulfill];
          }];
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     respondeToConversation1 = nil;
                                 }];
    
    for (int i = 0; i < PAGING_SIZE + PAGING_SIZE_MODIFIER; i++){
        NSString *message = [[NSString alloc] initWithFormat:@"test message %i",i];
        NSDictionary *messageSummaryValues = @{ @"data":@"data" };
        QredoConversationMessage *conversationMessage = [[QredoConversationMessage alloc]
                                                         initWithValue:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                         dataType:@"com.qredo.plaintext"
                                                         summaryValues:messageSummaryValues];
        
        __block XCTestExpectation *postExpectation = [self expectationWithDescription:@"post message"];
        [testConversation publishMessage:conversationMessage
                       completionHandler: ^(QredoConversationHighWatermark *messageHighWatermark,NSError *error) {
                           XCTAssertNil(error);
                           XCTAssertNotNil(messageHighWatermark);
                           [postExpectation fulfill];
                           QLog(@"Sent message");
                       }];
        [self waitForExpectationsWithTimeout:30
                                     handler:^(NSError *error) {
                                         postExpectation = nil;
                                     }];
    }
    
    //Enumerate the message using the all in one (not paged method)
    __block XCTestExpectation *retrievePosts1 = [self expectationWithDescription:@"retrievePosts"];
    __block int messageCount1 = 0;
    [testConversation enumerateSentMessagesUsingBlock:^(QredoConversationMessage *message,BOOL *stop) {
        QLog(@"%@",[[NSString alloc]                   initWithData:message.value
                                                           encoding:NSUTF8StringEncoding]);
        messageCount1++;
    }
                                                since:nil
                                    completionHandler:^(NSError *error) {
                                        QLog(@"Retrieved all the messages");
                                        [retrievePosts1 fulfill];
                                    }];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     retrievePosts1 = nil;
                                 }];
    
    XCTAssertTrue(messageCount1 == PAGING_SIZE + PAGING_SIZE_MODIFIER,"Failure to retieve messages using Non Paged method - enumerateSentMessagesUsingBlock");
}


-(void)testPagedRendezvous {
    for (int i = 0; i < PAGING_SIZE + PAGING_SIZE_MODIFIER; i++){
        QLog(@"Create rendezvous %i",i);
        NSString *randomTag = [[QredoQUID QUID] QUIDString];
        [self createRendezvousOnClient:testClient1 withTag:randomTag];
    }
    
    //enumerate the rendezvous using ALL
    __block XCTestExpectation *didEnumerateComplete2 = [self expectationWithDescription:@"didEnumerateComplete2"];
    __block int count2 = 0;
    
    [testClient1 enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata,BOOL *stop) {
        XCTAssertNotNil(rendezvousMetadata.rendezvousRef);
        QLog(@"TAG = %@",rendezvousMetadata.tag);
        count2++;
    }
                        completionHandler:^(NSError *error) {
                            XCTAssertNil(error);
                            [didEnumerateComplete2 fulfill];
                        }];
    
    [self waitForExpectationsWithTimeout:30.0
                                 handler:^(NSError *error) {
                                     didEnumerateComplete2 = nil;
                                 }];
    
    XCTAssertTrue(count2 == PAGING_SIZE + PAGING_SIZE_MODIFIER,"Failure to retrieve correct number of rendezvous using Non Paged Method - enumerateRendezvousWithBlock");
}


-(void)testPagedConversations {
    
    NSString *tagName = [self randomStringWithLength:32];
    [self createRendezvousOnClient:testClient1 withTag:tagName];
    
    for (int i = 0; i < PAGING_SIZE + PAGING_SIZE_MODIFIER; i++){
        incomingConversation = nil;
        QredoConversation *newConversation = nil;
        newConversation = [self createConversationOnClient:testClient2 withTag:tagName];
        [self createMessageOnConversation:newConversation];
    }
    
    //enumerate all conversations on client
    __block int count2 = 0;
    __block XCTestExpectation *enumeateConv2 = [self expectationWithDescription:@"Enumerate conversations on client"];
    
    [testClient2 enumerateConversationsWithBlock:^(QredoConversationMetadata *conversationMetadata,BOOL *stop) {
        count2++;
    }
                           completionHandler:^(NSError *error) {
                               QLog(@"Enumerated %i conversations",count2);
                               [enumeateConv2 fulfill];
                           }];
    
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     enumeateConv2 = nil;
                                 }];
    XCTAssertTrue(count2 == PAGING_SIZE + PAGING_SIZE_MODIFIER,@"Failed to enumerate all the new messages");
}


-(void)testPagedVaultItems {
    QredoVault *vault = [testClient1 defaultVault];
    
    XCTAssertNotNil(vault);
    
    for (int i = 0; i < PAGING_SIZE + PAGING_SIZE_MODIFIER; i++){
        //Create an item and store in vault
        NSString *testString = [NSString stringWithFormat:@"DATA %i",i];
        NSString *keyValue = [NSString stringWithFormat:@"KEYVALUE %i",i];
        
        NSData *item1Data = [testString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *item1SummaryValues = @{ @"key1":keyValue,
                                              @"key2":@"value2",
                                              @"key3":@"value3" };
        
        QredoVaultItem *item1 = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                                value:item1Data];
        __block QredoVaultItemDescriptor *item1Descriptor = nil;
        __block XCTestExpectation *putItemCompletedExpectation = [self expectationWithDescription:@"PutItem completion handler called"];
        
        [vault putItem:item1
     completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
         XCTAssertNil(error,@"Error occurred during PutItem");
         item1Descriptor = newItemMetadata.descriptor;
         [putItemCompletedExpectation fulfill];
     }];
        
        [self waitForExpectationsWithTimeout:30
                                     handler:^(NSError *error) {
                                         //avoiding exception when 'fulfill' is called after timeout
                                         putItemCompletedExpectation = nil;
                                     }];
        XCTAssertNotNil(item1Descriptor,@"Descriptor returned is nil");
    }
    
    //Confirm enumerate finds item we added
    __block int count1 = 0;
    __block XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"EnumerateVaultItems completion handler called"];
    
    
    [vault enumerateVaultItemsAllVersionsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop) {
        count1++;
    }
                                  completionHandler:^(NSError *error) {
                                      XCTAssertNil(error);
                                      [completionHandlerCalled fulfill];
                                  }];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     completionHandlerCalled = nil;
                                 }];
    
    XCTAssertTrue(count1 == PAGING_SIZE + PAGING_SIZE_MODIFIER,@"Failed to enumerate ALL the vault items");
}


#pragma mark
#pragma mark Utility Methods




-(void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation {
    //incomingConversation = conversation;
    //[incomingConversationExpectation fulfill];
}





-(QredoConversation *)createConversationOnClient:(QredoClient *)qredoClient withTag:(NSString *)tagName {
    //respond to rendezvous by tag
    
    XCTAssertNotNil(qredoClient);
    XCTAssertNotNil(tagName);
    
    
    incomingConversationExpectation = [self expectationWithDescription:@"Wait for incoming Conversation"];
    
    __block QredoConversation *newConversation = nil;
    [qredoClient respondWithTag:tagName
              completionHandler:^(QredoConversation *conversation,NSError *error) {
                  XCTAssertNotNil(conversation);
                  newConversation = conversation;
                  [incomingConversationExpectation fulfill];
              }];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *_Nullable error) {
                                     incomingConversationExpectation = nil;
                                 }];
    XCTAssertNotNil(newConversation);
    return newConversation;
}


-(QredoConversationHighWatermark *)createMessageOnConversation:(QredoConversation *)conversation {
    XCTAssertNotNil(conversation);
    __block QredoConversationHighWatermark *newMessageHighWatermark = nil;
    
    NSString *message = [[NSString alloc] initWithFormat:@"test message"];
    NSDictionary *messageSummaryValues = @{ @"data":@"data" };
    QredoConversationMessage *conversationMessage = [[QredoConversationMessage alloc] initWithValue:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                                                           dataType:@"com.qredo.plaintext"
                                                                                      summaryValues:messageSummaryValues];
    
    __block XCTestExpectation *postExpectation = [self expectationWithDescription:@"post message"];
    
    [conversation publishMessage:conversationMessage
               completionHandler: ^(QredoConversationHighWatermark *messageHighWatermark,NSError *error) {
                   XCTAssertNil(error);
                   XCTAssertNotNil(messageHighWatermark);
                   newMessageHighWatermark = messageHighWatermark;
                   [postExpectation fulfill];
                   QLog(@"Sent message");
               }];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     postExpectation = nil;
                                 }];
    
    return newMessageHighWatermark;
}


-(QredoRendezvous *)createRendezvousOnClient:(QredoClient *)qredoClient withTag:(NSString *)tagName {
    //create rendezvous
    XCTAssertNotNil(qredoClient);
    XCTAssertNotNil(tagName);

    
    __block XCTestExpectation *createRendezvous1Expectation = [self expectationWithDescription:@"Create rendezvous 1"];
    __block QredoRendezvous *newRendezvous = nil;
    
    [qredoClient createAnonymousRendezvousWithTag:tagName
                                         duration:0
                               unlimitedResponses:YES
     
                                completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                    XCTAssertNotNil(rendezvous);
                                    newRendezvous = rendezvous;
                                    [createRendezvous1Expectation fulfill];
                                    [newRendezvous addRendezvousObserver:self];
                                    [NSThread sleepForTimeInterval:0.1];
                                }];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error) {
                                     createRendezvous1Expectation = nil;
                                 }];
    return newRendezvous;
}


@end
