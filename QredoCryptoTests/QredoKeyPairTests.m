//
//  QredoKeyPairTests.m
//  LinguaFranca-iOS
//
//  Created by David Hearn on 10/09/2014.
//  Copyright (c) 2014 Qredo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoKeyPair.h"

@interface QredoKeyPairTests : XCTestCase

@end

@implementation QredoKeyPairTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    QredoPublicKey *publicKey = [[QredoPublicKey alloc] init];
    QredoPrivateKey *privateKey = [[QredoPrivateKey alloc] init];
    
    QredoKeyPair *keyPair = [[QredoKeyPair alloc] initWithPublicKey:publicKey privateKey:privateKey];
    
    XCTAssertNotNil(keyPair, @"Key pair should not be nil.");
    XCTAssertEqualObjects(publicKey, keyPair.publicKey, @"Public keys are different objects.");
    XCTAssertEqualObjects(privateKey, keyPair.privateKey, @"Private keys are different objects.");
}

- (void)testInit_NilPublicKey
{
    QredoPublicKey *publicKey = nil;
    QredoPrivateKey *privateKey = [[QredoPrivateKey alloc] init];
    
    XCTAssertThrowsSpecificNamed([[QredoKeyPair alloc] initWithPublicKey:publicKey privateKey:privateKey], NSException, NSInvalidArgumentException, @"Nil public key but NSInvalidArgumentException not thrown.");
}


- (void)testInit_NilPrivateKey
{
    QredoPublicKey *publicKey = [[QredoPublicKey alloc] init];
    QredoPrivateKey *privateKey = nil;
    
    XCTAssertThrowsSpecificNamed([[QredoKeyPair alloc] initWithPublicKey:publicKey privateKey:privateKey], NSException, NSInvalidArgumentException, @"Nil private key but NSInvalidArgumentException not thrown.");
}
@end
