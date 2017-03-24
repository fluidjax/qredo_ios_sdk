//
//  ObjectSerialization.m
//  QredoSDK
//
//  Created by Christopher Morris on 04/10/2016.
//  Testing put (serializaing) & get (deserialize) RendezvousRef & ConversationRef & VaultItemRef into summmary values
//

#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"

@interface ObjectSerialization : QredoXCTestCase

@end

@implementation ObjectSerialization

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void)testFailingDeserialization{
    [self buildStack1];
    NSString *randomConversationRef = @"KDc6YgAAAAMAADc6YgAAAAMAACgxOkMxMzonVmF1bHRJdGVtUmVmKDc6J2l0ZW1JZDMzOlFHAP5HGUxAHYrrcrX35dRYmVETu5nWTxCWCvd/B41kyykoMTE6J3NlcXVlbmNlSWQzMzpRiyD1CeIMRV6SLP0/GP2IBGJvGO4CaEOFleKI2bKoNz8pKDE0OidzZXF1ZW5jZVZhbHVlOTpJAAAAAAAACIwpKDg6J3ZhdWx0SWQzMzpRVwKhr0iOi5Ds4Kw4xO3ro6EYXj5wkTlbsQSYoixqkrIpKSk=";
    XCTAssertNotNil(conversation1);
    NSString *serializedConversationRef = [conversation1.metadata.conversationRef serializedString];
    QredoConversationRef *convRef = [[QredoConversationRef alloc] initWithSerializedString:serializedConversationRef];
    XCTAssertFalse([randomConversationRef isEqual:convRef],@"these shouldnt be the same");
}



-(void)testPassingConversationRefDeserialization{
    [self buildStack1];
    XCTAssertNotNil(conversation1);
    NSString *serializedConversationRef = [conversation1.metadata.conversationRef serializedString];
    QredoConversationRef *convRef = [[QredoConversationRef alloc] initWithSerializedString:serializedConversationRef];
    XCTAssertTrue([convRef isEqual:conversation1.metadata.conversationRef],@"serialization / deserialization values are not the same");
}


-(void)testPassingRendezvousRefDeserialization{
    [self buildStack1];
    XCTAssertNotNil(rendezvous1);
    
    NSString *serializedRendezvousRef = [rendezvous1.metadata.rendezvousRef serializedString];
    QredoRendezvousRef *rendRef = [[QredoRendezvousRef alloc] initWithSerializedString:serializedRendezvousRef];
    
    XCTAssertTrue([rendRef isEqual:rendezvous1.metadata.rendezvousRef],@"serialization / deserialization values are not the same");
}



/*
-(void)testConversationRefSerialization{
    [self buildStack1];
    
    XCTAssertNotNil(conversation1);
    
    NSString *serializedConversationRef = [conversation1.metadata.conversationRef serializedString];
    
    QredoConversationRef *convRef = [[QredoConversationRef alloc] initWithSerializedString:serializedConversationRef];
    
    XCTAssertTrue([convRef isEqual:conversation1.metadata.conversationRef],@"serialization / deserialization values are not the same");
    
    QredoVault *vault = testClient1.defaultVault;
    NSData *item1Data = [QredoUtils randomBytesOfLength:64];
    NSDictionary *item1SummaryValues = @{ @"key1":@"teststring",
                                          @"convRef":conversation1.metadata.conversationRef};
    
    QredoVaultItem *item = [QredoVaultItem vaultItemWithMetadata:[QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:item1SummaryValues]
                                                           value:item1Data];
    
    
    __block XCTestExpectation *putExpectation =  [self expectationWithDescription:@"Put item in vault"];
    
    
    [vault putItem:item completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
        XCTAssertNotNil(newItemMetadata);
    }];
    
    
    [self waitForExpectationsWithTimeout:30  handler:^(NSError *error) {
        putExpectation=nil;
    }];

    
    
}
 */

@end
