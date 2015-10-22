/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoEllipticCurvePoint.h"

@interface QredoEllipticCurvePointTests : XCTestCase

@end

@implementation QredoEllipticCurvePointTests

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
    NSData *data = [[NSData alloc] init];
    
    QredoEllipticCurvePoint *point = [[QredoEllipticCurvePoint alloc] initWithPointData:data];
    
    XCTAssertNotNil(point, @"Point should not be nil.");
    XCTAssertTrue([data isEqualToData:point.data], @"Point data differs.");
}

- (void)testInit_NilPointData
{
    NSData *data = nil;
    
    XCTAssertThrowsSpecificNamed([[QredoEllipticCurvePoint alloc] initWithPointData:data], NSException, NSInvalidArgumentException, @"Nil data but NSInvalidArgumentException not thrown.");
}

- (void)testPointWithData
{
    NSData *data = [[NSData alloc] init];
    
    QredoEllipticCurvePoint *point = [QredoEllipticCurvePoint pointWithData:data];
    
    XCTAssertNotNil(point, @"Point should not be nil.");
    XCTAssertTrue([data isEqualToData:point.data], @"Point data differs.");
}

- (void)testPointWithData_NilPointData
{
    NSData *data = nil;
    
    XCTAssertThrowsSpecificNamed([QredoEllipticCurvePoint pointWithData:data], NSException, NSInvalidArgumentException, @"Nil data but NSInvalidArgumentException not thrown.");
}

- (void)testMult
{
//    uint8_t bobPrivateKeyDataArray[] = {
//        0x5D,0xAB,0x08,0x7E,0x62,0x4A,0x8A,0x4B,0x79,0xE1,0x7F,0x8B,0x83,0x80,0x0E,0xE6,
//        0x6F,0x3B,0xB1,0x29,0x26,0x18,0xB6,0xFD,0x1C,0x2F,0x8B,0x27,0xFF,0x88,0xE0,0xEB
//    };
//    NSData *bobPrivateKeyData = [NSData dataWithBytes:bobPrivateKeyDataArray length:sizeof(bobPrivateKeyDataArray) / sizeof(uint8_t)];

    uint8_t bobPublicKeyDataArray[] = {
        0xDE,0x9E,0xDB,0x7D,0x7B,0x7D,0xC1,0xB4,0xD3,0x5B,0x61,0xC2,0xEC,0xE4,0x35,0x37,
        0x3F,0x83,0x43,0xC8,0x5B,0x78,0x67,0x4D,0xAD,0xFC,0x7E,0x14,0x6F,0x88,0x2B,0x4F
    };
    NSData *bobPublicKeyData = [NSData dataWithBytes:bobPublicKeyDataArray length:sizeof(bobPublicKeyDataArray) / sizeof(uint8_t)];
    
    uint8_t alicePrivateKeyDataArray[] = {
        0x77,0x07,0x6D,0x0A,0x73,0x18,0xA5,0x7D,0x3C,0x16,0xC1,0x72,0x51,0xB2,0x66,0x45,
        0xDF,0x4C,0x2F,0x87,0xEB,0xC0,0x99,0x2A,0xB1,0x77,0xFB,0xA5,0x1D,0xB9,0x2C,0x2A
    };
    NSData *alicePrivateKeyData = [NSData dataWithBytes:alicePrivateKeyDataArray length:sizeof(alicePrivateKeyDataArray) / sizeof(uint8_t)];
    
//    uint8_t alicePublicKeyDataArray[] = {
//        0x85,0x20,0xF0,0x09,0x89,0x30,0xA7,0x54,0x74,0x8B,0x7D,0xDC,0xB4,0x3E,0xF7,0x5A,
//        0x0D,0xBF,0x3A,0x0D,0x26,0x38,0x1A,0xF4,0xEB,0xA4,0xA9,0x8E,0xAA,0x9B,0x4E,0x6A
//    };
//    NSData *alicePublicKeyData = [NSData dataWithBytes:alicePublicKeyDataArray length:sizeof(alicePublicKeyDataArray) / sizeof(uint8_t)];
    
    uint8_t aliceMultBoxDataArray[] = {
        0x4A,0x5D,0x9D,0x5B,0xA4,0xCE,0x2D,0xE1,0x72,0x8E,0x3B,0xF4,0x80,0x35,0x0F,0x25,
        0xE0,0x7E,0x21,0xC9,0x47,0xD1,0x9E,0x33,0x76,0xF0,0x9B,0x3C,0x1E,0x16,0x17,0x42
    };
    NSData *aliceMultBoxData = [NSData dataWithBytes:aliceMultBoxDataArray length:sizeof(aliceMultBoxDataArray) / sizeof(uint8_t)];
    
    QredoEllipticCurvePoint *bobPublicKeyPoint = [QredoEllipticCurvePoint pointWithData:bobPublicKeyData];
    QredoEllipticCurvePoint *alicePrivateKeyPoint = [QredoEllipticCurvePoint pointWithData:alicePrivateKeyData];
    
    QredoEllipticCurvePoint *multResult = [bobPublicKeyPoint multiplyWithPoint:alicePrivateKeyPoint];
    XCTAssertNotNil(multResult, @"Mult result should not be nil.");
    XCTAssertTrue([aliceMultBoxData isEqualToData:multResult.data], @"Mult result data differs from expected result.");
}
@end
