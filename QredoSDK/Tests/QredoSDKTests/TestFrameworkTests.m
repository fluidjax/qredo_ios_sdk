/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"


@interface TestFrameworkTests :QredoXCTestCase

@end

@implementation TestFrameworkTests

-(void)setUp {
    [super setUp];
    
    //Put setup code here. This method is called before the invocation of each test method in the class.
    
    //In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    //UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
}


-(void)tearDown {
    //Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void)testStack1 {
    [self buildStack1];
}


-(void)testStack2 {
    [self buildStack2];
}


-(void)testHighwaterMark {
    [self createRandomClient1];
    QredoVault *vault = testClient1.defaultVault;
    
    //nothing in the vault
    XCTAssertTrue([self countEnumAllVaultItemsOnServer] == 0);
    //Highwater mark is nil
    XCTAssertNil(vault.highWatermark);
    
    
    
    [self createVaultItem];
    //1 item in the vault
    XCTAssertTrue([self countEnumAllVaultItemsOnServer] == 1);
    //water mark is now not nil
    XCTAssertNotNil(vault.highWatermark);
    
    //save a copy of the watermark
    QredoVaultHighWatermark *savedWaterMark = vault.highWatermark;
    
    
    //Add another vault item
    [self createVaultItem];
    
    //2 items in the vault
    XCTAssertTrue([self countEnumAllVaultItemsOnServer] == 2);
    
    //Count all items from current high water mark, should be 0 as we have a listener which is updating the Highwater mark internally
    XCTAssertTrue([self countEnumAllVaultItemsOnServerFromWatermark:vault.highWatermark] == 0);
    
    //1 new item since the saved water mark
    XCTAssertTrue([self countEnumAllVaultItemsOnServerFromWatermark:savedWaterMark] == 1);
    [self createVaultItem];
    //2 new item since the  saved water mark
    XCTAssertTrue([self countEnumAllVaultItemsOnServerFromWatermark:savedWaterMark] == 2);
    
    
    //Sanity checks
    //Still listener is receieving the incoming items and the internal HWM is up to date, so nothing to retirve
    XCTAssertTrue([self countEnumAllVaultItemsOnServerFromWatermark:vault.highWatermark] == 0);
    
    //Total number of items in vault
    XCTAssertTrue([self countEnumAllVaultItemsOnServer] == 3);
}


-(void)testConversationEnum {
    [self buildStack1];
    XCTAssertTrue([self countConversationsOnRendezvous:rendezvous1] == 1,@"Should be 1 conversation");
    XCTAssertTrue([self countConversationsOnClient:testClient2] == 1,@"Should be 1 conversation");
    [self createRendezvous];
    [self respondToRendezvous];
    XCTAssertTrue([self countConversationsOnRendezvous:rendezvous1] == 1,@"Should be 1 conversation");
    XCTAssertTrue([self countConversationsOnClient:testClient2] == 2,@"Should be 1 conversation");
}


-(void)testVault {
    [self createRandomClient1];
    XCTAssertTrue([self countEnumAllVaultItemsOnServer] == 0,@"Vault should be empty");
    
    QredoVaultItemMetadata *itemMetadata = [self createVaultItem];
    XCTAssertTrue([self countEnumAllVaultItemsOnServer] == 1,@"Vault should have 1 item");
    QredoVaultItem *item = [self getVaultItem:itemMetadata.descriptor];
    
    
    QredoVaultItemMetadata *updatedMetadata =  [self updateVaultItem:item];
    XCTAssertTrue([self countEnumAllVaultItemsOnServer] == 2,@"Vault should have 2 items");
    
    QredoVaultItemDescriptor *deletedDescriptor =  [self deleteVaultItem:updatedMetadata];
    XCTAssertTrue([self countEnumAllVaultItemsOnServer] == 3,@"Vault should have 3 items");
}


@end
