/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "rsapss.h"
#import "QredoCrypto.h"
#import "NSData+QredoRandomData.h"
#import "NSData+Conversion.h"
#import "QredoLoggerPrivate.h"
#import "QredoRsaPrivateKey.h"

@interface QredoPSSTests :XCTestCase
{
    NSString *privateKeyName;
    NSString *publicKeyName;
    int failed;
}

@end

@implementation QredoPSSTests

-(void)setUp {
    [super setUp];
    
    NSString *keyName = [[NSData dataWithRandomBytesOfLength:16] hexadecimalString];
    privateKeyName = [keyName stringByAppendingString:@".private"];
    publicKeyName = [keyName stringByAppendingString:@".public"];
    
    [self generateRandomKeys];
    //[self importKnownKeys];
    
    NSData *privateKeyData = [QredoCrypto getKeyDataForIdentifier:privateKeyName];
    [QredoCrypto getKeyDataForIdentifier:publicKeyName];
    
    QredoRsaPrivateKey *qredoPrivateKey = [[QredoRsaPrivateKey alloc] initWithPkcs1KeyData:privateKeyData];
    XCTAssertNotNil(qredoPrivateKey);
}

-(void)tearDown {
    if (privateKeyName)[QredoCrypto deleteKeyInAppleKeychainWithIdentifier:privateKeyName];
    
    if (publicKeyName)[QredoCrypto deleteKeyInAppleKeychainWithIdentifier:publicKeyName];
    
    [super tearDown];
}

-(void)generateRandomKeys {
    QredoSecKeyRefPair *keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:2048
                                                         publicKeyIdentifier:publicKeyName
                                                        privateKeyIdentifier:privateKeyName
                                                      persistInAppleKeychain:YES];
    
    XCTAssertNotNil(keyPairRef,"RSA key generation failed (nil object returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil public key ref returned).");
    XCTAssertNotNil((__bridge id)keyPairRef.publicKeyRef,"RSA key generation failed (nil private key ref returned).");
}

-(void)importKnownKeys {
    [super setUp];
    
    //Configure specific keys for this test, helped to investigate and recreate specific problem
    
    NSInteger keySizeBits = 2048;
    
    uint8_t publicKeyDataArray[] = { 0x30,0x82,0x01,0x0A,0x02,0x82,0x01,0x01,0x00,0xF7,0xB7,0x9F,0xBF,0x70,0x00,0x06,0xF1,0x50,0x77,0x11,0x7E,0x40,0x6B,0x02,0x2B,0xD5,0xC1,0xCE,0x23,0xE1,0xE3,0x6A,0x1E,0xF0,0x1E,0xD9,0x0C,0x9B,0x44,0xF1,0x5A,0x8A,0x0D,0xE1,0x77,0x3B,0xDA,0x77,0xE1,0x04,0x45,0x08,0xC1,0x0D,0xE7,0x86,0xB0,0x5D,0x32,0x2E,0x5D,0xDB,0xD5,0x53,0x19,0xC2,0x20,0x88,0x71,0x92,0x0D,0xCF,0x7F,0x49,0x9D,0xF4,0x8B,0x21,0x3A,0x7B,0xC6,0xC2,0xC6,0x69,0xCD,0x7D,0xC9,0x13,0xA2,0x6A,0x9D,0x44,0x6F,0x23,0x34,0xA0,0xAA,0xE4,0x8C,0x5A,0xED,0xF3,0xC9,0xEF,0x8D,0x18,0x65,0x71,0xE0,0x9D,0x5B,0x01,0xB6,0x45,0x1F,0xF5,0x99,0x98,0xF0,0xA6,0xA5,0x67,0xA7,0xDF,0x23,0x52,0x73,0x8E,0x03,0x6E,0xA7,0x40,0xB2,0x09,0xBD,0xD3,0xC2,0xD5,0x81,0x6B,0xC1,0x1C,0x8B,0xAF,0xB5,0x7A,0x8B,0x46,0x94,0xE3,0xB1,0x30,0x20,0x56,0x8C,0x02,0x3F,0x5E,0xA3,0xEE,0x61,0x5F,0x7A,0x34,0x65,0xE4,0x77,0x70,0xF1,0xE7,0xFB,0xBE,0x6B,0x1F,0x89,0x94,0x2A,0x1A,0x36,0xD3,0x4F,0x61,0xB3,0x68,0x6A,0x17,0x20,0x07,0x32,0xBD,0xEE,0x9B,0xE1,0x9F,0x08,0x4B,0x5B,0x2B,0x02,0x36,0x9B,0x9B,0x53,0x90,0x7C,0xB2,0x39,0x9B,0x4E,0x3C,0x50,0x71,0x41,0x57,0x00,0xC0,0x76,0x68,0x57,0xEE,0x8D,0x53,0xBA,0xC8,0x3C,0xD1,0x09,0x69,0x58,0xFC,0x1E,0x90,0xE2,0x89,0x48,0x3D,0xE3,0xB8,0x6C,0xFA,0x53,0x99,0xDC,0xCF,0xAA,0x0A,0x52,0xD9,0x3A,0x2C,0x3A,0x4D,0xB7,0x27,0x97,0x02,0x99,0x68,0x6E,0x54,0x17,0x1A,0x06,0xEC,0xB3,0x02,0x03,0x01,0x00,0x01 };
    NSData *publicKeyData = [NSData dataWithBytes:publicKeyDataArray
                                           length:sizeof(publicKeyDataArray) / sizeof(uint8_t)];
    
    uint8_t privateKeyDataArray[] = { 0x30,0x82,0x04,0xA3,0x02,0x01,0x00,0x02,0x82,0x01,0x01,0x00,0xF7,0xB7,0x9F,0xBF,0x70,0x00,0x06,0xF1,0x50,0x77,0x11,0x7E,0x40,0x6B,0x02,0x2B,0xD5,0xC1,0xCE,0x23,0xE1,0xE3,0x6A,0x1E,0xF0,0x1E,0xD9,0x0C,0x9B,0x44,0xF1,0x5A,0x8A,0x0D,0xE1,0x77,0x3B,0xDA,0x77,0xE1,0x04,0x45,0x08,0xC1,0x0D,0xE7,0x86,0xB0,0x5D,0x32,0x2E,0x5D,0xDB,0xD5,0x53,0x19,0xC2,0x20,0x88,0x71,0x92,0x0D,0xCF,0x7F,0x49,0x9D,0xF4,0x8B,0x21,0x3A,0x7B,0xC6,0xC2,0xC6,0x69,0xCD,0x7D,0xC9,0x13,0xA2,0x6A,0x9D,0x44,0x6F,0x23,0x34,0xA0,0xAA,0xE4,0x8C,0x5A,0xED,0xF3,0xC9,0xEF,0x8D,0x18,0x65,0x71,0xE0,0x9D,0x5B,0x01,0xB6,0x45,0x1F,0xF5,0x99,0x98,0xF0,0xA6,0xA5,0x67,0xA7,0xDF,0x23,0x52,0x73,0x8E,0x03,0x6E,0xA7,0x40,0xB2,0x09,0xBD,0xD3,0xC2,0xD5,0x81,0x6B,0xC1,0x1C,0x8B,0xAF,0xB5,0x7A,0x8B,0x46,0x94,0xE3,0xB1,0x30,0x20,0x56,0x8C,0x02,0x3F,0x5E,0xA3,0xEE,0x61,0x5F,0x7A,0x34,0x65,0xE4,0x77,0x70,0xF1,0xE7,0xFB,0xBE,0x6B,0x1F,0x89,0x94,0x2A,0x1A,0x36,0xD3,0x4F,0x61,0xB3,0x68,0x6A,0x17,0x20,0x07,0x32,0xBD,0xEE,0x9B,0xE1,0x9F,0x08,0x4B,0x5B,0x2B,0x02,0x36,0x9B,0x9B,0x53,0x90,0x7C,0xB2,0x39,0x9B,0x4E,0x3C,0x50,0x71,0x41,0x57,0x00,0xC0,0x76,0x68,0x57,0xEE,0x8D,0x53,0xBA,0xC8,0x3C,0xD1,0x09,0x69,0x58,0xFC,0x1E,0x90,0xE2,0x89,0x48,0x3D,0xE3,0xB8,0x6C,0xFA,0x53,0x99,0xDC,0xCF,0xAA,0x0A,0x52,0xD9,0x3A,0x2C,0x3A,0x4D,0xB7,0x27,0x97,0x02,0x99,0x68,0x6E,0x54,0x17,0x1A,0x06,0xEC,0xB3,0x02,0x03,0x01,0x00,0x01,0x02,0x82,0x01,0x01,0x00,0xA9,0xF5,0x85,0x98,0x4E,0x5A,0xE6,0x68,0x89,0x21,0xB8,0x91,0xDB,0xD6,0xCF,0x9D,0x8D,0xC2,0xB4,0x11,0xB0,0x79,0x5C,0xA5,0x2F,0x70,0xAA,0xD0,0xD8,0x73,0x5B,0xF9,0x17,0xC1,0x60,0x51,0x73,0x72,0x78,0x4F,0x9D,0xA3,0x53,0xD7,0x49,0x17,0xF2,0x34,0x6D,0x2C,0xF1,0xDD,0x19,0xE8,0x6A,0x64,0xC0,0xE9,0x9B,0x53,0xF8,0xB6,0x9B,0x08,0x25,0x55,0x47,0xA4,0x71,0xBE,0xF3,0x8F,0xB2,0xB1,0x79,0x84,0x30,0xEA,0x56,0x1B,0x58,0x74,0xE0,0xB0,0x34,0x02,0x76,0xBD,0xE9,0xA3,0x56,0xFB,0xEE,0x09,0x3D,0xDF,0x9B,0xBE,0x76,0x7C,0x7A,0xDA,0x26,0xF9,0x8C,0xC1,0xD9,0xBB,0x71,0xD0,0xA3,0x35,0xD7,0x41,0xB9,0x7A,0x3D,0xA6,0xE4,0xE7,0xFB,0xF2,0xAB,0x13,0xBC,0x55,0x4E,0xC4,0xAE,0xA1,0x3B,0xFD,0xC2,0x3A,0x78,0xC5,0xC0,0xDB,0xC6,0x18,0x21,0x40,0xB3,0x14,0x66,0x59,0x11,0x8B,0x01,0xD1,0x86,0x65,0x69,0xBD,0x3D,0xE9,0x33,0x9D,0x7F,0xD7,0x3C,0x31,0x84,0xB1,0xCF,0x8E,0x9C,0x70,0x56,0x9D,0x4E,0x84,0x33,0x49,0xA4,0xB2,0x9C,0xA0,0x9C,0x11,0x8B,0xCD,0xF0,0x94,0xF1,0x9C,0x45,0xAA,0xD9,0x3E,0x7E,0x1F,0xC7,0xF8,0x17,0x6B,0xDA,0xEF,0x9F,0xB3,0xCD,0x4F,0x29,0x8B,0xD4,0x55,0xE6,0x62,0xCF,0x2A,0xBF,0x7D,0x67,0x0E,0x2F,0x10,0xCC,0x3B,0xFE,0x1E,0xE7,0x62,0xD1,0x13,0xD0,0x2F,0x5F,0x86,0x22,0x0F,0x03,0xEC,0xBD,0xA3,0x06,0xDE,0x48,0x0E,0x9B,0xC4,0x07,0x74,0x1E,0x9B,0x2B,0x65,0x3F,0xA3,0x77,0xD4,0x75,0x14,0x8E,0x68,0xA5,0x61,0x02,0x81,0x81,0x01,0xF6,0x0D,0xEC,0xAF,0xA8,0x99,0x2E,0x16,0x34,0xEA,0xFA,0x1B,0xE8,0xFD,0x82,0xB6,0x16,0xD5,0xA8,0x28,0x61,0xBA,0x4E,0x5B,0xFC,0xB3,0xBD,0x5F,0x46,0x53,0x29,0x6A,0xB3,0xD2,0xED,0xD3,0x4E,0x25,0xED,0x47,0x02,0x06,0xD6,0x6C,0x2C,0x02,0x49,0xD3,0x83,0x50,0xE4,0x2A,0x04,0x42,0x6D,0xAF,0x62,0xE3,0x47,0x33,0x57,0x95,0x17,0x99,0x8E,0xA0,0x93,0x2B,0xC2,0x5C,0x49,0x61,0x35,0xE2,0x86,0xE9,0xFF,0x0F,0x0D,0xBA,0x24,0x3A,0x3E,0xAA,0x2B,0x4E,0x4D,0xAB,0x46,0x9F,0x01,0xAA,0xB2,0x8E,0xE4,0x0A,0x17,0x2B,0x66,0x58,0x13,0x28,0x44,0x1C,0x8D,0xC0,0x8E,0x90,0xC9,0xD2,0xD4,0x6F,0x7E,0x73,0xFA,0xF7,0x36,0xB2,0x05,0x82,0x38,0xDD,0x11,0x62,0x73,0x13,0xFA,0xE3,0x02,0x81,0x80,0x7E,0x4F,0xF0,0x24,0xA7,0xBC,0xF3,0x05,0x36,0x81,0xE5,0x8C,0xA1,0x72,0xDE,0x54,0xD9,0xD8,0x45,0xF8,0x1C,0x6C,0x0D,0x53,0xCF,0x7D,0xB9,0x32,0x5E,0x2D,0xD3,0x12,0xA6,0x64,0x3C,0x92,0x13,0xDF,0x98,0x6E,0x9A,0x6C,0x91,0xD6,0xC2,0x72,0xDA,0x0C,0xF3,0x73,0x2C,0xA7,0xA7,0xAA,0xE4,0x3D,0x9E,0xD7,0xBB,0xCA,0xF6,0x73,0x18,0xD5,0xBB,0x77,0xB8,0x48,0xF5,0x66,0xC2,0x3D,0xC0,0x26,0xB8,0xA6,0x63,0xE5,0x5C,0xC3,0x25,0x6A,0x17,0xE4,0x59,0xB3,0xA6,0x76,0xCF,0x11,0x1D,0x5C,0x5F,0xED,0x19,0x91,0x32,0xB5,0xF8,0x99,0x17,0x02,0x36,0xC4,0x0C,0xED,0x03,0x93,0x2C,0xBD,0x3B,0xF9,0x31,0x24,0x36,0x1D,0xCE,0x84,0x0F,0x49,0xBB,0xEE,0x4E,0x94,0xF4,0x64,0xDF,0xF1,0x02,0x81,0x81,0x01,0x35,0xB6,0x1F,0x55,0xB9,0xAF,0x4D,0x63,0xFB,0x9F,0x1D,0x4D,0x8C,0x6C,0x9F,0x6F,0x0F,0x25,0x1C,0xC8,0x54,0x89,0x66,0xFF,0x8E,0x23,0x9F,0x66,0x1F,0xEE,0xFB,0x74,0xCC,0x9C,0x09,0x84,0xBA,0x07,0xE1,0x99,0x55,0x61,0xBC,0x73,0x1C,0xAF,0x08,0xB6,0x07,0xA3,0x26,0x2D,0xD9,0x54,0xD5,0x6F,0x45,0x94,0xA9,0x7E,0xBD,0xBF,0xC6,0xC0,0x3E,0xE1,0x46,0x08,0xCF,0xAC,0xB8,0xC3,0xD4,0x46,0xFB,0x2D,0x6C,0xDF,0xEF,0x7A,0xEE,0x10,0x54,0x4A,0x0B,0xCF,0x11,0x50,0xE0,0x8F,0x04,0xAB,0x35,0xDD,0xBA,0x45,0x93,0x47,0x7D,0xAA,0x45,0x9F,0x28,0x6D,0x68,0xF0,0xE9,0xC1,0xDE,0x0F,0x46,0x67,0xC5,0x5D,0x6C,0xEB,0x86,0x7D,0x49,0xB2,0xAC,0xBB,0x8B,0x96,0xED,0x20,0xDD,0x3B,0x02,0x81,0x80,0x21,0x0A,0x59,0xFF,0xCC,0x9C,0xC1,0x59,0x10,0xBC,0x03,0xC6,0xB8,0x88,0xAA,0x9D,0xB9,0x6A,0x38,0x4B,0x41,0x6C,0x06,0x44,0x71,0x17,0x2A,0xF5,0x80,0xEB,0x2D,0xB6,0x48,0x2E,0x1A,0x25,0xFF,0xEA,0xD2,0x1D,0xC4,0x69,0x37,0xF0,0xDC,0x66,0x5C,0xA1,0x5C,0xA1,0x39,0x02,0x15,0xFA,0xBE,0xBF,0x5B,0xA8,0x84,0xE7,0xFF,0x75,0x75,0xFE,0x9A,0x8E,0x23,0x77,0x7A,0x31,0xCA,0x07,0x8B,0x16,0xD5,0xE0,0x38,0x6B,0x4B,0xCB,0x84,0x22,0xEF,0x62,0xFD,0x0F,0xE0,0x30,0x5D,0xD3,0xD5,0x41,0x4F,0x9A,0x5E,0xC0,0xBB,0x6A,0x1C,0x40,0x37,0x63,0x8D,0xDD,0xD4,0x9F,0xBE,0xFA,0xA5,0x8E,0x4E,0x7C,0xCD,0x9C,0xF2,0x46,0xF3,0xB9,0x59,0xA2,0x68,0xF5,0x5A,0x3A,0xDE,0x7E,0xF0,0x91,0x02,0x81,0x80,0x69,0x7C,0xF6,0xD2,0x9B,0xC2,0xC6,0x03,0x3F,0x7D,0x1F,0x98,0x31,0x47,0x77,0xA3,0x0C,0xCC,0xFC,0xC4,0x61,0x7A,0xD7,0xAC,0xA7,0x6C,0xC4,0x16,0xD6,0xA9,0xBC,0xAC,0x72,0x05,0x95,0xBB,0x52,0x14,0xFF,0xD3,0x01,0xA7,0xEA,0x90,0xA5,0x62,0x33,0x2D,0x68,0x3C,0xE9,0x62,0x05,0x0E,0x54,0xB4,0x4B,0x1E,0xEE,0x94,0x2D,0x42,0xCD,0x3D,0x17,0xA3,0xA4,0x75,0xBA,0x5A,0x2E,0xEF,0x41,0x4E,0x0B,0x35,0x87,0x26,0x5A,0x91,0x3B,0x19,0x6B,0x22,0xEC,0xF3,0x64,0x73,0x03,0x5B,0x6A,0x3A,0x0F,0x91,0x77,0x91,0xAD,0xA7,0xEF,0x94,0xD8,0x65,0x88,0x1A,0x7A,0x69,0xAD,0x8D,0x34,0x77,0xA0,0x5A,0x9B,0x86,0x16,0xEF,0xC7,0xB3,0xDA,0x2D,0x05,0x42,0x51,0xD0,0x11,0x00,0x7D,0xFB };
    NSData *privateKeyData = [NSData dataWithBytes:privateKeyDataArray
                                            length:sizeof(privateKeyDataArray) / sizeof(uint8_t)];
    
    //Import the public key
    SecKeyRef importPubKeyRef = [QredoCrypto importPkcs1KeyData:publicKeyData
                                                  keyLengthBits:keySizeBits
                                                  keyIdentifier:publicKeyName
                                                      isPrivate:NO];
    XCTAssertTrue((__bridge id)importPubKeyRef,@"Publuc key import failed.");
    
    
    //Import the private key
    SecKeyRef importPrivKeyRef = [QredoCrypto importPkcs1KeyData:privateKeyData
                                                   keyLengthBits:keySizeBits
                                                   keyIdentifier:privateKeyName
                                                       isPrivate:YES];
    XCTAssertTrue((__bridge id)importPrivKeyRef,@"Private key import failed.");
}

-(void)testPSSCImplementation {
    NSString *inputData = @"Hello, world";
    NSData *hash = [QredoCrypto sha256:[inputData dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *wrongInputData = @"Hello, world 2";
    NSData *wrongHash = [QredoCrypto sha256:[wrongInputData dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    int saltLength = 11;
    int keyBits = 2048;
    
    NSMutableData *encodedData = [NSMutableData dataWithLength:256];
    
    int result = rsa_pss_sha256_encode(hash.bytes,hash.length,saltLength,keyBits,encodedData.mutableBytes,encodedData.length);
    
    XCTAssert(result > 0,@"Failed to encode with PSS. Result %d",result);
    XCTAssert(result == (keyBits / 8),@"Encoded message size should be the 256 bytes, but it is %d",result);
    
    result = rsa_pss_sha256_verify(hash.bytes,hash.length,encodedData.bytes,encodedData.length,saltLength,keyBits);
    XCTAssert(result == QREDO_RSA_PSS_VERIFIED,@"Failed to verify PSS encoded signature. Result %d",result);
    
    result = rsa_pss_sha256_verify(wrongHash.bytes,wrongHash.length,encodedData.bytes,encodedData.length,saltLength,keyBits);
    XCTAssert(result == QREDO_RSA_PSS_NOT_VERIFIED,@"Failed to verify PSS encoded signature. Result %d",result);
    
    //messing up the data a bit
    ((uint8_t *)encodedData.mutableBytes)[0] = 0x11;
    result = rsa_pss_sha256_verify(hash.bytes,hash.length,encodedData.bytes,result,saltLength,keyBits);
    XCTAssert(result != QREDO_RSA_PSS_VERIFIED,@"Failed to verify PSS encoded signature. Result %d",result);
}

-(void)testPSSSignAndVerifyMessage {
    const int messageLength = 64;
    const int saltLen = 32;
    NSData *message = [NSData dataWithRandomBytesOfLength:messageLength];
    
    SecKeyRef privateKey = [QredoCrypto getRsaSecKeyReferenceForIdentifier:privateKeyName];
    SecKeyRef publicKey = [QredoCrypto getRsaSecKeyReferenceForIdentifier:publicKeyName];
    
    NSData *signature = [QredoCrypto rsaPssSignMessage:message saltLength:saltLen keyRef:privateKey];
    
    XCTAssertNotNil(signature);
    
    BOOL verified = [QredoCrypto rsaPssVerifySignature:signature forMessage:message saltLength:saltLen keyRef:publicKey];
    XCTAssertTrue(verified);
    
    if (!verified)failed++;
}

-(void)testPSSSignAndVerifyMessageMultiple {
    int iterations = 300; //1000 iterations takes about 14 seconds to run
    
    for (int i = 0; i < iterations; i++){
        @try {
            [self testPSSSignAndVerifyMessage];
        } @catch (NSException *exception){
            @throw exception;
        }
    }
    
    XCTAssertEqual(failed,0);
}

@end
