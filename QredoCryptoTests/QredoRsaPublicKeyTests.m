/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoRsaPublicKey.h"
#import "QredoCrypto.h"

@interface QredoRsaPublicKeyTests : XCTestCase

@end

@implementation QredoRsaPublicKeyTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // Must remove any existing keys before starting
    [QredoCrypto deleteAllKeysInAppleKeychain];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    // Must remove any keys after completing
    [QredoCrypto deleteAllKeysInAppleKeychain];
}

- (void)testInitWithPkcs1KeyData
{
    uint8_t keyDataArray[] = {0x30,0x81,0x89,0x02,0x81,0x81,0x00,0xBA,0x47,0x16,0xD7,0x9F,0x8D,0xAC,0x73,0xA7,0xD6,0xEE,0x3E,0x44,0xCB,0x5C,0xCE,0xBB,0xFD,0xDE,0x36,0xD6,0x7F,0x53,0xA5,0xEF,0x67,0x4E,0x79,0x43,0xFF,0x13,0xED,0x63,0xA7,0x9F,0x92,0x4D,0x28,0x4B,0x84,0xC5,0xFE,0xF2,0xB5,0xFA,0x0B,0x16,0x8B,0xEB,0x81,0x1C,0xB2,0x72,0x16,0x50,0x3E,0x18,0x6F,0x8B,0xC7,0xA3,0x12,0x2D,0x78,0x24,0xDF,0x6F,0x0D,0x27,0x4E,0x57,0xF7,0x84,0xB4,0x18,0x5B,0xD7,0x97,0x54,0x59,0x11,0x80,0x9E,0x1C,0x79,0x7C,0xE9,0x44,0x8D,0x26,0xA4,0x2D,0x45,0x84,0x7A,0xB9,0x17,0x71,0xEE,0x06,0x37,0x33,0xA9,0x9E,0x10,0xCD,0x78,0x38,0xEC,0x35,0xB7,0xF8,0x75,0x4A,0x8F,0x91,0x14,0xDD,0xEF,0xDC,0x7A,0x90,0x20,0x3F,0x71,0x7C,0x3D,0x17,0x02,0x03,0x01,0x00,0x01};
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];

    uint8_t expectedModulusDataArray[] = {0x00,0xBA,0x47,0x16,0xD7,0x9F,0x8D,0xAC,0x73,0xA7,0xD6,0xEE,0x3E,0x44,0xCB,0x5C,0xCE,0xBB,0xFD,0xDE,0x36,0xD6,0x7F,0x53,0xA5,0xEF,0x67,0x4E,0x79,0x43,0xFF,0x13,0xED,0x63,0xA7,0x9F,0x92,0x4D,0x28,0x4B,0x84,0xC5,0xFE,0xF2,0xB5,0xFA,0x0B,0x16,0x8B,0xEB,0x81,0x1C,0xB2,0x72,0x16,0x50,0x3E,0x18,0x6F,0x8B,0xC7,0xA3,0x12,0x2D,0x78,0x24,0xDF,0x6F,0x0D,0x27,0x4E,0x57,0xF7,0x84,0xB4,0x18,0x5B,0xD7,0x97,0x54,0x59,0x11,0x80,0x9E,0x1C,0x79,0x7C,0xE9,0x44,0x8D,0x26,0xA4,0x2D,0x45,0x84,0x7A,0xB9,0x17,0x71,0xEE,0x06,0x37,0x33,0xA9,0x9E,0x10,0xCD,0x78,0x38,0xEC,0x35,0xB7,0xF8,0x75,0x4A,0x8F,0x91,0x14,0xDD,0xEF,0xDC,0x7A,0x90,0x20,0x3F,0x71,0x7C,0x3D,0x17};
    NSData *expectedModulusData = [NSData dataWithBytes:expectedModulusDataArray length:sizeof(expectedModulusDataArray) / sizeof(uint8_t)];
    
    uint8_t expectedPublicExponentDataArray[] = {0x01,0x00,0x01};
    NSData *expectedPublicExponentData = [NSData dataWithBytes:expectedPublicExponentDataArray length:sizeof(expectedPublicExponentDataArray) / sizeof(uint8_t)];
    
    QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithPkcs1KeyData:keyData];

    XCTAssertNotNil(publicKey, @"Public key should not be nil.");
    XCTAssertTrue([publicKey.modulus isEqualToData:expectedModulusData], @"Modulus is incorrect.");
    XCTAssertTrue([publicKey.publicExponent isEqualToData:expectedPublicExponentData], @"Public exponent is incorrect.");
}

-(void)testInitWithPkcs1KeyData_GeneratedPkcs1KeyData
{
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKeyExport1";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKeyExport1";
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits
                                                         publicKeyIdentifier:publicKeyIdentifier
                                                        privateKeyIdentifier:privateKeyIdentifier
                                                      persistInAppleKeychain:YES];
    XCTAssertNotNil(keyPairRef, "RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef, "RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef, "RSA key generation failed (nil private key ref returned).");
    
    NSData *keyData = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithPkcs1KeyData:keyData];
    XCTAssertNotNil(publicKey, @"Public key should not be nil.");
    XCTAssertNotNil(publicKey.modulus, @"Modulus should not be nil.");
    XCTAssertNotNil(publicKey.publicExponent, @"Public exponent should not be nil.");
}

-(void)testInitWithPkcs1KeyData_ManualKeyDataFromBouncyCastle
{
    uint8_t keyDataArray[] = {0x30,0x81,0x89,0x02,0x81,0x81,0x00,0x95,0x65,0xC9,0xBC,0xB8,0xC1,0xEC,0x9A,0xA7,0x1B,0x3B,0x54,0x84,0x30,0x0A,0x8A,0xF1,0xBC,0x78,0x28,0x4C,0x90,0xCB,0xCD,0x61,0x8D,0x38,0xAD,0xEA,0xC3,0xA3,0x4B,0x42,0x89,0xD6,0x65,0x1B,0xF7,0x1C,0x07,0xE9,0x16,0x82,0x1A,0x59,0x8A,0x64,0xC1,0x1F,0x6E,0x3B,0xAB,0x58,0x3A,0xDA,0x04,0xB2,0xA4,0x97,0x4C,0xEE,0x54,0xAE,0xBB,0xEF,0xF5,0xE1,0x9D,0x66,0x82,0x07,0x8C,0x41,0x6C,0xC2,0x30,0x42,0x2A,0xE2,0xD2,0x38,0x32,0x84,0x63,0xCA,0x4A,0xF4,0xF9,0xE8,0x8D,0xBE,0xE5,0x18,0x84,0xC2,0xD0,0x97,0x8E,0xD5,0x4F,0x61,0x73,0x77,0xD4,0x0E,0x1C,0xD2,0x4D,0x2A,0x34,0xCF,0xFA,0x17,0x21,0x04,0xDE,0xF7,0xE3,0x32,0x55,0xDF,0xAB,0x31,0x44,0xD6,0xAE,0x6D,0xA3,0x02,0x03,0x01,0x00,0x01};
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithPkcs1KeyData:keyData];
    XCTAssertNotNil(publicKey, @"Public key should not be nil.");
    XCTAssertNotNil(publicKey.modulus, @"Modulus should not be nil.");
    XCTAssertNotNil(publicKey.publicExponent, @"Public exponent should not be nil.");
}

-(void)testInitWithX509KeyData_KeyDataFromBouncyCastle
{
    uint8_t keyDataArray[] = {0x30,0x81,0x9F,0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x01,0x05,0x00,0x03,0x81,0x8D,0x00,0x30,0x81,0x89,0x02,0x81,0x81,0x00,0xD3,0x1C,0x61,0x7C,0xCC,0x1F,0x10,0x5C,0x06,0xA1,0xB5,0x77,0x34,0xAB,0x99,0x4E,0x1F,0x5F,0xA5,0x0D,0xFC,0x2C,0x4F,0x76,0x5E,0x58,0x7B,0x82,0xB0,0x76,0xEB,0x58,0x0C,0x7F,0xED,0xE3,0xF1,0xD9,0xD3,0xEB,0x48,0x81,0x70,0x04,0x68,0xEC,0x11,0xB8,0x70,0x79,0xEB,0x51,0xE5,0x09,0x82,0x15,0x57,0x93,0x29,0x83,0x0F,0x30,0xD7,0xD3,0x8A,0x48,0x1F,0x57,0x2D,0xB3,0x75,0xC1,0x40,0xB5,0xB2,0x72,0x14,0xF0,0xE8,0xB6,0x69,0x4D,0x70,0x8D,0x4D,0x12,0x02,0x0A,0x8B,0xA6,0xBE,0xCA,0x11,0x87,0x76,0x6D,0x7A,0x99,0x81,0x8A,0x0A,0xB7,0x56,0x0A,0x51,0xCA,0x4E,0x9F,0xD7,0x62,0xF7,0x03,0x78,0x54,0x22,0xBE,0x58,0xE3,0xDF,0xE1,0x76,0x3B,0xCC,0x66,0xA6,0x50,0x99,0xED,0x02,0x03,0x01,0x00,0x01};
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithX509KeyData:keyData];
    XCTAssertNotNil(publicKey, @"Public key should not be nil.");
    XCTAssertNotNil(publicKey.modulus, @"Modulus should not be nil.");
    XCTAssertNotNil(publicKey.publicExponent, @"Public exponent should not be nil.");
}

- (void)testInitWithModulus
{
    uint8_t modulusDataArray[] = {0x00,0xBA,0x47,0x16,0xD7,0x9F,0x8D,0xAC,0x73,0xA7,0xD6,0xEE,0x3E,0x44,0xCB,0x5C,0xCE,0xBB,0xFD,0xDE,0x36,0xD6,0x7F,0x53,0xA5,0xEF,0x67,0x4E,0x79,0x43,0xFF,0x13,0xED,0x63,0xA7,0x9F,0x92,0x4D,0x28,0x4B,0x84,0xC5,0xFE,0xF2,0xB5,0xFA,0x0B,0x16,0x8B,0xEB,0x81,0x1C,0xB2,0x72,0x16,0x50,0x3E,0x18,0x6F,0x8B,0xC7,0xA3,0x12,0x2D,0x78,0x24,0xDF,0x6F,0x0D,0x27,0x4E,0x57,0xF7,0x84,0xB4,0x18,0x5B,0xD7,0x97,0x54,0x59,0x11,0x80,0x9E,0x1C,0x79,0x7C,0xE9,0x44,0x8D,0x26,0xA4,0x2D,0x45,0x84,0x7A,0xB9,0x17,0x71,0xEE,0x06,0x37,0x33,0xA9,0x9E,0x10,0xCD,0x78,0x38,0xEC,0x35,0xB7,0xF8,0x75,0x4A,0x8F,0x91,0x14,0xDD,0xEF,0xDC,0x7A,0x90,0x20,0x3F,0x71,0x7C,0x3D,0x17};
    NSData *modulusData = [NSData dataWithBytes:modulusDataArray length:sizeof(modulusDataArray) / sizeof(uint8_t)];
    
    uint8_t publicExponentDataArray[] = {0x01,0x00,0x01};
    NSData *publicExponentData = [NSData dataWithBytes:publicExponentDataArray length:sizeof(publicExponentDataArray) / sizeof(uint8_t)];
    
    QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithModulus:modulusData publicExponent:publicExponentData];
    
    XCTAssertNotNil(publicKey, @"Public key should not be nil.");
    XCTAssertTrue([publicKey.modulus isEqualToData:modulusData], @"Modulus is incorrect.");
    XCTAssertTrue([publicKey.publicExponent isEqualToData:publicExponentData], @"Public exponent is incorrect.");
}

- (void)testConvertToPkcs1Format_FromPkcs1Data
{
    // Initialise with PKCS#1 data, and then convert to PKCS#1 data.  Data elements should be the same
    
    uint8_t keyDataArray[] = {0x30,0x81,0x89,0x02,0x81,0x81,0x00,0x95,0x65,0xC9,0xBC,0xB8,0xC1,0xEC,0x9A,0xA7,0x1B,0x3B,0x54,0x84,0x30,0x0A,0x8A,0xF1,0xBC,0x78,0x28,0x4C,0x90,0xCB,0xCD,0x61,0x8D,0x38,0xAD,0xEA,0xC3,0xA3,0x4B,0x42,0x89,0xD6,0x65,0x1B,0xF7,0x1C,0x07,0xE9,0x16,0x82,0x1A,0x59,0x8A,0x64,0xC1,0x1F,0x6E,0x3B,0xAB,0x58,0x3A,0xDA,0x04,0xB2,0xA4,0x97,0x4C,0xEE,0x54,0xAE,0xBB,0xEF,0xF5,0xE1,0x9D,0x66,0x82,0x07,0x8C,0x41,0x6C,0xC2,0x30,0x42,0x2A,0xE2,0xD2,0x38,0x32,0x84,0x63,0xCA,0x4A,0xF4,0xF9,0xE8,0x8D,0xBE,0xE5,0x18,0x84,0xC2,0xD0,0x97,0x8E,0xD5,0x4F,0x61,0x73,0x77,0xD4,0x0E,0x1C,0xD2,0x4D,0x2A,0x34,0xCF,0xFA,0x17,0x21,0x04,0xDE,0xF7,0xE3,0x32,0x55,0xDF,0xAB,0x31,0x44,0xD6,0xAE,0x6D,0xA3,0x02,0x03,0x01,0x00,0x01};
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithPkcs1KeyData:keyData];
    XCTAssertNotNil(publicKey, @"Public key should not be nil.");
    XCTAssertNotNil(publicKey.modulus, @"Modulus should not be nil.");
    XCTAssertNotNil(publicKey.publicExponent, @"Public exponent should not be nil.");

    NSData *pkcs1Data = [publicKey convertToPkcs1Format];
    XCTAssertNotNil(pkcs1Data, @"PKCS#1 data should not be nil.");
    XCTAssertTrue([pkcs1Data isEqualToData:keyData], @"PKCS#1 data is incorrect.");
}

- (void)testConvertToPkcs1Format_FromKeyComponents
{
    // Initialise with key components and then convert to PKCS#1 data.
    
    uint8_t modulusDataArray[] = {0x00,0xBA,0x47,0x16,0xD7,0x9F,0x8D,0xAC,0x73,0xA7,0xD6,0xEE,0x3E,0x44,0xCB,0x5C,0xCE,0xBB,0xFD,0xDE,0x36,0xD6,0x7F,0x53,0xA5,0xEF,0x67,0x4E,0x79,0x43,0xFF,0x13,0xED,0x63,0xA7,0x9F,0x92,0x4D,0x28,0x4B,0x84,0xC5,0xFE,0xF2,0xB5,0xFA,0x0B,0x16,0x8B,0xEB,0x81,0x1C,0xB2,0x72,0x16,0x50,0x3E,0x18,0x6F,0x8B,0xC7,0xA3,0x12,0x2D,0x78,0x24,0xDF,0x6F,0x0D,0x27,0x4E,0x57,0xF7,0x84,0xB4,0x18,0x5B,0xD7,0x97,0x54,0x59,0x11,0x80,0x9E,0x1C,0x79,0x7C,0xE9,0x44,0x8D,0x26,0xA4,0x2D,0x45,0x84,0x7A,0xB9,0x17,0x71,0xEE,0x06,0x37,0x33,0xA9,0x9E,0x10,0xCD,0x78,0x38,0xEC,0x35,0xB7,0xF8,0x75,0x4A,0x8F,0x91,0x14,0xDD,0xEF,0xDC,0x7A,0x90,0x20,0x3F,0x71,0x7C,0x3D,0x17};
    NSData *modulusData = [NSData dataWithBytes:modulusDataArray length:sizeof(modulusDataArray) / sizeof(uint8_t)];
    
    uint8_t publicExponentDataArray[] = {0x01,0x00,0x01};
    NSData *publicExponentData = [NSData dataWithBytes:publicExponentDataArray length:sizeof(publicExponentDataArray) / sizeof(uint8_t)];
    
    uint8_t expectedPkcs1DataArray[] = {0x30,0x81,0x89,0x02,0x81,0x81,0x00,0xBA,0x47,0x16,0xD7,0x9F,0x8D,0xAC,0x73,0xA7,0xD6,0xEE,0x3E,0x44,0xCB,0x5C,0xCE,0xBB,0xFD,0xDE,0x36,0xD6,0x7F,0x53,0xA5,0xEF,0x67,0x4E,0x79,0x43,0xFF,0x13,0xED,0x63,0xA7,0x9F,0x92,0x4D,0x28,0x4B,0x84,0xC5,0xFE,0xF2,0xB5,0xFA,0x0B,0x16,0x8B,0xEB,0x81,0x1C,0xB2,0x72,0x16,0x50,0x3E,0x18,0x6F,0x8B,0xC7,0xA3,0x12,0x2D,0x78,0x24,0xDF,0x6F,0x0D,0x27,0x4E,0x57,0xF7,0x84,0xB4,0x18,0x5B,0xD7,0x97,0x54,0x59,0x11,0x80,0x9E,0x1C,0x79,0x7C,0xE9,0x44,0x8D,0x26,0xA4,0x2D,0x45,0x84,0x7A,0xB9,0x17,0x71,0xEE,0x06,0x37,0x33,0xA9,0x9E,0x10,0xCD,0x78,0x38,0xEC,0x35,0xB7,0xF8,0x75,0x4A,0x8F,0x91,0x14,0xDD,0xEF,0xDC,0x7A,0x90,0x20,0x3F,0x71,0x7C,0x3D,0x17,0x02,0x03,0x01,0x00,0x01};
    NSData *expectedPkcs1Data = [NSData dataWithBytes:expectedPkcs1DataArray length:sizeof(expectedPkcs1DataArray) / sizeof(uint8_t)];
    
    QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithModulus:modulusData publicExponent:publicExponentData];
    XCTAssertNotNil(publicKey, @"Public key should not be nil.");
    
    NSData *pkcs1Data = [publicKey convertToPkcs1Format];
    XCTAssertNotNil(pkcs1Data, @"PKCS#1 data should not be nil.");
    XCTAssertTrue([pkcs1Data isEqualToData:expectedPkcs1Data], @"PKCS#1 data is incorrect.");
}

- (void)testConvertToX509Format_FromX509Data
{
    // Initialise with X509 data, and then convert to X509 data.  Data elements should be the same
    
    uint8_t keyDataArray[] = {0x30,0x81,0x9F,0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x01,0x05,0x00,0x03,0x81,0x8D,0x00,0x30,0x81,0x89,0x02,0x81,0x81,0x00,0xD3,0x1C,0x61,0x7C,0xCC,0x1F,0x10,0x5C,0x06,0xA1,0xB5,0x77,0x34,0xAB,0x99,0x4E,0x1F,0x5F,0xA5,0x0D,0xFC,0x2C,0x4F,0x76,0x5E,0x58,0x7B,0x82,0xB0,0x76,0xEB,0x58,0x0C,0x7F,0xED,0xE3,0xF1,0xD9,0xD3,0xEB,0x48,0x81,0x70,0x04,0x68,0xEC,0x11,0xB8,0x70,0x79,0xEB,0x51,0xE5,0x09,0x82,0x15,0x57,0x93,0x29,0x83,0x0F,0x30,0xD7,0xD3,0x8A,0x48,0x1F,0x57,0x2D,0xB3,0x75,0xC1,0x40,0xB5,0xB2,0x72,0x14,0xF0,0xE8,0xB6,0x69,0x4D,0x70,0x8D,0x4D,0x12,0x02,0x0A,0x8B,0xA6,0xBE,0xCA,0x11,0x87,0x76,0x6D,0x7A,0x99,0x81,0x8A,0x0A,0xB7,0x56,0x0A,0x51,0xCA,0x4E,0x9F,0xD7,0x62,0xF7,0x03,0x78,0x54,0x22,0xBE,0x58,0xE3,0xDF,0xE1,0x76,0x3B,0xCC,0x66,0xA6,0x50,0x99,0xED,0x02,0x03,0x01,0x00,0x01};
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithX509KeyData:keyData];
    XCTAssertNotNil(publicKey, @"Public key should not be nil.");
    
    NSData *pkcs1Data = [publicKey convertToX509Format];
    XCTAssertNotNil(pkcs1Data, @"X509 data should not be nil.");
    XCTAssertTrue([pkcs1Data isEqualToData:keyData], @"X509 data is incorrect.");
}
@end
