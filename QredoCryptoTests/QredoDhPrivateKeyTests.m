//
//  QredoPrivateKeyTests.m
//  QredoSDK
//
//  Created by David Hearn on 18/09/2014.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface QredoDhPrivateKeyTests : XCTestCase

@end

@implementation QredoDhPrivateKeyTests
//
//- (void)testInit
//{
//    uint8_t keyDataArray[] = {
//        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
//    };
//    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
//
//    
//    NSData *key1Data = [[NSData alloc] init];
//    NSData *key2Data = [[NSData alloc] init];
//    QredoPublicKey *publicKey = [[QredoPublicKey alloc] initWithData:key1Data];
//    QredoPrivateKey *privateKey = [[QredoPrivateKey alloc] initWithData:key2Data];
//    
//    QredoKeyPair *keyPair = [[QredoKeyPair alloc] initWithPublicKey:publicKey privateKey:privateKey];
//    
//    XCTAssertNotNil(keyPair, @"Key pair should not be nil.");
//    XCTAssertEqualObjects(publicKey, keyPair.publicKey, @"Public keys are different objects.");
//    XCTAssertEqualObjects(privateKey, keyPair.privateKey, @"Private keys are different objects.");
//}

@end
