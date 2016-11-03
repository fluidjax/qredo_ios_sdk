/* HEADER GOES HERE */
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoCrypto.h"
#import <CommonCrypto/CommonCrypto.h>
#import "rsapss.h"
#import "QredoRsaPublicKey.h"
#import "QredoCertificateUtils.h"
#import "TestCertificates.h"
#import "QredoLoggerPrivate.h"

@interface QredoCryptoTests :XCTestCase

@end

@implementation QredoCryptoTests

-(void)setUp {
    [super setUp];
    
    //Must remove any existing keys before starting
    [QredoCrypto deleteAllKeysInAppleKeychain];
}


-(void)tearDown {
    //Must remove any keys after completing
    [QredoCrypto deleteAllKeysInAppleKeychain];
    
    [super tearDown];
}


-(void)testDecryptData128BitKey {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t ivDataArray[] = {
        0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    uint8_t encryptedDataArray[] = {
        0x1d,0xb8,0x50,0x74,0xaf,0xc3,0x4d,0x73,0x16,0x85,0x3c,0x12,0x22,0xda,0x2b,0x4d,
        0xba,0xf2,0x5b,0xd3,0xfe,0xe0,0x17,0x43,0xce,0x65,0x72,0x6c,0xe6,0xf8,0x4f,0x8a,
        0x7a,0xdb,0x7e,0xed,0x0d,0x5e,0x00,0x98,0x30,0x89,0xa2,0xfc,0x47,0x25,0xfa,0x88,
        0x5c,0x19,0x9a,0x80,0xa3,0x3d,0xc9,0x96,0xeb,0x3f,0x73,0x5b,0x7e,0x22,0xd8,0x5f
    };
    NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
    
    NSString *expectedString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *expectedData = [expectedString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSData *decryptedData = [QredoCrypto decryptData:encryptedData withAesKey:keyData iv:ivData];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue([expectedData isEqualToData:decryptedData],@"Decrypted data incorrect.");
}

/* AES now only supports 128b keys
-(void)testDecryptData256BitKey {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t ivDataArray[] = {
        0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    uint8_t encryptedDataArray[] = {
        0xCA,0x20,0x92,0x99,0xC2,0xFD,0x06,0xF2,0x74,0xDA,0xA1,0x87,0x74,0x11,0x45,0xC5,
        0x86,0xF6,0xE1,0x52,0xB3,0x31,0xC4,0x07,0x43,0xC9,0x2A,0xCC,0x82,0x86,0x84,0x2E,
        0x0B,0x56,0x93,0xF4,0xE3,0x67,0x3F,0x40,0x1C,0x93,0x7F,0x8C,0xB3,0xC3,0x8D,0xEA,
        0x2C,0xBA,0x0E,0x7F,0x5B,0x0C,0x3D,0xF6,0xEC,0xDC,0x00,0xE6,0xDB,0x36,0xDB,0x5A
    };
    NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
    
    NSString *expectedString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *expectedData = [expectedString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSData *decryptedData = [QredoCrypto decryptData:encryptedData withAesKey:keyData iv:ivData];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue([expectedData isEqualToData:decryptedData],@"Decrypted data incorrect.");
}


-(void)testDecryptData256BitKey_IvZeroes {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t ivDataArray[] = {
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    uint8_t encryptedDataArray[] = {
        0x4F,0x26,0xC1,0xA6,0x8E,0x02,0x39,0x5D,0xED,0x9A,0x94,0xEF,0x8E,0x33,0xB0,0xEE,
        0xF5,0x6A,0x21,0xF0,0xBC,0x07,0xC1,0x42,0x33,0xD7,0x4C,0x60,0x29,0xD0,0x3F,0xB1,
        0x79,0x8B,0xCB,0xA0,0x23,0x8D,0x95,0x1A,0x82,0x2E,0xCE,0x6A,0xE9,0x6E,0x85,0xFF,
        0xE8,0x86,0x38,0xC2,0x4B,0x9D,0xFD,0x07,0x48,0x6E,0xD1,0x37,0xDB,0x96,0xA0,0xD1
    };
    NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
    
    NSString *expectedString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *expectedData = [expectedString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSData *decryptedData = [QredoCrypto decryptData:encryptedData withAesKey:keyData iv:ivData];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue([expectedData isEqualToData:decryptedData],@"Decrypted data incorrect.");
}



-(void)testDecryptData256BitKey_NilIv {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    //Nil IV should result in IV of zeroes being used
    NSData *ivData = nil;
    
    uint8_t encryptedDataArray[] = {
        0x4F,0x26,0xC1,0xA6,0x8E,0x02,0x39,0x5D,0xED,0x9A,0x94,0xEF,0x8E,0x33,0xB0,0xEE,
        0xF5,0x6A,0x21,0xF0,0xBC,0x07,0xC1,0x42,0x33,0xD7,0x4C,0x60,0x29,0xD0,0x3F,0xB1,
        0x79,0x8B,0xCB,0xA0,0x23,0x8D,0x95,0x1A,0x82,0x2E,0xCE,0x6A,0xE9,0x6E,0x85,0xFF,
        0xE8,0x86,0x38,0xC2,0x4B,0x9D,0xFD,0x07,0x48,0x6E,0xD1,0x37,0xDB,0x96,0xA0,0xD1
    };
    NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
    
    NSString *expectedString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *expectedData = [expectedString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSData *decryptedData = [QredoCrypto decryptData:encryptedData withAesKey:keyData iv:ivData];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue([expectedData isEqualToData:decryptedData],@"Decrypted data incorrect.");
}
*/
 

-(void)testDecryptData_InvalidIvLengthTooShort {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t ivDataArray[] = {
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    uint8_t encryptedDataArray[] = {
        0x4F,0x26,0xC1,0xA6,0x8E,0x02,0x39,0x5D,0xED,0x9A,0x94,0xEF,0x8E,0x33,0xB0,0xEE,
        0xF5,0x6A,0x21,0xF0,0xBC,0x07,0xC1,0x42,0x33,0xD7,0x4C,0x60,0x29,0xD0,0x3F,0xB1,
        0x79,0x8B,0xCB,0xA0,0x23,0x8D,0x95,0x1A,0x82,0x2E,0xCE,0x6A,0xE9,0x6E,0x85,0xFF,
        0xE8,0x86,0x38,0xC2,0x4B,0x9D,0xFD,0x07,0x48,0x6E,0xD1,0x37,0xDB,0x96,0xA0,0xD1
    };
    NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
    
    XCTAssertThrowsSpecificNamed([QredoCrypto decryptData:encryptedData withAesKey:keyData iv:ivData],NSException,NSInvalidArgumentException,@"Invalid IV length but NSInvalidArgumentException not thrown.");
}


-(void)testDecryptData_InvalidIvLengthTooLong {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t ivDataArray[] = {
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    uint8_t encryptedDataArray[] = {
        0x4F,0x26,0xC1,0xA6,0x8E,0x02,0x39,0x5D,0xED,0x9A,0x94,0xEF,0x8E,0x33,0xB0,0xEE,
        0xF5,0x6A,0x21,0xF0,0xBC,0x07,0xC1,0x42,0x33,0xD7,0x4C,0x60,0x29,0xD0,0x3F,0xB1,
        0x79,0x8B,0xCB,0xA0,0x23,0x8D,0x95,0x1A,0x82,0x2E,0xCE,0x6A,0xE9,0x6E,0x85,0xFF,
        0xE8,0x86,0x38,0xC2,0x4B,0x9D,0xFD,0x07,0x48,0x6E,0xD1,0x37,0xDB,0x96,0xA0,0xD1
    };
    NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
    
    XCTAssertThrowsSpecificNamed([QredoCrypto decryptData:encryptedData withAesKey:keyData iv:ivData],NSException,NSInvalidArgumentException,@"Invalid IV length but NSInvalidArgumentException not thrown.");
}


-(void)testEncryptDataInvalidShortKey {
    //15 byte (120 bit) key - invalid for AES (128/192/256 bit keys only)
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t ivDataArray[] = {
        0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    NSString *plaintextString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *plaintextData = [plaintextString dataUsingEncoding:NSASCIIStringEncoding];
    
    XCTAssertThrowsSpecificNamed([QredoCrypto encryptData:plaintextData withAesKey:keyData iv:ivData],NSException,NSInvalidArgumentException,@"Invalid key length but NSInvalidArgumentException not thrown.");
}


-(void)testEncryptData128BitKey {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t ivDataArray[] = {
        0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    NSString *plaintextString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *plaintextData = [plaintextString dataUsingEncoding:NSASCIIStringEncoding];
    
    uint8_t expectedDataArray[] = {
        0x1d,0xb8,0x50,0x74,0xaf,0xc3,0x4d,0x73,0x16,0x85,0x3c,0x12,0x22,0xda,0x2b,0x4d,
        0xba,0xf2,0x5b,0xd3,0xfe,0xe0,0x17,0x43,0xce,0x65,0x72,0x6c,0xe6,0xf8,0x4f,0x8a,
        0x7a,0xdb,0x7e,0xed,0x0d,0x5e,0x00,0x98,0x30,0x89,0xa2,0xfc,0x47,0x25,0xfa,0x88,
        0x5c,0x19,0x9a,0x80,0xa3,0x3d,0xc9,0x96,0xeb,0x3f,0x73,0x5b,0x7e,0x22,0xd8,0x5f
    };
    NSData *expectedData = [NSData dataWithBytes:expectedDataArray length:sizeof(expectedDataArray) / sizeof(uint8_t)];
    
    NSData *encryptedData = [QredoCrypto encryptData:plaintextData withAesKey:keyData iv:ivData];
    
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    XCTAssertTrue([expectedData isEqualToData:encryptedData],@"Encrypted data incorrect.");
}

/* AES now only supports 128b keys
-(void)testEncryptData256BitKey {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t ivDataArray[] = {
        0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12,0x34,0x56,0x78,0x90,0x12
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    NSString *plaintextString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *plaintextData = [plaintextString dataUsingEncoding:NSASCIIStringEncoding];
    
    uint8_t expectedDataArray[] = {
        0xCA,0x20,0x92,0x99,0xC2,0xFD,0x06,0xF2,0x74,0xDA,0xA1,0x87,0x74,0x11,0x45,0xC5,
        0x86,0xF6,0xE1,0x52,0xB3,0x31,0xC4,0x07,0x43,0xC9,0x2A,0xCC,0x82,0x86,0x84,0x2E,
        0x0B,0x56,0x93,0xF4,0xE3,0x67,0x3F,0x40,0x1C,0x93,0x7F,0x8C,0xB3,0xC3,0x8D,0xEA,
        0x2C,0xBA,0x0E,0x7F,0x5B,0x0C,0x3D,0xF6,0xEC,0xDC,0x00,0xE6,0xDB,0x36,0xDB,0x5A
    };
    NSData *expectedData = [NSData dataWithBytes:expectedDataArray length:sizeof(expectedDataArray) / sizeof(uint8_t)];
    
    NSData *encryptedData = [QredoCrypto encryptData:plaintextData withAesKey:keyData iv:ivData];
    
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    XCTAssertTrue([expectedData isEqualToData:encryptedData],@"Encrypted data incorrect.");
}


-(void)testEncryptData256BitKey_IvZeroes {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t ivDataArray[] = {
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    NSString *plaintextString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *plaintextData = [plaintextString dataUsingEncoding:NSASCIIStringEncoding];
    
    uint8_t expectedDataArray[] = {
        0x4F,0x26,0xC1,0xA6,0x8E,0x02,0x39,0x5D,0xED,0x9A,0x94,0xEF,0x8E,0x33,0xB0,0xEE,
        0xF5,0x6A,0x21,0xF0,0xBC,0x07,0xC1,0x42,0x33,0xD7,0x4C,0x60,0x29,0xD0,0x3F,0xB1,
        0x79,0x8B,0xCB,0xA0,0x23,0x8D,0x95,0x1A,0x82,0x2E,0xCE,0x6A,0xE9,0x6E,0x85,0xFF,
        0xE8,0x86,0x38,0xC2,0x4B,0x9D,0xFD,0x07,0x48,0x6E,0xD1,0x37,0xDB,0x96,0xA0,0xD1
    };
    NSData *expectedData = [NSData dataWithBytes:expectedDataArray length:sizeof(expectedDataArray) / sizeof(uint8_t)];
    
    NSData *encryptedData = [QredoCrypto encryptData:plaintextData withAesKey:keyData iv:ivData];
    
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    XCTAssertTrue([expectedData isEqualToData:encryptedData],@"Encrypted data incorrect.");
}


-(void)testEncryptData256BitKey_NilIv {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    //Nil IV should result in IV of zeroes being used
    NSData *ivData = nil;
    
    NSString *plaintextString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *plaintextData = [plaintextString dataUsingEncoding:NSASCIIStringEncoding];
    
    uint8_t expectedDataArray[] = {
        0x4F,0x26,0xC1,0xA6,0x8E,0x02,0x39,0x5D,0xED,0x9A,0x94,0xEF,0x8E,0x33,0xB0,0xEE,
        0xF5,0x6A,0x21,0xF0,0xBC,0x07,0xC1,0x42,0x33,0xD7,0x4C,0x60,0x29,0xD0,0x3F,0xB1,
        0x79,0x8B,0xCB,0xA0,0x23,0x8D,0x95,0x1A,0x82,0x2E,0xCE,0x6A,0xE9,0x6E,0x85,0xFF,
        0xE8,0x86,0x38,0xC2,0x4B,0x9D,0xFD,0x07,0x48,0x6E,0xD1,0x37,0xDB,0x96,0xA0,0xD1
    };
    NSData *expectedData = [NSData dataWithBytes:expectedDataArray length:sizeof(expectedDataArray) / sizeof(uint8_t)];
    
    NSData *encryptedData = [QredoCrypto encryptData:plaintextData withAesKey:keyData iv:ivData];
    
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    XCTAssertTrue([expectedData isEqualToData:encryptedData],@"Encrypted data incorrect.");
}

*/
 
-(void)testEncryptData_InvalidIvLengthTooShort {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    //15 byte IV is invalid for AES (should be 16 byte)
    uint8_t ivDataArray[] = {
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    NSString *plaintextString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *plaintextData = [plaintextString dataUsingEncoding:NSASCIIStringEncoding];
    
    XCTAssertThrowsSpecificNamed([QredoCrypto encryptData:plaintextData withAesKey:keyData iv:ivData],NSException,NSInvalidArgumentException,@"Invalid IV length but NSInvalidArgumentException not thrown.");
}


-(void)testEncryptData_InvalidIvLengthTooLong {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    //17 byte IV is invalid for AES (should be 16 byte)
    uint8_t ivDataArray[] = {
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    NSData *ivData = [NSData dataWithBytes:ivDataArray length:sizeof(ivDataArray) / sizeof(uint8_t)];
    
    NSString *plaintextString = @"Chim-chimeney, chim-chimeney, chim-chim-cheree. 'ave a banana!";
    NSData *plaintextData = [plaintextString dataUsingEncoding:NSASCIIStringEncoding];
    
    XCTAssertThrowsSpecificNamed([QredoCrypto encryptData:plaintextData withAesKey:keyData iv:ivData],NSException,NSInvalidArgumentException,@"Invalid IV length but NSInvalidArgumentException not thrown.");
}


-(void)testHkdfExtractSha256WithSalt {
    uint8_t ikmDataArray[] = {
        0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,
        0x0b,0x0b,0x0b,0x0b,0x0b,0x0b
    };
    NSData *ikmData = [NSData dataWithBytes:ikmDataArray length:sizeof(ikmDataArray) / sizeof(uint8_t)];
    
    uint8_t saltDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c
    };
    NSData *saltData = [NSData dataWithBytes:saltDataArray length:sizeof(saltDataArray) / sizeof(uint8_t)];
    
    uint8_t expectedPrkDataArray[] = {
        0x07,0x77,0x09,0x36,0x2c,0x2e,0x32,0xdf,0x0d,0xdc,0x3f,0x0d,0xc4,0x7b,0xba,0x63,
        0x90,0xb6,0xc7,0x3b,0xb5,0x0f,0x9c,0x31,0x22,0xec,0x84,0x4a,0xd7,0xc2,0xb3,0xe5
    };
    NSData *expectedPrkData = [NSData dataWithBytes:expectedPrkDataArray length:sizeof(expectedPrkDataArray) / sizeof(uint8_t)];
    
    NSData *prk = [QredoCrypto hkdfExtractSha256WithSalt:saltData initialKeyMaterial:ikmData];
    
    XCTAssertNotNil(prk,@"PRK should not be nil.");
    XCTAssertTrue([expectedPrkData isEqualToData:prk],@"PRK data incorrect.");
}


-(void)testHkdfExpandSha256WithKey {
    uint8_t keyDataArray[] = {
        0x07,0x77,0x09,0x36,0x2c,0x2e,0x32,0xdf,0x0d,0xdc,0x3f,0x0d,0xc4,0x7b,0xba,0x63,
        0x90,0xb6,0xc7,0x3b,0xb5,0x0f,0x9c,0x31,0x22,0xec,0x84,0x4a,0xd7,0xc2,0xb3,0xe5
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t infoDataArray[] = {
        0xf0,0xf1,0xf2,0xf3,0xf4,0xf5,0xf6,0xf7,0xf8,0xf9
    };
    NSData *infoData = [NSData dataWithBytes:infoDataArray length:sizeof(infoDataArray) / sizeof(uint8_t)];
    
    NSUInteger outputLength = 32;
    
    uint8_t expectedOkmDataArray[] = {
        0x3c,0xb2,0x5f,0x25,0xfa,0xac,0xd5,0x7a,0x90,0x43,0x4f,0x64,0xd0,0x36,0x2f,0x2a,
        0x2d,0x2d,0x0a,0x90,0xcf,0x1a,0x5a,0x4c,0x5d,0xb0,0x2d,0x56,0xec,0xc4,0xc5,0xbf
    };
    NSData *expectedOkmData = [NSData dataWithBytes:expectedOkmDataArray length:sizeof(expectedOkmDataArray) / sizeof(uint8_t)];
    
    NSData *okm = [QredoCrypto hkdfExpandSha256WithKey:keyData info:infoData outputLength:outputLength];
    
    XCTAssertNotNil(okm,@"OKM should not be nil.");
    XCTAssertTrue([expectedOkmData isEqualToData:okm],@"OKM data incorrect.");
}


-(void)testHkdfSha256WithSalt {
    uint8_t ikmDataArray[] = {
        0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,
        0x0b,0x0b,0x0b,0x0b,0x0b,0x0b
    };
    NSData *ikmData = [NSData dataWithBytes:ikmDataArray length:sizeof(ikmDataArray) / sizeof(uint8_t)];
    
    uint8_t saltDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c
    };
    NSData *saltData = [NSData dataWithBytes:saltDataArray length:sizeof(saltDataArray) / sizeof(uint8_t)];
    
    uint8_t infoDataArray[] = {
        0xf0,0xf1,0xf2,0xf3,0xf4,0xf5,0xf6,0xf7,0xf8,0xf9
    };
    NSData *infoData = [NSData dataWithBytes:infoDataArray length:sizeof(infoDataArray) / sizeof(uint8_t)];
    
    uint8_t expectedOkmDataArray[] = {
        0x3c,0xb2,0x5f,0x25,0xfa,0xac,0xd5,0x7a,0x90,0x43,0x4f,0x64,0xd0,0x36,0x2f,0x2a,
        0x2d,0x2d,0x0a,0x90,0xcf,0x1a,0x5a,0x4c,0x5d,0xb0,0x2d,0x56,0xec,0xc4,0xc5,0xbf
    };
    NSData *expectedOkmData = [NSData dataWithBytes:expectedOkmDataArray length:sizeof(expectedOkmDataArray) / sizeof(uint8_t)];
    
    NSData *okm = [QredoCrypto hkdfSha256WithSalt:saltData initialKeyMaterial:ikmData info:infoData];
    
    XCTAssertNotNil(okm,@"OKM should not be nil.");
    XCTAssertTrue([expectedOkmData isEqualToData:okm],@"OKM data incorrect.");
}


-(void)testPbkdf2Sha256WithSalt_RFC6070Example {
    NSString *saltString = @"saltSALTsaltSALTsaltSALTsaltSALTsalt";
    NSData *saltData = [saltString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSString *passwordString = @"passwordPASSWORDpassword";
    NSData *passwordData = [passwordString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSUInteger keyLength = 25;
    NSUInteger iterations = 4096;
    
    uint8_t expectedDerivedKeyDataArray[] = {
        0x34,0x8C,0x89,0xDB,0xCB,0xD3,0x2B,0x2F,0x32,0xD8,0x14,0xB8,0x11,0x6E,0x84,0xCF,
        0x2B,0x17,0x34,0x7E,0xBC,0x18,0x00,0x18,0x1C
    };
    NSData *expectedDerivedKeyData = [NSData dataWithBytes:expectedDerivedKeyDataArray length:sizeof(expectedDerivedKeyDataArray) / sizeof(uint8_t)];
    
    NSData *derivedKey = [QredoCrypto pbkdf2Sha256WithSalt:saltData passwordData:passwordData requiredKeyLengthBytes:keyLength iterations:iterations];
    
    XCTAssertNotNil(derivedKey,@"Derived key should not be nil.");
    XCTAssertTrue([expectedDerivedKeyData isEqualToData:derivedKey],@"Derived key incorrect.");
}


/* Test removed as it is essentially a duplicate of the one above, but the salt is too short to pass the guards
//This test takes about 10 seconds to run due (high number of iterations)
-(void)testPbkdf2Sha256WithSalt_RFC6070Example2 {
    BOOL bypassSaltLengthCheck = YES; //Used for testing salts < 8 bytes, which unfortunately all but 1 of RFC6070's test vectors are
    NSString *saltString = @"saltsaltsalt";
    NSData *saltData = [saltString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSString *passwordString = @"password";
    NSData *passwordData = [passwordString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSUInteger keyLength = 20;
    NSUInteger iterations = 16777216;
    
    uint8_t expectedDerivedKeyDataArray[] = {
        0xcf,0x81,0xc6,0x6f,0xe8,0xcf,0xc0,0x4d,0x1f,0x31,0xec,0xb6,0x5d,0xab,0x40,0x89,0xf7,0xf1,0x79,0xe8
    };
    NSData *expectedDerivedKeyData = [NSData dataWithBytes:expectedDerivedKeyDataArray length:sizeof(expectedDerivedKeyDataArray) / sizeof(uint8_t)];
    
    NSData *derivedKey = [QredoCrypto pbkdf2Sha256WithSalt:saltData  passwordData:passwordData requiredKeyLengthBytes:keyLength iterations:iterations];
    
    XCTAssertNotNil(derivedKey,@"Derived key should not be nil.");
    XCTAssertTrue([expectedDerivedKeyData isEqualToData:derivedKey],@"Derived key incorrect.");
}
*/

-(void)testGenerateHmacSha256ForDataWithCorrectLength {
    uint8_t keyDataArray[] = {
        0x68,0x65,0x6c,0x6c,0x6f,0x77,0x6f,0x72,0x6c,0x64,0x31,0x32,0x33,0x34,0x35,0x36
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t dataArray[] = {
        0x68,0x65,0x6c,0x6c,0x6f,0x77,0x6f,0x72,0x6c,0x64,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x6c,0x75,0x76,0x63,0x68,0x65,0x65,0x73,0x65,0x31,0x32,0x33,0x34,0x35,0x36,
        0x75,0x61,0x72,0x65,0x73,0x6d,0x65,0x6c,0x6c,0x79,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x61,0x6d,0x67,0x72,0x65,0x61,0x74,0x6f,0x6b,0x31,0x32,0x33,0x34,0x35,0x36
    };
    NSData *data = [NSData dataWithBytes:dataArray length:sizeof(dataArray) / sizeof(uint8_t)];
    
    uint8_t expectedMacDataArray[] = {
        0xcb,0x20,0x7c,0x67,0x82,0x75,0x79,0x2e,0xd1,0xf4,0x4b,0x61,0x79,0x46,0x43,0x68,
        0xf2,0xc3,0x4b,0x16,0x43,0x55,0xac,0xb9,0xb9,0xff,0x84,0x66,0x00,0xfe,0xa3,0xc4
    };
    NSData *expectedMacData = [NSData dataWithBytes:expectedMacDataArray length:sizeof(expectedMacDataArray) / sizeof(uint8_t)];
    
    
    NSData *mac = [QredoCrypto generateHmacSha256ForData:data length:data.length key:keyData];
    
    XCTAssertNotNil(mac,@"MAC should not be nil.");
    XCTAssertTrue([expectedMacData isEqualToData:mac],@"MAC data incorrect.");
}


-(void)testGenerateHmacSha256ForDataWithShorterLength {
    uint8_t keyDataArray[] = {
        0x68,0x65,0x6c,0x6c,0x6f,0x77,0x6f,0x72,0x6c,0x64,0x31,0x32,0x33,0x34,0x35,0x36
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t dataArray[] = {
        0x68,0x65,0x6c,0x6c,0x6f,0x77,0x6f,0x72,0x6c,0x64,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x6c,0x75,0x76,0x63,0x68,0x65,0x65,0x73,0x65,0x31,0x32,0x33,0x34,0x35,0x36,
        0x75,0x61,0x72,0x65,0x73,0x6d,0x65,0x6c,0x6c,0x79,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x61,0x6d,0x67,0x72,0x65,0x61,0x74,0x6f,0x6b,0x31,0x32,0x33,0x34,0x35,0x36,
        0x68,0x65,0x6c,0x6c,0x6f,0x77,0x6f,0x72,0x6c,0x64,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x6c,0x75,0x76,0x63,0x68,0x65,0x65,0x73,0x65,0x31,0x32,0x33,0x34,0x35,0x36,
        0x75,0x61,0x72,0x65,0x73,0x6d,0x65,0x6c,0x6c,0x79,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x61,0x6d,0x67,0x72,0x65,0x61,0x74,0x6f,0x6b,0x31,0x32,0x33,0x34,0x35,0x36
    };
    NSData *data = [NSData dataWithBytes:dataArray length:sizeof(dataArray) / sizeof(uint8_t)];
    
    uint8_t expectedMacDataArray[] = {
        0xcb,0x20,0x7c,0x67,0x82,0x75,0x79,0x2e,0xd1,0xf4,0x4b,0x61,0x79,0x46,0x43,0x68,
        0xf2,0xc3,0x4b,0x16,0x43,0x55,0xac,0xb9,0xb9,0xff,0x84,0x66,0x00,0xfe,0xa3,0xc4
    };
    NSData *expectedMacData = [NSData dataWithBytes:expectedMacDataArray length:sizeof(expectedMacDataArray) / sizeof(uint8_t)];
    
    //Only use the first 64 bytes
    NSData *mac = [QredoCrypto generateHmacSha256ForData:data length:64 key:keyData];
    
    XCTAssertNotNil(mac,@"MAC should not be nil.");
    XCTAssertTrue([expectedMacData isEqualToData:mac],@"MAC data incorrect.");
}


-(void)testSha256 {
    uint8_t dataArray[] = {
        0x68,0x65,0x6c,0x6c,0x6f,0x77,0x6f,0x72,0x6c,0x64,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x6c,0x75,0x76,0x63,0x68,0x65,0x65,0x73,0x65,0x31,0x32,0x33,0x34,0x35,0x36,
        0x75,0x61,0x72,0x65,0x73,0x6d,0x65,0x6c,0x6c,0x79,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x61,0x6d,0x67,0x72,0x65,0x61,0x74,0x6f,0x6b,0x31,0x32,0x33,0x34,0x35,0x36,
        0x68,0x65,0x6c,0x6c,0x6f,0x77,0x6f,0x72,0x6c,0x64,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x6c,0x75,0x76,0x63,0x68,0x65,0x65,0x73,0x65,0x31,0x32,0x33,0x34,0x35,0x36,
        0x75,0x61,0x72,0x65,0x73,0x6d,0x65,0x6c,0x6c,0x79,0x31,0x32,0x33,0x34,0x35,0x36,
        0x69,0x61,0x6d,0x67,0x72,0x65,0x61,0x74,0x6f,0x6b,0x31,0x32,0x33,0x34,0x35,0x36
    };
    NSData *data = [NSData dataWithBytes:dataArray length:sizeof(dataArray) / sizeof(uint8_t)];
    
    uint8_t expectedHashDataArray[] = {
        0xA1,0x26,0x38,0x10,0x0D,0x91,0xCC,0x43,0x60,0x96,0x9C,0x21,0x92,0x58,0xEE,0x37,
        0x3E,0xF1,0x48,0x40,0xFF,0xC1,0x95,0x09,0x01,0xA3,0xCA,0x56,0xCA,0x10,0x41,0x3C
    };
    NSData *expectedHashData = [NSData dataWithBytes:expectedHashDataArray length:sizeof(expectedHashDataArray) / sizeof(uint8_t)];
    
    NSData *hash = [QredoCrypto sha256:data];
    
    XCTAssertNotNil(hash,@"Hash should not be nil.");
    XCTAssertTrue([expectedHashData isEqualToData:hash],@"Hash data incorrect.");
}


-(void)testSha256SZeroLength {
    //Zero length input
    uint8_t dataArray[] = {
    };
    NSData *data = [NSData dataWithBytes:dataArray length:sizeof(dataArray) / sizeof(uint8_t)];
    
    uint8_t expectedHashDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *expectedHashData = [NSData dataWithBytes:expectedHashDataArray length:sizeof(expectedHashDataArray) / sizeof(uint8_t)];
    
    NSData *hash = [QredoCrypto sha256:data];
    
    XCTAssertNotNil(hash,@"Hash should not be nil.");
    XCTAssertTrue([expectedHashData isEqualToData:hash],@"Hash data incorrect.");
}


-(void)testSecureRandom {
    NSData *randomBytes1 = [QredoCrypto secureRandomWithSize:32];
    NSData *randomBytes2 = [QredoCrypto secureRandomWithSize:32];
    NSData *randomBytes3 = [QredoCrypto secureRandomWithSize:64];
    NSData *randomBytes4 = [QredoCrypto secureRandomWithSize:128];
    NSData *randomBytes5 = [QredoCrypto secureRandomWithSize:256];
    NSData *randomBytes6 = [QredoCrypto secureRandomWithSize:131072];
    
    XCTAssertEqual([randomBytes1 length],32);
    XCTAssertEqual([randomBytes2 length],32);
    XCTAssertEqual([randomBytes3 length],64);
    XCTAssertEqual([randomBytes4 length],128);
    XCTAssertEqual([randomBytes5 length],256);
    XCTAssertEqual([randomBytes6 length],131072);
    XCTAssertFalse([randomBytes1 isEqualToData:randomBytes2]);
}


-(void)testEqualsConstantTime_SameData {
    uint8_t leftDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *leftData = [NSData dataWithBytes:leftDataArray length:sizeof(leftDataArray) / sizeof(uint8_t)];
    
    uint8_t rightDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *rightData = [NSData dataWithBytes:rightDataArray length:sizeof(rightDataArray) / sizeof(uint8_t)];
    
    BOOL expectedComparisonResult = YES;
    
    BOOL comparisonResult = [QredoCrypto equalsConstantTime:leftData right:rightData];
    
    XCTAssertTrue(expectedComparisonResult == comparisonResult,@"Comparison check failed.");
}


-(void)testEqualsConstantTime_DifferentLengths {
    uint8_t leftDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8
    };
    NSData *leftData = [NSData dataWithBytes:leftDataArray length:sizeof(leftDataArray) / sizeof(uint8_t)];
    
    uint8_t rightDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *rightData = [NSData dataWithBytes:rightDataArray length:sizeof(rightDataArray) / sizeof(uint8_t)];
    
    BOOL expectedComparisonResult = NO;
    
    BOOL comparisonResult = [QredoCrypto equalsConstantTime:leftData right:rightData];
    
    XCTAssertTrue(expectedComparisonResult == comparisonResult,@"Comparison check failed.");
}


-(void)testEqualsConstantTime_EmptyData {
    uint8_t leftDataArray[] = {
    };
    NSData *leftData = [NSData dataWithBytes:leftDataArray length:sizeof(leftDataArray) / sizeof(uint8_t)];
    
    uint8_t rightDataArray[] = {
    };
    NSData *rightData = [NSData dataWithBytes:rightDataArray length:sizeof(rightDataArray) / sizeof(uint8_t)];
    
    BOOL expectedComparisonResult = YES;
    
    BOOL comparisonResult = [QredoCrypto equalsConstantTime:leftData right:rightData];
    
    XCTAssertTrue(expectedComparisonResult == comparisonResult,@"Comparison check failed.");
}


-(void)testEqualsConstantTime_CheckComparisonTimesCorrect {
    uint8_t leftDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *leftData = [NSData dataWithBytes:leftDataArray length:sizeof(leftDataArray) / sizeof(uint8_t)];
    
    uint8_t rightCorrectDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *rightCorrectData = [NSData dataWithBytes:rightCorrectDataArray length:sizeof(rightCorrectDataArray) / sizeof(uint8_t)];
    
    [self measureBlock:^{
        //Put the code you want to measure the time of here.
        
        //Repeat enough so the measurement is fairly accurate
        for (int i = 0; i < 10000; i++){
            [QredoCrypto   equalsConstantTime:leftData
                                        right:rightCorrectData];
        }
    }];
}


-(void)testEqualsConstantTime_CheckComparisonTimesWithFirstByteWrong {
    uint8_t leftDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *leftData = [NSData dataWithBytes:leftDataArray length:sizeof(leftDataArray) / sizeof(uint8_t)];
    
    uint8_t rightIncorrectDataArray[] = {
        0xE4,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *rightIncorrectData = [NSData dataWithBytes:rightIncorrectDataArray length:sizeof(rightIncorrectDataArray) / sizeof(uint8_t)];
    
    [self measureBlock:^{
        //Put the code you want to measure the time of here.
        
        //Repeat enough so the measurement is fairly accurate
        for (int i = 0; i < 10000; i++){
            [QredoCrypto   equalsConstantTime:leftData
                                        right:rightIncorrectData];
        }
    }];
}


-(void)testIsEqualToData_CheckComparisonTimesCorrect {
    uint8_t leftDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *leftData = [NSData dataWithBytes:leftDataArray length:sizeof(leftDataArray) / sizeof(uint8_t)];
    
    uint8_t rightCorrectDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *rightCorrectData = [NSData dataWithBytes:rightCorrectDataArray length:sizeof(rightCorrectDataArray) / sizeof(uint8_t)];
    
    [self measureBlock:^{
        //Put the code you want to measure the time of here.
        
        //Repeat enough so the measurement is fairly accurate
        for (int i = 0; i < 1000000; i++){
            [leftData isEqualToData:rightCorrectData];
        }
    }];
}


-(void)testIsEqualToData_CheckComparisonTimesWithFirstByteWrong {
    uint8_t leftDataArray[] = {
        0xE3,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *leftData = [NSData dataWithBytes:leftDataArray length:sizeof(leftDataArray) / sizeof(uint8_t)];
    
    uint8_t rightIncorrectDataArray[] = {
        0xE4,0xB0,0xC4,0x42,0x98,0xFC,0x1C,0x14,0x9A,0xFB,0xF4,0xC8,0x99,0x6F,0xB9,0x24,
        0x27,0xAE,0x41,0xE4,0x64,0x9B,0x93,0x4C,0xA4,0x95,0x99,0x1B,0x78,0x52,0xB8,0x55
    };
    NSData *rightIncorrectData = [NSData dataWithBytes:rightIncorrectDataArray length:sizeof(rightIncorrectDataArray) / sizeof(uint8_t)];
    
    [self measureBlock:^{
        //Put the code you want to measure the time of here.
        
        //Repeat enough so the measurement is fairly accurate
        for (int i = 0; i < 1000000; i++){
            [leftData isEqualToData:rightIncorrectData];
        }
    }];
}


-(void)testRsaKeyGen_Persist_1024 {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024;
    BOOL persistInKeychain = YES;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits
                                                         publicKeyIdentifier:publicKeyIdentifier
                                                        privateKeyIdentifier:privateKeyIdentifier
                                                      persistInAppleKeychain:persistInKeychain];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
}


-(void)testRsaKeyGen_Persist_2048 {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 2048;
    BOOL persistInKeychain = YES;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits
                                                         publicKeyIdentifier:publicKeyIdentifier
                                                        privateKeyIdentifier:privateKeyIdentifier
                                                      persistInAppleKeychain:persistInKeychain];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
}


-(void)testRsaKeyGen_Persist_4096 {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 4096;
    BOOL persistInKeychain = YES;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits
                                                         publicKeyIdentifier:publicKeyIdentifier
                                                        privateKeyIdentifier:privateKeyIdentifier
                                                      persistInAppleKeychain:persistInKeychain];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
}


-(void)testRsaKeyGen_NotPersisted {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024;
    BOOL persistInKeychain = NO;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:persistInKeychain];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are NOT present
    
    NSData *publicKeyData;
    NSData *privateKeyData;
    
    @try {
        publicKeyData = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    } @catch (NSException *exception){
        if (![exception.name isEqualToString:@"QredoKeyIdentifierNotFound"])XCTFail(@"Error happened or keys are persisted.");
    } @finally {
        XCTAssertNil(publicKeyData,@"Public key data should be nil.");
    }
    
    @try {
        privateKeyData = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    } @catch (NSException *exception){
        if (![exception.name isEqualToString:@"QredoKeyIdentifierNotFound"])XCTFail(@"Error happened or keys are persisted.");
    } @finally {
        XCTAssertNil(privateKeyData,@"Private key data should be nil.");
    }
}


-(void)testRsaKeyGenEncryptOaepAndDecrypt {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    
    uint8_t plainTextDataArray[] = {
        0x11
    };
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    //In the case of OAEP padding, decrypted length should be original plaintext length
    NSInteger expectedDecryptedDataLength = plainTextData.length;
    
    QredoPadding padding = QredoPaddingOaep;
    
    SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyIdentifier];
    NSData *encryptedData = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef];
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    
    SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
    NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue(decryptedData.length == expectedDecryptedDataLength,@"Decrypted data length is incorrect.");
    XCTAssertTrue([decryptedData isEqualToData:plainTextData],@"Decrypted data is incorrect.");
}


-(void)testRsaKeyGenEncryptOaepAndDecrypt_JustZero {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    
    //Try and encrypt/decrypt just zero to confirm works with OAEP padding.
    uint8_t plainTextDataArray[] = {
        0x00
    };
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    //In the case of OAEP padding, decrypted length should be original plaintext length
    NSInteger expectedDecryptedDataLength = plainTextData.length;
    
    QredoPadding padding = QredoPaddingOaep;
    
    SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyIdentifier];
    NSData *encryptedData = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef];
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    
    SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
    NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue(decryptedData.length == expectedDecryptedDataLength,@"Decrypted data length is incorrect.");
    XCTAssertTrue([decryptedData isEqualToData:plainTextData],@"Decrypted data is incorrect.");
}


-(void)testRsaKeyGenEncryptPkcs1AndDecrypt {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    
    uint8_t plainTextDataArray[] = {
        0x11
    };
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    //In the case of PKCS#1 padding, decrypted length should be original plaintext length
    NSInteger expectedDecryptedDataLength = plainTextData.length;
    
    QredoPadding padding = QredoPaddingPkcs1;
    
    SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyIdentifier];
    NSData *encryptedData = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef];
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    
    SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
    NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue(decryptedData.length == expectedDecryptedDataLength,@"Decrypted data length is incorrect.");
    XCTAssertTrue([decryptedData isEqualToData:plainTextData],@"Decrypted data is incorrect.");
}


-(void)testRsaKeyGenEncryptPkcs1AndDecrypt_JustZero {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    
    //Try and encrypt/decrypt just zero to confirm works with PKCS1 padding.
    uint8_t plainTextDataArray[] = {
        0x00
    };
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    //In the case of PKCS#1 padding, decrypted length should be original plaintext length
    NSInteger expectedDecryptedDataLength = plainTextData.length;
    
    QredoPadding padding = QredoPaddingPkcs1;
    
    SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyIdentifier];
    NSData *encryptedData = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef];
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    
    SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
    NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue(decryptedData.length == expectedDecryptedDataLength,@"Decrypted data length is incorrect.");
    XCTAssertTrue([decryptedData isEqualToData:plainTextData],@"Decrypted data is incorrect.");
}


-(void)testRsaKeyGenEncryptNoPaddingAndDecrypt {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024; //1024 bits = 128 bytes
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    
    uint8_t plainTextDataArray[] = { 0x01,0x16,0x80,0xE3,0x7E,0xB3,0xCF,0xD8,0xA2,0xDF,0x91,0xC7,0xA6,0x41,0x3C,0xA7,0x5F,0xF3,0x58,0x26,0x08,0x8C,0x16,0x44,0xB2,0x75,0x0F,0x6B,0x9F,0xDA,0xB8,0x90,0xB9,0xF0,0xAB,0xDB,0x82,0x72,0x15,0x32,0xF7,0x7A,0x5C,0x44,0xC5,0x2B,0xB4,0x93,0x3C,0xF1,0x2D,0x68,0xCB,0x48,0x95,0xD6,0x4F,0x94,0x2E,0xB9,0xE2,0x03,0x05,0x43,0x4C,0x70,0x7A,0x15,0xEE,0xAA,0x24,0xC8,0x45,0x1D,0x0C,0x54,0x88,0x30,0x3E,0x41,0xEB,0xD0,0xF1,0xB4,0xAF,0x59,0xA1,0xE5,0x23,0x76,0x12,0x40,0x59,0xBE,0x62,0x62,0x5D,0xC3,0x38,0x89,0xF4,0xC4,0x22,0x17,0x5D,0x50,0x37,0x7A,0xE0,0xAA,0xF9,0xC3,0xA2,0x9D,0x62,0x55,0x0F,0x1B,0xAF,0x53,0x93,0x5C,0x96,0xD9,0x6B,0x0D,0x64,0x1B }; //128 bytes, correct length for 1024 bit key
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    //In the case of no padding, decrypted length will depend on any leading zeroes (0x00) in the plaintext data. The leading zeroes will be lost.
    //We have no leading zeroes, so lengths should match
    NSInteger expectedDecryptedDataLength = plainTextData.length;
    
    QredoPadding padding = QredoPaddingNone;
    
    SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyIdentifier];
    NSData *encryptedData = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef];
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    
    SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
    NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue(decryptedData.length == expectedDecryptedDataLength,@"Decrypted data length is incorrect.");
    XCTAssertTrue([decryptedData isEqualToData:plainTextData],@"Decrypted data is incorrect.");
}


-(void)testRsaKeyGenEncryptNoPaddingAndDecrypt_StartsWithZero {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024; //1024 bits = 128 bytes
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    
    uint8_t plainTextDataArray[] = { 0x00,0x16,0x80,0xE3,0x7E,0xB3,0xCF,0xD8,0xA2,0xDF,0x91,0xC7,0xA6,0x41,0x3C,0xA7,0x5F,0xF3,0x58,0x26,0x08,0x8C,0x16,0x44,0xB2,0x75,0x0F,0x6B,0x9F,0xDA,0xB8,0x90,0xB9,0xF0,0xAB,0xDB,0x82,0x72,0x15,0x32,0xF7,0x7A,0x5C,0x44,0xC5,0x2B,0xB4,0x93,0x3C,0xF1,0x2D,0x68,0xCB,0x48,0x95,0xD6,0x4F,0x94,0x2E,0xB9,0xE2,0x03,0x05,0x43,0x4C,0x70,0x7A,0x15,0xEE,0xAA,0x24,0xC8,0x45,0x1D,0x0C,0x54,0x88,0x30,0x3E,0x41,0xEB,0xD0,0xF1,0xB4,0xAF,0x59,0xA1,0xE5,0x23,0x76,0x12,0x40,0x59,0xBE,0x62,0x62,0x5D,0xC3,0x38,0x89,0xF4,0xC4,0x22,0x17,0x5D,0x50,0x37,0x7A,0xE0,0xAA,0xF9,0xC3,0xA2,0x9D,0x62,0x55,0x0F,0x1B,0xAF,0x53,0x93,0x5C,0x96,0xD9,0x6B,0x0D,0x64,0x1B }; //128 bytes, correct length for 1024 bit key
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    //In the case of no padding, decrypted length will depend on any leading zeroes (0x00) in the plaintext data. The leading zeroes will be lost.
    //We have 1 leading zero
    uint8_t expectedDecryptedDataArray[] = { 0x16,0x80,0xE3,0x7E,0xB3,0xCF,0xD8,0xA2,0xDF,0x91,0xC7,0xA6,0x41,0x3C,0xA7,0x5F,0xF3,0x58,0x26,0x08,0x8C,0x16,0x44,0xB2,0x75,0x0F,0x6B,0x9F,0xDA,0xB8,0x90,0xB9,0xF0,0xAB,0xDB,0x82,0x72,0x15,0x32,0xF7,0x7A,0x5C,0x44,0xC5,0x2B,0xB4,0x93,0x3C,0xF1,0x2D,0x68,0xCB,0x48,0x95,0xD6,0x4F,0x94,0x2E,0xB9,0xE2,0x03,0x05,0x43,0x4C,0x70,0x7A,0x15,0xEE,0xAA,0x24,0xC8,0x45,0x1D,0x0C,0x54,0x88,0x30,0x3E,0x41,0xEB,0xD0,0xF1,0xB4,0xAF,0x59,0xA1,0xE5,0x23,0x76,0x12,0x40,0x59,0xBE,0x62,0x62,0x5D,0xC3,0x38,0x89,0xF4,0xC4,0x22,0x17,0x5D,0x50,0x37,0x7A,0xE0,0xAA,0xF9,0xC3,0xA2,0x9D,0x62,0x55,0x0F,0x1B,0xAF,0x53,0x93,0x5C,0x96,0xD9,0x6B,0x0D,0x64,0x1B }; //128 bytes, correct length for 1024 bit key
    NSData *expectedDecryptedData = [NSData dataWithBytes:expectedDecryptedDataArray length:sizeof(expectedDecryptedDataArray) / sizeof(uint8_t)];
    
    
    QredoPadding padding = QredoPaddingNone;
    
    SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyIdentifier];
    NSData *encryptedData = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef];
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    
    SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
    NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue(decryptedData.length == expectedDecryptedData.length,@"Decrypted data length is incorrect.");
    XCTAssertTrue([decryptedData isEqualToData:expectedDecryptedData],@"Decrypted data is incorrect.");
}


-(void)testRsaKeyGenEncryptNoPaddingAndDecrypt_AllZeroes {
    //When not using any padding scheme, RSA encrypt/decrypt will lose any leading zeroes (0x00) from original plaintext
    
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024; //1024 bits = 128 bytes
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    
    uint8_t plainTextDataArray[keySizeBits / 8]; //128 bytes, correct length for 1024 bit key
    memset(plainTextDataArray,0x00,sizeof(plainTextDataArray) / sizeof(uint8_t));
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    //In the case where plaintext is just zeroes (0x00), the decrypted result will be 0 length
    NSInteger expectedDecryptedDataLength = 0;
    
    QredoPadding padding = QredoPaddingNone;
    
    SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyIdentifier];
    NSData *encryptedData = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef];
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
    
    SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
    NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
    
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue(decryptedData.length == expectedDecryptedDataLength,@"Decrypted data length is incorrect.");
    XCTAssertTrue(decryptedData.length == expectedDecryptedDataLength,@"Decrypted data length is incorrect.");
}


-(void)testRsaKeyGenEncryptNoPaddingAndDecrypt_Multiple {
    //This test was originally written to investigate intermittent failures,
    //which were down to the plaintext data (as a BigInteger) exceeding the generated key (as a BigInteger) value.
    //Solution was to either use a suitable padding scheme (not suitable when testing the no-padding option) or
    //ensure that the plaintext data was less than the key - hence zero for first element of plaintext data.
    //This introduced another issue that leading zeroes are lost on decrypt (as it's just a Big Integer, leading
    //zeroes are meaningless), hence the decrypted data being slightly different to the plaintext data.
    
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024; //1024 bits = 128 bytes
    
    uint8_t plainTextDataArray[] = { 0x00,0x16,0x80,0xE3,0x7E,0xB3,0xCF,0xD8,0xA2,0xDF,0x91,0xC7,0xA6,0x41,0x3C,0xA7,0x5F,0xF3,0x58,0x26,0x08,0x8C,0x16,0x44,0xB2,0x75,0x0F,0x6B,0x9F,0xDA,0xB8,0x90,0xB9,0xF0,0xAB,0xDB,0x82,0x72,0x15,0x32,0xF7,0x7A,0x5C,0x44,0xC5,0x2B,0xB4,0x93,0x3C,0xF1,0x2D,0x68,0xCB,0x48,0x95,0xD6,0x4F,0x94,0x2E,0xB9,0xE2,0x03,0x05,0x43,0x4C,0x70,0x7A,0x15,0xEE,0xAA,0x24,0xC8,0x45,0x1D,0x0C,0x54,0x88,0x30,0x3E,0x41,0xEB,0xD0,0xF1,0xB4,0xAF,0x59,0xA1,0xE5,0x23,0x76,0x12,0x40,0x59,0xBE,0x62,0x62,0x5D,0xC3,0x38,0x89,0xF4,0xC4,0x22,0x17,0x5D,0x50,0x37,0x7A,0xE0,0xAA,0xF9,0xC3,0xA2,0x9D,0x62,0x55,0x0F,0x1B,0xAF,0x53,0x93,0x5C,0x96,0xD9,0x6B,0x0D,0x64,0x1B }; //128 bytes, correct length for 1024 bit key
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    //In the case of no padding, decrypted length will depend on any leading zeroes (0x00) in the plaintext data. The leading zeroes will be lost.
    //We have 1 leading zero
    uint8_t expectedDecryptedDataArray[] = { 0x16,0x80,0xE3,0x7E,0xB3,0xCF,0xD8,0xA2,0xDF,0x91,0xC7,0xA6,0x41,0x3C,0xA7,0x5F,0xF3,0x58,0x26,0x08,0x8C,0x16,0x44,0xB2,0x75,0x0F,0x6B,0x9F,0xDA,0xB8,0x90,0xB9,0xF0,0xAB,0xDB,0x82,0x72,0x15,0x32,0xF7,0x7A,0x5C,0x44,0xC5,0x2B,0xB4,0x93,0x3C,0xF1,0x2D,0x68,0xCB,0x48,0x95,0xD6,0x4F,0x94,0x2E,0xB9,0xE2,0x03,0x05,0x43,0x4C,0x70,0x7A,0x15,0xEE,0xAA,0x24,0xC8,0x45,0x1D,0x0C,0x54,0x88,0x30,0x3E,0x41,0xEB,0xD0,0xF1,0xB4,0xAF,0x59,0xA1,0xE5,0x23,0x76,0x12,0x40,0x59,0xBE,0x62,0x62,0x5D,0xC3,0x38,0x89,0xF4,0xC4,0x22,0x17,0x5D,0x50,0x37,0x7A,0xE0,0xAA,0xF9,0xC3,0xA2,0x9D,0x62,0x55,0x0F,0x1B,0xAF,0x53,0x93,0x5C,0x96,0xD9,0x6B,0x0D,0x64,0x1B }; //128 bytes, correct length for 1024 bit key
    NSData *expectedDecryptedData = [NSData dataWithBytes:expectedDecryptedDataArray length:sizeof(expectedDecryptedDataArray) / sizeof(uint8_t)];
    
    QredoPadding padding = QredoPaddingNone;
    
    const int numberOfTests = 20;
    
    for (int i = 0; i < numberOfTests; i++){
        [QredoCrypto deleteAllKeysInAppleKeychain];
        QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
        XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
        XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
        XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
        
        //Confirm keys are present
        NSData *keyData = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
        
        QredoRsaPublicKey *publicKey = [[QredoRsaPublicKey alloc] initWithPkcs1KeyData:keyData];
        XCTAssertNotNil(publicKey,@"Public Key object should not be nil.");
        
        keyData = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
        XCTAssertNotNil(keyData,@"Private Key data should not be nil.");
        
        SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyIdentifier];
        XCTAssertTrue(publicKeyRef != NULL,@"Failed to get SecKeyRef for generated public key.");
        
        NSData *encryptedData = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef];
        XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil. Iteration: %d",i);
        
        if (encryptedData == nil){
            //Do not want to continue, otherwise exception is thrown which aborts the test
            continue;
        }
        
        SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
        NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
        
        XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
        XCTAssertTrue(decryptedData.length == expectedDecryptedData.length,@"Decrypted data length is incorrect.");
        XCTAssertTrue([decryptedData isEqualToData:expectedDecryptedData],@"Decrypted data is incorrect.");
    }
}


-(void)testRsaKeyGenEncryptNoPadding_IncorrectLength {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    //Confirm keys are present
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
    
    uint8_t plainTextDataArray[] = {
        0x11
    };
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    QredoPadding padding = QredoPaddingNone;
    
    SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyIdentifier];
    
    XCTAssertThrowsSpecificNamed([QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef],NSException,NSInvalidArgumentException,@"Invalid data length but NSInvalidArgumentException not thrown.");
}


-(void)testRsaDecryptCipherTextData_BouncyCastleEncrypted {
    /*
     This key was generated by in iOS, exported to C# Bouncy Castle library.
     The value 0x11 was encrypted in Bouncy Castle using the public key.
     The PKCS#1 key data to import into iOS (as key will have been deleted) was manually created from the exported iOS elements.
     This test will confirm that we can export key to Bouncy Castle, and decrypt data (using private key) encrypted by Bouncy Castle, and that the inported key works correctly.
     */
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
    NSUInteger keyLengthBits = 1024;
    BOOL isPrivateKey = YES;
    uint8_t keyDataArray[] = { 0x30,0x82,0x02,0x62,0x02,0x01,0x00,0x02,0x81,0x81,0x00,0xCD,0x85,0xBE,0xB0,0xF8,0x45,0x2D,0xD7,0xCF,0x02,0x87,0x10,0x28,0xE0,0x94,0x8D,0x94,0x97,0xD4,0x4B,0x66,0xEF,0x6F,0xF0,0x09,0xCC,0xBC,0x40,0x17,0x32,0xBB,0x2E,0xE7,0x48,0xE4,0x12,0x8C,0x93,0x0A,0x47,0xF0,0xA7,0xFB,0x2A,0x69,0xCB,0xF5,0x6F,0x48,0x0A,0x1E,0xBE,0x73,0xEE,0xC6,0xB4,0x18,0xC0,0x2C,0xAD,0x99,0x27,0x40,0x77,0x66,0x6A,0xA9,0xF8,0xF9,0x8C,0xE2,0x0B,0xF2,0x08,0xDB,0x0F,0xBB,0xAA,0x42,0xA6,0x57,0xA7,0x59,0x73,0xB4,0xE8,0x23,0x7D,0x50,0x23,0x87,0x74,0x3F,0x1F,0xCC,0x65,0xAA,0xA2,0xC4,0x9D,0xE0,0xCE,0x72,0x1D,0x90,0x67,0xE7,0x87,0xAA,0xC2,0xEC,0xE2,0x3B,0xF8,0x02,0xAF,0x14,0x40,0xC8,0xDC,0x0D,0x17,0xCE,0x10,0xEE,0xA0,0xD5,0x8B,0x02,0x03,0x01,0x00,0x01,0x02,0x81,0x81,0x00,0xA9,0x2F,0x96,0x81,0x1C,0x7F,0xE6,0x73,0x27,0x88,0x8F,0x22,0xF0,0x63,0xA0,0x26,0xC4,0xD2,0x10,0x03,0x5A,0x63,0x75,0x24,0x87,0x0C,0xB1,0x53,0x99,0x45,0x3B,0xEE,0x2A,0x9B,0x48,0x95,0x34,0x7F,0xBF,0x10,0xE5,0xBD,0x82,0xF7,0xB1,0x4C,0x23,0x69,0x4E,0x46,0x76,0x74,0x95,0xFF,0x54,0x37,0xE1,0xC0,0x21,0x87,0x6E,0xF2,0x6F,0x0F,0x74,0x48,0xEA,0xB7,0x7A,0x69,0xDC,0x88,0x1B,0xE7,0xBB,0x2A,0xE6,0x7F,0x52,0x8A,0xBD,0xB4,0xC0,0xBA,0x42,0xEE,0xB4,0x8F,0xF7,0xA8,0x47,0xEE,0x12,0xF9,0x4F,0xF2,0xE6,0x32,0x7F,0xA9,0xE5,0xAD,0x3A,0xD6,0xBF,0x06,0xE6,0x3D,0x2C,0xD1,0x0D,0x93,0x71,0xE4,0xED,0xA1,0xAB,0x90,0x89,0x92,0x4E,0x4D,0x05,0x55,0x7D,0x96,0x39,0x71,0x02,0x81,0x41,0x01,0xE3,0x00,0x6D,0xF9,0x3E,0x5F,0xB6,0xE8,0x00,0xFC,0x74,0x1F,0x80,0x3D,0x3D,0xCF,0xAF,0xAD,0x85,0xA7,0x6E,0xEF,0xDD,0x80,0x9E,0x21,0x9D,0xB7,0x29,0xCF,0xAB,0x3F,0x9C,0x4D,0x84,0x45,0x2E,0xE9,0x43,0x18,0xDB,0xAD,0x86,0x79,0xFF,0xDF,0xAF,0xBE,0xC1,0x73,0x3E,0xCA,0xB0,0x28,0xA9,0xB9,0x3D,0x98,0xE8,0x44,0xA5,0x1F,0x54,0xD7,0x02,0x81,0x40,0x6C,0xEE,0x46,0xF7,0xC3,0x72,0x12,0xA7,0xD8,0x42,0xB8,0x24,0xC5,0x97,0xF7,0x88,0x68,0x5F,0xDF,0xC7,0x82,0xC4,0xF6,0x3F,0x25,0x29,0x45,0x69,0xB4,0xFA,0xEE,0x53,0xC7,0x87,0x6A,0xE6,0x21,0xAA,0x91,0xBE,0xEA,0x48,0x87,0x20,0xC4,0x34,0xE4,0x27,0xCC,0x96,0xB4,0x3D,0x67,0x6F,0x0E,0x7C,0x6D,0x80,0x9B,0x8D,0x9E,0x57,0x3A,0x6D,0x02,0x81,0x41,0x00,0xF4,0x2C,0x24,0x6C,0x6B,0x2E,0xE1,0xFD,0x79,0x7A,0x26,0x8E,0x42,0x3B,0x33,0x83,0x49,0xD1,0x94,0x0E,0xA7,0xD3,0x95,0x0B,0xCF,0x65,0x39,0x20,0xFE,0x7F,0x20,0x98,0x80,0xC0,0xE3,0x4C,0x42,0x41,0xE4,0x0C,0xAE,0x09,0x94,0x41,0x1A,0xAC,0x8F,0x61,0x04,0xD4,0xE8,0xFA,0x78,0x81,0xA6,0x03,0xA2,0x73,0x29,0x80,0x82,0x65,0x4B,0x73,0x02,0x81,0x40,0x4E,0xA2,0x2F,0x2E,0xB9,0xB2,0xC6,0x0E,0xCD,0xC9,0x53,0xFE,0x8F,0x78,0xE5,0x22,0x5E,0x1E,0x1F,0x7F,0x79,0x41,0xCF,0x74,0xC3,0xD1,0xA8,0x1E,0xE7,0x9B,0x60,0xA1,0xAF,0xDE,0x6C,0x67,0x96,0x13,0xF8,0x43,0xF6,0x01,0xC7,0x31,0xFB,0x11,0x27,0x46,0x27,0xA4,0xFE,0x95,0x78,0xEE,0x2D,0x69,0xDA,0xEE,0x44,0xDC,0x15,0x5A,0x68,0x7D,0x02,0x81,0x41,0x01,0xC9,0xD7,0x89,0x1B,0xFA,0x62,0xFA,0xF6,0x79,0xBE,0x5E,0x3C,0x53,0x8E,0xFB,0x94,0x4F,0x4E,0x99,0xAD,0x8A,0xB1,0x12,0x50,0x0C,0x21,0x72,0xE8,0xDD,0xF3,0x8D,0x36,0x6D,0x09,0x91,0xBA,0x4B,0x7C,0x12,0x1A,0x42,0x4A,0xAC,0xE3,0x05,0xD7,0x89,0x0F,0x9E,0xA7,0x9D,0x65,0xCF,0x40,0x98,0x4F,0xE5,0xF1,0x4A,0xBF,0x88,0xA0,0x22,0xB1 };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    uint8_t expectedPlaintextDataArray[] = { 0x11 };
    NSData *expectedPlaintextData = [NSData dataWithBytes:expectedPlaintextDataArray
                                                   length:sizeof(expectedPlaintextDataArray) / sizeof(uint8_t)];
    
    uint8_t ciphertextDataArray[] = { 0x5D,0x4D,0x16,0x32,0x5F,0x27,0xA5,0xA5,0x74,0x6F,0x57,0xAF,0x82,0xEB,0x1B,0x61,0xE2,0xB8,0xE4,0x47,0x03,0xC4,0xDB,0xC7,0x4F,0x94,0x7C,0xB6,0xE4,0xAC,0x41,0x21,0xB6,0xBF,0x42,0xF1,0x3C,0x5E,0x47,0x3D,0xE9,0xAF,0x09,0xD8,0xA4,0xA3,0xC8,0x7D,0x83,0xA3,0xFF,0xB1,0xAA,0xD1,0x5B,0x56,0xA3,0x78,0x32,0x4E,0x28,0xF4,0xFD,0x8D,0xA3,0x17,0x31,0xEF,0x16,0xE7,0xC7,0x7E,0xC0,0x6A,0xCE,0xBA,0xCE,0x9C,0xDB,0xEA,0x04,0x94,0xE6,0x59,0x02,0xA1,0xC4,0x14,0xDA,0x43,0x7B,0xCD,0x77,0x48,0x7A,0x11,0xBA,0x30,0x7E,0x26,0x58,0xCF,0x20,0x6C,0xB7,0xE1,0x65,0x9C,0x63,0xA1,0xED,0xA7,0x81,0x7C,0xD4,0x55,0x22,0x92,0x50,0xB0,0xCA,0xFA,0x26,0xB7,0xB4,0x31,0x49,0xCD };
    NSData *ciphertextData = [NSData dataWithBytes:ciphertextDataArray length:sizeof(ciphertextDataArray) / sizeof(uint8_t)];
    QredoPadding paddingType = QredoPaddingPkcs1;
    
    SecKeyRef importKeyRef = [QredoCrypto importPkcs1KeyData:keyData
                                               keyLengthBits:keyLengthBits
                                               keyIdentifier:privateKeyIdentifier
                                                   isPrivate:isPrivateKey];
    
    XCTAssertTrue((__bridge id)importKeyRef,@"Key import failed.");
    
    SecKeyRef keyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
    
    NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:ciphertextData padding:paddingType keyRef:keyRef];
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");
    XCTAssertTrue([decryptedData isEqualToData:expectedPlaintextData],@"Decrypted data is incorrect.");
}


//- (void)testRsaDecrypt_OaepData1
//{
//// NOTE: This test currently uses keys already generated and exported, so should the keys not be present, or be re-generated, the test data will be wrong
//NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
//NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
////    NSInteger keySizeBits = 1024;
////    [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
//
////    NSData *modulus = [QredoCrypto getModulusForIdentifier:publicKeyIdentifier];
////    XCTAssertNotNil(modulus, @"Modulus should not be nil.");
////    NSData *pubExponent = [QredoCrypto getPublicKeyExponentForIdentifier:publicKeyIdentifier];
////    XCTAssertNotNil(pubExponent, @"Public key exponent should not be nil.");
//
//// OAEP padded
//uint8_t encryptedDataArray[] = {0xB5,0xB5,0x8F,0xC1,0xC3,0x36,0xFA,0x7F,0x23,0x16,0xA5,0x53,0xD3,0x00,0xC0,0x05,0x58,0x2B,0x55,0x13,0x9E,0x0E,0xD7,0xAA,0x45,0x22,0x81,0xAB,0x1E,0x02,0xE2,0x0A,0x55,0x63,0x81,0x4D,0x6E,0x51,0x3C,0x1A,0x61,0x0A,0xC5,0x92,0xED,0x65,0x64,0x89,0x75,0xD6,0xFF,0x3F,0x91,0x25,0x6E,0x74,0xE1,0xC7,0x16,0x23,0xEF,0x9C,0x4C,0x50,0x39,0x77,0x78,0x93,0x31,0x56,0x9C,0x7B,0x69,0x66,0x64,0x06,0x8F,0x56,0x2E,0x55,0xBF,0xB9,0x63,0x49,0x07,0x5F,0xDC,0x0D,0x85,0x09,0x71,0xD2,0xE0,0xC6,0x8D,0xC4,0x3A,0xD8,0x45,0x0D,0x7E,0xCB,0x83,0xA2,0xD5,0xAA,0x71,0x65,0x03,0x6E,0x30,0xBB,0x46,0xD1,0xF3,0xF5,0xFD,0x3C,0x1B,0x28,0x97,0x20,0xE2,0x20,0x70,0x0E,0x99,0x00};
//NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
//
//uint8_t expectedPlainTextDataArray[] = {
//0x11
//};
//NSData *expectedPlainTextData = [NSData dataWithBytes:expectedPlainTextDataArray length:sizeof(expectedPlainTextDataArray) / sizeof(uint8_t)];
//
//QredoPadding padding = QredoPaddingOaep;
//
//SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
//NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
//
//XCTAssertNotNil(decryptedData, @"Decrypted data should not be nil.");
//XCTAssertTrue([decryptedData isEqualToData:expectedPlainTextData], @"Decrypted data is incorrect.");
//}
//
//- (void)testRsaDecrypt_OaepData2
//{
//// NOTE: This test currently uses keys already generated and exported, so should the keys not be present, or be re-generated, the test data will be wrong
//NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
//NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
////    NSInteger keySizeBits = 1024;
////    [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
//
////    NSData *modulus = [QredoCrypto getModulusForIdentifier:publicKeyIdentifier];
////    XCTAssertNotNil(modulus, @"Modulus should not be nil.");
////    NSData *pubExponent = [QredoCrypto getPublicKeyExponentForIdentifier:publicKeyIdentifier];
////    XCTAssertNotNil(pubExponent, @"Public key exponent should not be nil.");
//
//// OAEP padded
//uint8_t encryptedDataArray[] = {0xA7,0x33,0x65,0x1E,0x0A,0xBB,0x38,0x28,0x8F,0x3A,0x87,0x62,0x06,0x71,0x7B,0x5A,0xDA,0xA3,0xEC,0x1C,0xDF,0x89,0x1C,0xF4,0xD4,0x35,0x2E,0x46,0x69,0x91,0xCB,0x12,0x5B,0x47,0x79,0x51,0xED,0x05,0xB0,0x8A,0x96,0x49,0xB9,0x26,0xA5,0xEB,0xD4,0x53,0xA5,0xE0,0xEB,0x03,0xE9,0x56,0x4F,0x07,0x1C,0x76,0x2D,0x1D,0x59,0x37,0xE3,0x94,0xF4,0x3B,0x75,0x8D,0xCE,0x32,0x2C,0x43,0xB0,0xE5,0x3D,0x4E,0x86,0xB6,0x91,0x18,0x0F,0x35,0x86,0x8E,0x72,0xA0,0xF9,0x8A,0x9F,0x18,0xA5,0x66,0xFD,0x76,0x9D,0x68,0x6B,0xCF,0x54,0x5D,0x9F,0xA5,0x08,0xBF,0x47,0x4F,0x1C,0xC0,0xFA,0x92,0x20,0xD1,0x6F,0x24,0x33,0x1D,0xAC,0x0A,0x65,0x11,0x34,0x11,0x05,0xB2,0xB6,0xF7,0xBC,0xA3};
//NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
//
//uint8_t expectedPlainTextDataArray[] = {
//0x11
//};
//NSData *expectedPlainTextData = [NSData dataWithBytes:expectedPlainTextDataArray length:sizeof(expectedPlainTextDataArray) / sizeof(uint8_t)];
//
//QredoPadding padding = QredoPaddingOaep;
//
//SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
//NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
//
//XCTAssertNotNil(decryptedData, @"Decrypted data should not be nil.");
//XCTAssertTrue([decryptedData isEqualToData:expectedPlainTextData], @"Decrypted data is incorrect.");
//}
//
//- (void)testRsaDecrypt_Pkcs1Data1
//{
//// NOTE: This test uses keys already generated and exported, so should the keys not be present, or be re-generated, the test data will be wrong
//NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
//NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
////    NSInteger keySizeBits = 1024;
////    [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
//
////    NSData *modulus = [QredoCrypto getModulusForIdentifier:publicKeyIdentifier];
////    XCTAssertNotNil(modulus, @"Modulus should not be nil.");
////    NSData *pubExponent = [QredoCrypto getPublicKeyExponentForIdentifier:publicKeyIdentifier];
////    XCTAssertNotNil(pubExponent, @"Public key exponent should not be nil.");
//
//// PKCS1 padded
//uint8_t encryptedDataArray[] = {0x01,0x67,0x41,0xAA,0x05,0x70,0xC4,0x91,0xC2,0xEC,0xBE,0xB4,0x33,0x2B,0x4D,0x88,0x57,0xB5,0x50,0xCB,0x35,0x6C,0x09,0x0A,0x9B,0x01,0x06,0xB0,0xE0,0x15,0xBE,0xAF,0x62,0x65,0xEF,0x04,0xC4,0xF4,0x0F,0x2B,0xDB,0x3C,0xEC,0xA9,0x2E,0xB2,0xBC,0x0E,0x14,0x84,0x98,0xCA,0x5B,0x2E,0xC6,0xB9,0x7B,0xCC,0x16,0xD7,0x65,0xE8,0xA0,0xCE,0x1D,0xB4,0xD1,0xC6,0x2B,0x33,0x0A,0x97,0x74,0xDD,0x0B,0x8E,0xFB,0x2B,0xDF,0x46,0x5C,0x3D,0xFB,0xF5,0xB4,0x98,0xC7,0x1B,0x2F,0x42,0xDE,0xE3,0x96,0xCF,0x79,0xD8,0x44,0xB1,0xCA,0xD8,0x83,0x3E,0x85,0x58,0xA2,0x59,0x60,0xBB,0xE2,0xB8,0xBF,0x07,0x04,0xDD,0xE3,0xDA,0x1E,0x84,0x05,0xD8,0x24,0x7D,0xEE,0x7B,0xCF,0xAE,0x5B,0x97};
//NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
//
//uint8_t expectedPlainTextDataArray[] = {
//0x11
//};
//NSData *expectedPlainTextData = [NSData dataWithBytes:expectedPlainTextDataArray length:sizeof(expectedPlainTextDataArray) / sizeof(uint8_t)];
//
//QredoPadding padding = QredoPaddingPkcs1;
//
//SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
//NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
//
//XCTAssertNotNil(decryptedData, @"Decrypted data should not be nil.");
//XCTAssertTrue([decryptedData isEqualToData:expectedPlainTextData], @"Decrypted data is incorrect.");
//}
//
//- (void)testRsaDecrypt_Pkcs1Data2
//{
//// NOTE: This test uses keys already generated and exported, so should the keys not be present, or be re-generated, the test data will be wrong
//NSString *publicKeyIdentifier = @"com.qredo.TestPublicKey";
//NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKey";
////    NSInteger keySizeBits = 1024;
////    [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
//
////    NSData *modulus = [QredoCrypto getModulusForIdentifier:publicKeyIdentifier];
////    XCTAssertNotNil(modulus, @"Modulus should not be nil.");
////    NSData *pubExponent = [QredoCrypto getPublicKeyExponentForIdentifier:publicKeyIdentifier];
////    XCTAssertNotNil(pubExponent, @"Public key exponent should not be nil.");
//
//// PKCS1 padded
//uint8_t encryptedDataArray[] = {0x7F,0x04,0x99,0x98,0x4A,0x52,0x18,0xED,0x56,0x25,0xAD,0x2B,0x00,0xD3,0xF0,0x90,0x94,0x1D,0x07,0x80,0x69,0xFD,0xD5,0xD0,0x86,0x2A,0x64,0x7F,0x86,0x00,0x4D,0xD9,0x4F,0x2C,0xD0,0xD3,0xCB,0xB9,0xA5,0x40,0xDD,0x84,0xAF,0xEF,0xFD,0xDE,0xD2,0x9C,0xD7,0xA3,0x7D,0xC8,0x10,0x3C,0x79,0xD7,0x54,0xFC,0x35,0xD0,0x79,0x1F,0xC5,0xB8,0x62,0x52,0x55,0x59,0xA4,0x75,0xD2,0xE8,0x66,0x77,0x1D,0x6B,0x18,0xAC,0x80,0x35,0xEF,0xDA,0x70,0x7F,0xD2,0xF5,0x09,0x7D,0x2C,0x74,0xB0,0xF9,0xAA,0x66,0x12,0xA0,0x7E,0x9C,0x8D,0xFB,0xD7,0x92,0xDC,0x1B,0x6D,0x2E,0xE9,0x7A,0xE1,0xB7,0x54,0xAB,0x5E,0xB4,0x3A,0xFD,0xD1,0xCD,0xF4,0x05,0xBF,0xE6,0x43,0x1E,0x79,0x93,0xA9,0xD4};
//NSData *encryptedData = [NSData dataWithBytes:encryptedDataArray length:sizeof(encryptedDataArray) / sizeof(uint8_t)];
//
//uint8_t expectedPlainTextDataArray[] = {
//0x11
//};
//NSData *expectedPlainTextData = [NSData dataWithBytes:expectedPlainTextDataArray length:sizeof(expectedPlainTextDataArray) / sizeof(uint8_t)];
//
//QredoPadding padding = QredoPaddingPkcs1;
//
//SecKeyRef privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyIdentifier];
//NSData *decryptedData = [QredoCrypto rsaDecryptCipherTextData:encryptedData padding:padding keyRef:privateKeyRef];
//
//XCTAssertNotNil(decryptedData, @"Decrypted data should not be nil.");
//XCTAssertTrue([decryptedData isEqualToData:expectedPlainTextData], @"Decrypted data is incorrect.");
//}

-(void)testDeleteAllKeysInAppleKeychain {
    //Generate 2 sets of keys, check both exist, delete, check neither exist
    
    NSString *publicKeyIdentifier1 = @"com.qredo.TestPublicKeyDelete1";
    NSString *privateKeyIdentifier1 = @"com.qredo.TestPrivateKeyDelete1";
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef1 = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier1 privateKeyIdentifier:privateKeyIdentifier1 persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef1,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef1.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef1.privateKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    NSData *keyData = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier1];
    keyData = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier1];
    
    NSString *publicKeyIdentifier2 = @"com.qredo.TestPublicKeyDelete2";
    NSString *privateKeyIdentifier2 = @"com.qredo.TestPrivateKeyDelete2";
    QredoSecKeyRefPair *keyPairRef2 = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier2 privateKeyIdentifier:privateKeyIdentifier2 persistInAppleKeychain:YES];
    XCTAssertNotNil(keyPairRef2,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef2.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef2.privateKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    keyData = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier2];
    XCTAssertNotNil(keyData,@"Public key data 2 should not be nil.");
    keyData = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier2];
    XCTAssertNotNil(keyData,@"Private key data 2 should not be nil.");
    
    BOOL expectedSuccess = YES;
    BOOL success = [QredoCrypto deleteAllKeysInAppleKeychain];
    XCTAssertTrue(success == expectedSuccess,@"Delete keys should not have failed.");
    
    //Now confirm neither key data is found
    
    NSData *publicKeyData1;
    NSData *privateKeyData1;
    NSData *publicKeyData2;
    NSData *privateKeyData2;
    
    @try {
        publicKeyData1 = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier1];
    } @catch (NSException *exception){
        if (![exception.name isEqualToString:@"QredoKeyIdentifierNotFound"])XCTFail(@"Error happened or keys are persisted.");
    } @finally {
        XCTAssertNil(publicKeyData1,@"Public key data 1 should be nil.");
    }
    
    @try {
        privateKeyData1 = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier1];
    } @catch (NSException *exception){
        if (![exception.name isEqualToString:@"QredoKeyIdentifierNotFound"])XCTFail(@"Error happened or keys are persisted.");
    } @finally {
        XCTAssertNil(privateKeyData1,@"Private key data 1 should be nil.");
    }
    
    @try {
        publicKeyData2 = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier2];
    } @catch (NSException *exception){
        if (![exception.name isEqualToString:@"QredoKeyIdentifierNotFound"])XCTFail(@"Error happened or keys are persisted.");
    } @finally {
        XCTAssertNil(publicKeyData2,@"Public key data 2 should be nil.");
    }
    
    @try {
        privateKeyData2 = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier2];
    } @catch (NSException *exception){
        if (![exception.name isEqualToString:@"QredoKeyIdentifierNotFound"])XCTFail(@"Error happened or keys are persisted.");
    } @finally {
        XCTAssertNil(privateKeyData2,@"Private key data 2 should be nil.");
    }
}


-(void)testDeleteAllKeysInAppleKeychain_NoKeysPresent {
    //No keys present (so nothing to delete) should not return error
    BOOL expectedSuccess = YES;
    BOOL success = [QredoCrypto deleteAllKeysInAppleKeychain];
    
    XCTAssertTrue(success == expectedSuccess,@"Delete keys should not have failed.");
}


-(void)testDeleteKeyInAppleKeychainWithIdentifier {
    //Generate 2 sets of keys, check both exist, delete first, check other still exists
    
    NSString *publicKeyIdentifier1 = @"com.qredo.TestPublicKeyDelete1";
    NSString *privateKeyIdentifier1 = @"com.qredo.TestPrivateKeyDelete1";
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef1 = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier1 privateKeyIdentifier:privateKeyIdentifier1 persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef1,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef1.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef1.privateKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    NSData *keyData = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier1];
    keyData = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier1];
    
    NSString *publicKeyIdentifier2 = @"com.qredo.TestPublicKeyDelete2";
    NSString *privateKeyIdentifier2 = @"com.qredo.TestPrivateKeyDelete2";
    QredoSecKeyRefPair *keyPairRef2 = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier2 privateKeyIdentifier:privateKeyIdentifier2 persistInAppleKeychain:YES];
    XCTAssertNotNil(keyPairRef2,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef2.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef2.privateKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    keyData = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier2];
    XCTAssertNotNil(keyData,@"Public key data 2 should not be nil.");
    keyData = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier2];
    XCTAssertNotNil(keyData,@"Private key data 2 should not be nil.");
    
    BOOL expectedSuccess = YES;
    
    //Only delete 1 key, check that other key data still exists
    BOOL success = [QredoCrypto deleteKeyInAppleKeychainWithIdentifier:publicKeyIdentifier2];
    XCTAssertTrue(success == expectedSuccess,@"Delete keys should not have failed.");
    
    //Now confirm all keys data is found, except the one deleted
    keyData = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier1];
    XCTAssertNotNil(keyData,@"Public key data 1 should not be nil.");
    keyData = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier1];
    
    NSData *publicKeyData2;
    
    @try {
        publicKeyData2 = [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier2];
    } @catch (NSException *exception){
        if (![exception.name isEqualToString:@"QredoKeyIdentifierNotFound"])XCTFail(@"Error happened or keys are persisted.");
    } @finally {
        XCTAssertNil(publicKeyData2,@"Public key data 2 should be nil.");
    }
    
    keyData = [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier2];
    XCTAssertNotNil(keyData,@"Private key data 2 should not be nil.");
}


-(void)testDeleteKeyInAppleKeychainWithIdentifier_NoKeysPresent {
    //No keys present (so nothing to delete) should return error when deleting a specific key
    NSString *keyIdentifier = @"com.qredo.TestMissingKey1";
    BOOL expectedSuccess = NO;
    BOOL success = [QredoCrypto deleteKeyInAppleKeychainWithIdentifier:keyIdentifier];
    
    XCTAssertTrue(success == expectedSuccess,@"Delete keys should have failed (requested key not present).");
}


-(void)testGetKeyDataForIdentifier_Public {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKeyExport1";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKeyExport1";
    NSInteger keySizeBits = 1024;
    
    
    
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
}


-(void)testGetKeyDataForIdentifier_Private {
    NSString *publicKeyIdentifier = @"com.qredo.TestPublicKeyExport1";
    NSString *privateKeyIdentifier = @"com.qredo.TestPrivateKeyExport1";
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
    
    [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
}


-(void)testGetKeyDataForIdentifier_ManyGenerates {
    NSString *prefix = @"keyIdentifier";
    NSString *publicSuffix = @".public";
    NSString *privateSuffix = @".private";
    
    //NSInteger keySizeBits = 2048;
    NSInteger keySizeBits = 1024;
    QredoSecKeyRefPair *keyPairRef = nil;
    
    //for (int generateCounter = 0; generateCounter < 99999; generateCounter++) {
    for (int generateCounter = 0; generateCounter < 10; generateCounter++){
        NSString *publicKeyIdentifier = [NSString stringWithFormat:@"%@%d%@",prefix,generateCounter,publicSuffix];
        NSString *privateKeyIdentifier = [NSString stringWithFormat:@"%@%d%@",prefix,generateCounter,privateSuffix];
        keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier privateKeyIdentifier:privateKeyIdentifier persistInAppleKeychain:YES];
        XCTAssertNotNil(keyPairRef,"RSA key generation %d failed (nil object returned).",generateCounter);
        XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation %d failed (nil public key ref returned).",generateCounter);
        XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation %d failed (nil private key ref returned).",generateCounter);
        
        //for (int getCounter = 0; getCounter < 1000; getCounter++) {
        for (int getCounter = 0; getCounter < 10; getCounter++){
            [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier];
            [QredoCrypto getKeyDataForIdentifier:privateKeyIdentifier];
        }
    }
}


-(void)testGetKeyDataForIdentifier_ConcurrentUse {
    //This test will attempt to call [QredoCrypto getKeyDataForIdentifier:] simultaneously from multiple threads.
    //Have seen logs where 2 threads calling this method at same time (with different identifiers) have both
    //returned nil, crashing test.  Trying to recreate this scenario.
    NSString *publicKeyIdentifier1 = @"31b0223f088e9409463381d627b4e71a71d162788ac93973af9a9b56738c0310zzzz.public";
    NSString *privateKeyIdentifier1 = @"31b0223f088e9409463381d627b4e71a71d162788ac93973af9a9b56738c0310zzzz.private";
    NSString *publicKeyIdentifier2 = @"a5db1c763d8f9bfa3a90d4a4508047858e800c408429ef45dd841b9dfd1da1ddzzzz.public";
    NSString *privateKeyIdentifier2 = @"a5db1c763d8f9bfa3a90d4a4508047858e800c408429ef45dd841b9dfd1da1ddzzzz.private";
    NSInteger keySizeBits = 2048;
    
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier1 privateKeyIdentifier:privateKeyIdentifier1 persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation 1 failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation 1 failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation 1 failed (nil private key ref returned).");
    
    keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:keySizeBits publicKeyIdentifier:publicKeyIdentifier2 privateKeyIdentifier:privateKeyIdentifier2 persistInAppleKeychain:YES];
    XCTAssertNotNil(keyPairRef,"RSA key generation 2 failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation 2 failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation 2 failed (nil private key ref returned).");
    
    __block XCTestExpectation *getCompleteExpectation1 = [self expectationWithDescription:@"Get 1 completed"];
    __block XCTestExpectation *getCompleteExpectation2 = [self expectationWithDescription:@"Get 2 completed"];
    __block XCTestExpectation *getCompleteExpectation3 = [self expectationWithDescription:@"Get 3 completed"];
    __block XCTestExpectation *getCompleteExpectation4 = [self expectationWithDescription:@"Get 4 completed"];
    dispatch_queue_t testQueue1 = dispatch_queue_create("testQueue1",nil);
    dispatch_queue_t testQueue2 = dispatch_queue_create("testQueue2",nil);
    dispatch_queue_t testQueue3 = dispatch_queue_create("testQueue3",nil);
    dispatch_queue_t testQueue4 = dispatch_queue_create("testQueue4",nil);
    dispatch_async(testQueue1,^{
        [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier1];
        [getCompleteExpectation1 fulfill];
    });
    dispatch_async(testQueue2,^{
        [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier2];
        [getCompleteExpectation2 fulfill];
    });
    dispatch_async(testQueue3,^{
        [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier1];
        [getCompleteExpectation3 fulfill];
    });
    dispatch_async(testQueue4,^{
        [QredoCrypto getKeyDataForIdentifier:publicKeyIdentifier2];
        [getCompleteExpectation4 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *error) {
                                     //avoiding exception when 'fulfill' is called after timeout
                                     getCompleteExpectation1 = nil;
                                     getCompleteExpectation2 = nil;
                                     getCompleteExpectation3 = nil;
                                     getCompleteExpectation4 = nil;
                                 }];
}


-(NSData *)stripPublicKeyHeader:(NSData *)d_key {
    //Skip ASN.1 public key header
    if (d_key == nil)return(nil);
    
    unsigned long len = [d_key length];
    
    if (!len)return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int idx    = 0;
    
    if (c_key[idx++] != 0x30)return(nil);
    
    if (c_key[idx] > 0x80)idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    //PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,0x0d,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x01,
        0x01,0x05,0x00 };
    
    if (memcmp(&c_key[idx],seqiod,15))return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03)return(nil);
    
    if (c_key[idx] > 0x80)idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0')return(nil);
    
    //Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}


-(void)testImportPublicKey {
    //NOTE: This test will fail if the key has already been imported (even with different identifier)
    
    //http://blog.flirble.org/2011/01/05/rsa-public-key-openssl-ios/
    //and
    //http://stackoverflow.com/questions/17623046/secitemcopymatching-returns-nil-value-without-any-error
    
    //Important note:
    //iOS wants PKCS#1 ASN.1 DER encoded key with stripped header.. Otherwise you'll not get kSecReturnRef as a result
    //
    //Steps to generate key:
    
    //$ openssl genrsa -out test_private.pem 1024
    //Generating RSA private key, 1024 bit long modulus
    //......................++++++
    //......................................++++++
    //e is 65537 (0x10001)
    
    //$ cat test_private.pem
    //-----BEGIN RSA PRIVATE KEY-----
    //MIICXQIBAAKBgQDNBNMX4RsVupfeApqgic4+Sua99Scdu86n/t9g2jexub4Y9ALG
    //KocqB37VYUFN64wBfqw0HUW5JOaRlYveah4Wrt8xNMhlEllp4hgm31XjO8cHXNQ4
    //m2/TZ/YHd4B0spkRdENoEEIHlZD1qp5G7R0qeoqYDzSeWaqLKT6N276K0QIDAQAB
    //AoGBAMfbbyi1IWEiP8+FvFTJYctp2tvMszASF9e+5uUUdPyE9CKBJH8nkBHRsruy
    //DiY2e4otgRNggcqFhVrgbLQJwH9fmC1o8iM5zUxnbbliroLXtYzHfrp3VeKIWw7e
    //El+duSb3Hr+aOaXVARK/Ji7kIEwTLCX1JcXV5UOzTDXTDtENAkEA5lMMsq+0oTwA
    //BgYDew5OTL6jRP1K4m6VSkHzurDbEbSq1NGlawJ5xcFjaN1NDyehuH5Ko3jRUjDI
    //sp07k3Br+wJBAOPfnCakCeBBzQo0K8wD414JApfBYPMqiDW7QsnAuRyXbiKPn0Zw
    //mrU6b98KMGwPrv7h8GlTkJ6vqx2tbiiZPqMCQQCMJeDGIdAhg+bnw2T+zderLx0d
    //75pPacaBptvtr4u9nFeOo/qpwJnkUSZyOqaXICBxqLc1/WAxSOn2dWI49uFdAkAu
    //AuuzvbGkz4SIR+qEAlD5ntYgMFLUJsVkHBCrTjfSdx0s61Uc0wXaDBeksJkAaNZL
    //7vEtQ0tTT2M81dUFa5QDAkASFPisNywNgTcUdr3CojoUGd4hl0zs/4/Tg+FtwMpO
    //BnFNTc7HMBuyYeGKXMDdvoa6CuPmLN1ZiceFMOJquRgX
    //-----END RSA PRIVATE KEY-----
    
    //// Not necessary
    //// $ openssl rsa -in test_private.pem -pubout > test_public.pem
    ////    writing RSA key
    ////
    //// $ cat test_public.pem
    ////    -----BEGIN PUBLIC KEY-----
    ////    MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDNBNMX4RsVupfeApqgic4+Sua9
    ////    9Scdu86n/t9g2jexub4Y9ALGKocqB37VYUFN64wBfqw0HUW5JOaRlYveah4Wrt8x
    ////    NMhlEllp4hgm31XjO8cHXNQ4m2/TZ/YHd4B0spkRdENoEEIHlZD1qp5G7R0qeoqY
    ////    DzSeWaqLKT6N276K0QIDAQAB
    ////    -----END PUBLIC KEY-----
    
    //$ openssl rsa -outform der -in test_private.pem -out test_private.der
    //writing RSA key
    
    //$ cat test_private.der
    //0?]???????????>J??'?Χ??`?7?????*?*~?aAM?~?4E?$摕??j??14?eYi?&?U?;?\?8?o?g?w?t??tChB?????F?*z??4?Y??)>?۾??????o(?!a"?υ?T?a?i??̳0׾??t???"?$'?Ѳ??&6A?S?`?ʅ?Z?l? ?_?-h?#9?Lgm?b??׵??~?wU?[?_??&???9???&.? L,%?%???C?L5??
    //????<{NL??D?J?n?JA?????ѥky??ch?M'??~J?x?R0Ȳ?;?pk?A?ߜ&?   ?A?
    //4+??^   ??`?*?5?B????n"??Fp??:o?
    //0l????iS?????n(?>?A?%??!?!????d??׫/?OiƁ???????W???????Q&r:??  q??5?`1H??ub8??]@.볽??τ?G?P??? 0R?&?d?N7?w,?U??
    //?7v?¢:?!?L???Ӄ?m??NqMM??0a?\?ݾ??                                                                             ???h?K??-CKSOc<??k?@??7,
    //??,?Y?ǅ0?j?
    
    //3082 025d 0201 0002 8181 00cd 04d3 17e1
    //1b15 ba97 de02 9aa0 89ce 3e4a e6bd f527
    //1dbb cea7 fedf 60da 37b1 b9be 18f4 02c6
    //2a87 2a07 7ed5 6141 4deb 8c01 7eac 341d
    //45b9 24e6 9195 8bde 6a1e 16ae df31 34c8
    //6512 5969 e218 26df 55e3 3bc7 075c d438
    //9b6f d367 f607 7780 74b2 9911 7443 6810
    //4207 9590 f5aa 9e46 ed1d 2a7a 8a98 0f34
    //9e59 aa8b 293e 8ddb be8a d102 0301 0001
    //0281 8100 c7db 6f28 b521 6122 3fcf 85bc
    //54c9 61cb 69da dbcc b330 1217 d7be e6e5
    //1474 fc84 f422 8124 7f27 9011 d1b2 bbb2
    //0e26 367b 8a2d 8113 6081 ca85 855a e06c
    //b409 c07f 5f98 2d68 f223 39cd 4c67 6db9
    //62ae 82d7 b58c c77e ba77 55e2 885b 0ede
    //125f 9db9 26f7 1ebf 9a39 a5d5 0112 bf26
    //2ee4 204c 132c 25f5 25c5 d5e5 43b3 4c35
    //d30e d10d 0241 00e6 530c b2af b4a1 3c00
    //0606 037b 0e4e 4cbe a344 fd4a e26e 954a
    //41f3 bab0 db11 b4aa d4d1 a56b 0279 c5c1
    //6368 dd4d 0f27 a1b8 7e4a a378 d152 30c8
    //b29d 3b93 706b fb02 4100 e3df 9c26 a409
    //e041 cd0a 342b cc03 e35e 0902 97c1 60f3
    //2a88 35bb 42c9 c0b9 1c97 6e22 8f9f 4670
    //9ab5 3a6f df0a 306c 0fae fee1 f069 5390
    //9eaf ab1d ad6e 2899 3ea3 0241 008c 25e0
    //c621 d021 83e6 e7c3 64fe cdd7 ab2f 1d1d
    //ef9a 4f69 c681 a6db edaf 8bbd 9c57 8ea3
    //faa9 c099 e451 2672 3aa6 9720 2071 a8b7
    //35fd 6031 48e9 f675 6238 f6e1 5d02 402e
    //02eb b3bd b1a4 cf84 8847 ea84 0250 f99e
    //d620 3052 d426 c564 1c10 ab4e 37d2 771d
    //2ceb 551c d305 da0c 17a4 b099 0068 d64b
    //eef1 2d43 4b53 4f63 3cd5 d505 6b94 0302
    //4012 14f8 ac37 2c0d 8137 1476 bdc2 a23a
    //1419 de21 974c ecff 8fd3 83e1 6dc0 ca4e
    //0671 4d4d cec7 301b b261 e18a 5cc0 ddbe
    //86ba 0ae3 e62c dd59 89c7 8530 e26a b918
    //17
    
    //$ openssl rsa -outform der -in test_private.pem -pubout > test_public.der
    //writing RSA key
    
    //$ cat test_public.der
    //??0?????????????>J??'?Χ??`?7?????*?*~?aAM?~?4E?$摕??j??14?eYi?&?U?;?\?8?o?g?w?t??tChB?????F?*z??4?Y??)>?۾??
    
    //3081 9f30 0d06 092a 8648 86f7 0d01 0101
    //0500 0381 8d00 3081 8902 8181 00cd 04d3
    //17e1 1b15 ba97 de02 9aa0 89ce 3e4a e6bd
    //f527 1dbb cea7 fedf 60da 37b1 b9be 18f4
    //02c6 2a87 2a07 7ed5 6141 4deb 8c01 7eac
    //341d 45b9 24e6 9195 8bde 6a1e 16ae df31
    //34c8 6512 5969 e218 26df 55e3 3bc7 075c
    //d438 9b6f d367 f607 7780 74b2 9911 7443
    //6810 4207 9590 f5aa 9e46 ed1d 2a7a 8a98
    //0f34 9e59 aa8b 293e 8ddb be8a d102 0301
    //0001
    
    
    
    NSString *keyIdentifier = @"com.qredo.TestPublicKeyImport1";
    NSInteger keySizeBits = 1024;
    BOOL isPrivate = NO;
    
    //From that $ cat test_public.der
    uint8_t keyDataArray[] = {
        0x30,0x81,0x9f,0x30,0x0d,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x01,0x01,
        0x05,0x00,0x03,0x81,0x8d,0x00,0x30,0x81,0x89,0x02,0x81,0x81,0x00,0xcd,0x04,0xd3,
        0x17,0xe1,0x1b,0x15,0xba,0x97,0xde,0x02,0x9a,0xa0,0x89,0xce,0x3e,0x4a,0xe6,0xbd,
        0xf5,0x27,0x1d,0xbb,0xce,0xa7,0xfe,0xdf,0x60,0xda,0x37,0xb1,0xb9,0xbe,0x18,0xf4,
        0x02,0xc6,0x2a,0x87,0x2a,0x07,0x7e,0xd5,0x61,0x41,0x4d,0xeb,0x8c,0x01,0x7e,0xac,
        0x34,0x1d,0x45,0xb9,0x24,0xe6,0x91,0x95,0x8b,0xde,0x6a,0x1e,0x16,0xae,0xdf,0x31,
        0x34,0xc8,0x65,0x12,0x59,0x69,0xe2,0x18,0x26,0xdf,0x55,0xe3,0x3b,0xc7,0x07,0x5c,
        0xd4,0x38,0x9b,0x6f,0xd3,0x67,0xf6,0x07,0x77,0x80,0x74,0xb2,0x99,0x11,0x74,0x43,
        0x68,0x10,0x42,0x07,0x95,0x90,0xf5,0xaa,0x9e,0x46,0xed,0x1d,0x2a,0x7a,0x8a,0x98,
        0x0f,0x34,0x9e,0x59,0xaa,0x8b,0x29,0x3e,0x8d,0xdb,0xbe,0x8a,0xd1,0x02,0x03,0x01,
        0x00,0x01
    };
    
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    [QredoCrypto importPkcs1KeyData:[self stripPublicKeyHeader:keyData]
                      keyLengthBits:keySizeBits
                      keyIdentifier:keyIdentifier
                          isPrivate:isPrivate];
    
    //Confirm key imported is present
    [QredoCrypto getKeyDataForIdentifier:keyIdentifier];
}


-(void)testImportPublicKey_IncorrectKeyLength_TooLarge {
    //This test demonstrates that the SecItemAdd does not validate the keysize argument.
    
    //NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSString *keyIdentifier = @"com.qredo.TestPublicKeyImport1";
    NSInteger keySizeBits = 2048; //Give the incorrect key length (larger than actual key length)
    BOOL isPrivate = NO;
    
    //1024 bit key
    uint8_t keyDataArray[] = { 0x30,0x81,0x88,0x02,0x81,0x80,0x9C,0x59,0xCE,0xDB,0xAD,0x8B,0x9A,0x7F,0xAD,0xC2,0xD6,0x1F,0x06,0x3D,0x17,0x5C,0x1D,0x10,0x1C,0x62,0x57,0x10,0xC9,0xB6,0xA6,0x49,0xBE,0x0C,0xF0,0x89,0x66,0x1B,0xA1,0xBB,0x48,0xC2,0x5A,0xAB,0x92,0xDB,0x6F,0x1A,0x2F,0x80,0x74,0x1D,0xDD,0xCC,0x80,0xF3,0x01,0x59,0x4E,0xB5,0x6F,0x2A,0x7E,0x63,0x1F,0xE4,0xFB,0xA1,0xEB,0x98,0xB3,0x32,0xBA,0x1C,0xA7,0x23,0x49,0x7F,0xCD,0xAE,0x32,0x88,0xF5,0x55,0xC4,0x96,0x64,0xC8,0x32,0x5F,0x31,0x83,0x43,0x5B,0x4C,0xB2,0x1C,0xC6,0x3C,0x50,0xB2,0x35,0xF2,0xF5,0x08,0x0D,0x77,0xDB,0x14,0x8C,0xA1,0xAE,0x3A,0x5B,0x80,0x5C,0x04,0x10,0x5E,0xD9,0x5C,0x73,0xC6,0xAC,0xAA,0x30,0xFC,0x75,0x85,0x64,0x58,0x08,0x70,0xC9,0x02,0x03,0x01,0x00,0x01 };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    XCTAssertThrowsSpecificNamed([QredoCrypto importPkcs1KeyData:keyData
                                                   keyLengthBits:keySizeBits
                                                   keyIdentifier:keyIdentifier
                                                       isPrivate:isPrivate],
                                 NSException,
                                 @"QredoCryptoImportPublicKeyInvalidFormat",
                                 @"Should have failed key import.");
}


-(void)testImportPublicKey_IncorrectKeyLength_TooSmall {
    //This test demonstrates that the SecItemAdd does not validate the keysize argument.
    
    //NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSString *keyIdentifier = @"com.qredo.TestPublicKeyImport1";
    NSInteger keySizeBits = 512; //Give the incorrect key length (smaller than actual key length)
    BOOL isPrivate = NO;
    
    //1024 bit key
    uint8_t keyDataArray[] = { 0x30,0x81,0x88,0x02,0x81,0x80,0x9C,0x59,0xCE,0xDB,0xAD,0x8B,0x9A,0x7F,0xAD,0xC2,0xD6,0x1F,0x06,0x3D,0x17,0x5C,0x1D,0x10,0x1C,0x62,0x57,0x10,0xC9,0xB6,0xA6,0x49,0xBE,0x0C,0xF0,0x89,0x66,0x1B,0xA1,0xBB,0x48,0xC2,0x5A,0xAB,0x92,0xDB,0x6F,0x1A,0x2F,0x80,0x74,0x1D,0xDD,0xCC,0x80,0xF3,0x01,0x59,0x4E,0xB5,0x6F,0x2A,0x7E,0x63,0x1F,0xE4,0xFB,0xA1,0xEB,0x98,0xB3,0x32,0xBA,0x1C,0xA7,0x23,0x49,0x7F,0xCD,0xAE,0x32,0x88,0xF5,0x55,0xC4,0x96,0x64,0xC8,0x32,0x5F,0x31,0x83,0x43,0x5B,0x4C,0xB2,0x1C,0xC6,0x3C,0x50,0xB2,0x35,0xF2,0xF5,0x08,0x0D,0x77,0xDB,0x14,0x8C,0xA1,0xAE,0x3A,0x5B,0x80,0x5C,0x04,0x10,0x5E,0xD9,0x5C,0x73,0xC6,0xAC,0xAA,0x30,0xFC,0x75,0x85,0x64,0x58,0x08,0x70,0xC9,0x02,0x03,0x01,0x00,0x01 };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    XCTAssertThrowsSpecificNamed([QredoCrypto importPkcs1KeyData:keyData
                                                   keyLengthBits:keySizeBits
                                                   keyIdentifier:keyIdentifier
                                                       isPrivate:isPrivate],
                                 NSException,
                                 @"QredoCryptoImportPublicKeyInvalidFormat",
                                 @"Should have failed key import.");
}


-(void)testImportPublicKeyAndEncrypt {
    //NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSString *keyIdentifier = @"com.qredo.TestPrivateKeyImport1";
    NSInteger keySizeBits = 1024;
    BOOL isPrivate = NO;
    
    //From that $ cat test_public.der
    uint8_t keyDataArray[] = {
        0x30,0x81,0x9f,0x30,0x0d,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x01,0x01,
        0x05,0x00,0x03,0x81,0x8d,0x00,0x30,0x81,0x89,0x02,0x81,0x81,0x00,0xcd,0x04,0xd3,
        0x17,0xe1,0x1b,0x15,0xba,0x97,0xde,0x02,0x9a,0xa0,0x89,0xce,0x3e,0x4a,0xe6,0xbd,
        0xf5,0x27,0x1d,0xbb,0xce,0xa7,0xfe,0xdf,0x60,0xda,0x37,0xb1,0xb9,0xbe,0x18,0xf4,
        0x02,0xc6,0x2a,0x87,0x2a,0x07,0x7e,0xd5,0x61,0x41,0x4d,0xeb,0x8c,0x01,0x7e,0xac,
        0x34,0x1d,0x45,0xb9,0x24,0xe6,0x91,0x95,0x8b,0xde,0x6a,0x1e,0x16,0xae,0xdf,0x31,
        0x34,0xc8,0x65,0x12,0x59,0x69,0xe2,0x18,0x26,0xdf,0x55,0xe3,0x3b,0xc7,0x07,0x5c,
        0xd4,0x38,0x9b,0x6f,0xd3,0x67,0xf6,0x07,0x77,0x80,0x74,0xb2,0x99,0x11,0x74,0x43,
        0x68,0x10,0x42,0x07,0x95,0x90,0xf5,0xaa,0x9e,0x46,0xed,0x1d,0x2a,0x7a,0x8a,0x98,
        0x0f,0x34,0x9e,0x59,0xaa,0x8b,0x29,0x3e,0x8d,0xdb,0xbe,0x8a,0xd1,0x02,0x03,0x01,
        0x00,0x01
    };
    
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    SecKeyRef importKeyRef = [QredoCrypto importPkcs1KeyData:[self stripPublicKeyHeader:keyData]
                                               keyLengthBits:keySizeBits
                                               keyIdentifier:keyIdentifier
                                                   isPrivate:isPrivate];
    
    XCTAssertTrue((__bridge id)importKeyRef,@"Key import failed.");
    
    uint8_t plainTextDataArray[] = {
        0x11
    };
    NSData *plainTextData = [NSData dataWithBytes:plainTextDataArray length:sizeof(plainTextDataArray) / sizeof(uint8_t)];
    
    QredoPadding padding = QredoPaddingOaep;
    
    SecKeyRef publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:keyIdentifier];
    NSData *encryptedData = [QredoCrypto rsaEncryptPlainTextData:plainTextData padding:padding keyRef:publicKeyRef];
    XCTAssertNotNil(encryptedData,@"Encrypted data should not be nil.");
}


-(void)testImportPrivateKey_ManualKeyDataFromBouncyCastle {
    //NOTE: This test will fail if the key has already been imported (even with different identifier)
    NSString *keyIdentifier = @"com.qredo.TestPrivateKeyImport1";
    NSInteger keySizeBits = 1024;
    BOOL isPrivate = YES;
    
    //Manual key data from Bouncy Castle
    uint8_t keyDataArray[] = { 0x30,0x82,0x02,0x5B,0x02,0x01,0x00,0x02,0x81,0x81,0x00,0xB8,0x8C,0xAF,0x43,0xFB,0x4B,0x97,0x6F,0xE6,0x98,0xAC,0x59,0xEE,0xAF,0xED,0x2B,0xD3,0xBC,0x30,0x5A,0x78,0x2B,0xB6,0x65,0x60,0xB3,0xE8,0xD1,0xAD,0xCD,0xC8,0x7E,0x31,0x43,0xD5,0x9F,0x44,0x42,0x54,0x74,0xED,0xD0,0x1B,0x09,0xBE,0xD8,0xE7,0x57,0xE7,0x40,0x4F,0x80,0x1A,0xAB,0x9B,0xA6,0xB1,0x20,0xE3,0x42,0xBB,0x79,0x9A,0xEA,0xEB,0x58,0x67,0x5C,0x48,0x04,0x16,0x9F,0x47,0xA7,0x77,0x23,0x04,0xEA,0xAF,0xBE,0xB9,0xB3,0xEC,0x86,0xE2,0xB4,0x2F,0x62,0x91,0x31,0x2D,0x52,0x26,0xAE,0x45,0x35,0x3B,0x44,0xFF,0x1A,0x7A,0xB1,0x46,0x93,0xF5,0x87,0xF7,0xAE,0x82,0x52,0xD0,0x22,0xBE,0x2E,0x7D,0xF2,0xCE,0xAA,0xC0,0xA2,0x50,0x27,0x92,0x83,0x0E,0x67,0x50,0xDF,0x02,0x03,0x01,0x00,0x01,0x02,0x81,0x80,0x06,0x23,0x87,0xE0,0xF7,0x06,0xF8,0xAE,0x9C,0x39,0x0F,0xE2,0x9D,0xF1,0xF4,0x2D,0xB5,0x09,0x59,0x82,0x68,0xE4,0xEB,0x58,0x4B,0xF3,0x30,0x17,0x69,0x74,0xA2,0xEA,0xAF,0xB0,0xD5,0xF6,0x4A,0x4A,0xFA,0x8C,0x39,0x2C,0xE6,0xF9,0x58,0x03,0xD7,0x0E,0x31,0x7F,0x0E,0x25,0xF0,0xBD,0x2C,0x9C,0x4A,0xE0,0x11,0x2F,0x33,0x15,0x44,0x75,0xE5,0x8B,0x2C,0xC4,0x9F,0x56,0x8E,0x9E,0x26,0xA9,0x1C,0x40,0xAB,0xDA,0xB9,0xF4,0xC8,0x39,0xBD,0xFF,0x82,0xC8,0xB7,0xB9,0x67,0xFE,0x7B,0x53,0xE8,0xB9,0x19,0x22,0xF6,0x41,0xD6,0xD5,0x65,0xBC,0xE5,0x07,0xF2,0x73,0x3B,0x5B,0x28,0xBA,0xBF,0x48,0x9F,0x1E,0xAA,0x45,0x95,0x08,0x62,0xBC,0x72,0xA3,0x06,0xC3,0x9D,0x23,0xD8,0xE1,0x02,0x41,0x00,0xE5,0x22,0xE6,0x8A,0xAE,0xD8,0x94,0xE9,0x83,0xE0,0x91,0x14,0x2E,0xAB,0x43,0x46,0xA5,0x7A,0xD3,0xF9,0x04,0x3D,0x35,0x18,0x31,0x38,0x82,0xA2,0xD3,0x0A,0xD7,0xE2,0x37,0xF8,0x17,0x22,0x08,0xD3,0xBF,0xBC,0xBD,0xFD,0x89,0x8C,0x21,0xCF,0x32,0xED,0x25,0x46,0xD0,0xC2,0x4E,0x50,0x58,0xDD,0x92,0xF5,0xDE,0x64,0x0B,0x3D,0x0A,0x0D,0x02,0x41,0x00,0xCE,0x2F,0x98,0x54,0x2B,0x59,0xC7,0x9D,0xA8,0x9E,0xA1,0x44,0xD7,0xBA,0x47,0x6B,0x23,0xE5,0xB1,0x89,0x8C,0xB4,0xAF,0xD3,0x19,0x0E,0x5A,0x8D,0x07,0xE4,0xF8,0x5B,0x11,0xC4,0x8E,0xCF,0xFB,0x39,0xBC,0xC2,0x9C,0x28,0x83,0xEE,0x3A,0x3E,0x17,0xE1,0xB4,0x3B,0x98,0x05,0xD6,0x8D,0x29,0xAA,0xBE,0x32,0x02,0x41,0x50,0x43,0x67,0x9B,0x02,0x40,0x13,0xD5,0x9E,0x91,0x38,0xAB,0x64,0xD0,0x85,0xEA,0xE5,0x84,0x12,0xBA,0x1E,0x7B,0xBA,0x0D,0x54,0xD6,0x04,0x68,0xEB,0xF4,0xA9,0x26,0x14,0x20,0xD6,0x15,0xE5,0x34,0x1E,0xD6,0x29,0xE2,0x77,0x53,0x25,0x10,0xC8,0x7D,0x6E,0xEF,0xA3,0x69,0x95,0x25,0xF4,0x09,0x1A,0x3F,0x07,0x9A,0x6A,0xE6,0xDB,0x36,0xCF,0x46,0x67,0xB6,0xA3,0xED,0x02,0x40,0x01,0xFF,0x6E,0x0F,0x6A,0xB8,0x1C,0xFA,0x07,0x17,0x3A,0x62,0xCB,0x60,0x4F,0xAE,0xD7,0x13,0x33,0xAC,0x2C,0x83,0xD7,0xAC,0x48,0xF2,0xDD,0xA7,0xBE,0x2A,0xD6,0xC9,0x33,0x1B,0xDF,0x72,0x5E,0x71,0xC9,0xC5,0x6C,0xF3,0xEB,0x8B,0x54,0x5F,0x23,0xA6,0x19,0x33,0xF6,0x9E,0x1F,0xDD,0x10,0x49,0x4A,0x3C,0x7B,0xCF,0x1C,0x32,0xFA,0xFF,0x02,0x40,0x4E,0xBB,0x7C,0xE3,0xA3,0xC2,0xA7,0x8B,0x60,0x08,0xE6,0xC6,0x13,0xF8,0x57,0x44,0xD4,0x69,0xE5,0x67,0xEF,0x22,0x11,0xE3,0x75,0xBE,0x7D,0x1D,0x6E,0x33,0x0D,0x57,0x72,0xC0,0xD6,0x79,0xCD,0xE3,0x9F,0xA7,0xD7,0x99,0x75,0xDA,0x39,0xB7,0xD9,0x29,0x6D,0x28,0x88,0x30,0x37,0x71,0x78,0x99,0x3A,0x73,0xBC,0x60,0x11,0x1B,0x50,0xE0 };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    SecKeyRef importKeyRef = [QredoCrypto importPkcs1KeyData:keyData
                                               keyLengthBits:keySizeBits
                                               keyIdentifier:keyIdentifier
                                                   isPrivate:isPrivate];
    
    XCTAssertTrue((__bridge id)importKeyRef,@"Key import failed.");
}


-(void)testGetPrivateKeyRefFromIdentityRef {
    //Test client 2048 certificate + priv key from Java-SDK, with intermediate cert
    
    NSError *error = nil;
    
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:@"clientCert2.2048.IntCA1" error:&error];
    
    NSString *pkcs12Password = @"password";
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    
    //Setup
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data
                                                                                             password:pkcs12Password
                                                                                  rootCertificateRefs:rootCertificates];
    XCTAssertNotNil(identityDictionary,@"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,
                                                                      kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef,@"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");
    
    //Test
    SecKeyRef privateKeyRef = [QredoCrypto getPrivateKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)privateKeyRef,@"Should not have got a nil private key ref");
}


-(void)testGetPublicKeyRefFromIdentityRef {
    //Test client 2048 certificate + priv key from Java-SDK, with intermediate cert
    
    NSError *error = nil;
    
    NSData *pkcs12Data = [TestCertificates fetchPfxForResource:@"clientCert2.2048.IntCA1" error:&error];
    
    NSString *pkcs12Password = @"password";
    
    //Java-SDK root cert
    NSString *rootCertificatesPemString = [TestCertificates fetchPemForResource:@"rootCAcert" error:&error];
    
    //Setup
    NSArray *rootCertificates = [QredoCertificateUtils getCertificateRefsFromPemCertificates:rootCertificatesPemString];
    
    XCTAssertNotNil(rootCertificates,@"Root certificates should not be nil.");
    
    NSDictionary *identityDictionary = [QredoCertificateUtils createAndValidateIdentityFromPkcs12Data:pkcs12Data password:pkcs12Password rootCertificateRefs:rootCertificates];
    XCTAssertNotNil(identityDictionary,@"Incorrect identity validation result. Should have returned valid NSDictionary.");
    
    SecIdentityRef identityRef = (SecIdentityRef)CFDictionaryGetValue((__bridge CFDictionaryRef)identityDictionary,kSecImportItemIdentity);
    XCTAssertNotNil((__bridge id)identityRef,@"Incorrect identity validation result dictionary contents. Should contain valid identity ref.");
    
    //Test
    SecKeyRef publicKeyRef = [QredoCrypto getPublicKeyRefFromIdentityRef:identityRef];
    XCTAssertNotNil((__bridge id)publicKeyRef,@"Should not have got a nil public key ref");
}


@end
