//
//  TestFrameworkTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 10/05/2016.
//
//

#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"


@interface TestFrameworkTests : QredoXCTestCase

@end

@implementation TestFrameworkTests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



-(void)testStack1{
    [self buildStack1];
}


-(void)testStack2{
    [self buildStack2];
}


#warning This is intentionally disabled but highlights an error not fixed by the 'saveToVault:NO' fix
// Line 648 QredoRendezvous.h -
// Fix before release
//
-(void)testConversationEnum{
    [self buildStack1];
    XCTAssertTrue([self countConversationsOnRendezvous:rendezvous1]==1,@"Should be 1 conversation");
    XCTAssertTrue([self countConversationsOnClient:testClient2]==1,@"Should be 1 conversation");
    
    [self createRendezvous];
    [self respondToRendezvous];
    
    
    XCTAssertTrue([self countConversationsOnRendezvous:rendezvous1]==1,@"Should be 1 conversation");
    XCTAssertTrue([self countConversationsOnClient:testClient2]==2,@"Should be 1 conversation");
    
    
}





-(void)testVault{
    [self createClient1];
    XCTAssertTrue([self countEnumAllVaultItemsOnServer]==0,@"Vault should be empty");
    
    QredoVaultItemMetadata *itemMetadata = [self createVaultItem];
    XCTAssertTrue([self countEnumAllVaultItemsOnServer]==1,@"Vault should have 1 item");
    QredoVaultItem *item = [self getVaultItem:itemMetadata.descriptor];
    
    
    QredoVaultItemMetadata *updatedMetadata =  [self updateVaultItem:item];
    XCTAssertTrue([self countEnumAllVaultItemsOnServer]==2,@"Vault should have 2 items");
    
    
    QredoVaultItemDescriptor *deletedDescriptor =  [self deleteVaultItem:updatedMetadata];
    XCTAssertTrue([self countEnumAllVaultItemsOnServer]==3,@"Vault should have 3 items");
    
    

}

@end
