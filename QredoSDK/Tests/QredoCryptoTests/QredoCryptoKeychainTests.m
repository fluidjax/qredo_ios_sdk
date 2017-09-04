//
//  QredoCryptoKeychainTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import <XCTest/XCTest.h>
#import "QredoCryptoKeychain.h"
#import "QredoKey.h"
#import "QredoKeyRef.h"
#import "QredoKeyRefPair.h"
#import "UICKeyChainStore.h"
#import "QredoBulkEncKey.h"
#import "QredoXCTestCase.h"

@interface QredoCryptoKeychainTests : XCTestCase

@end

@implementation QredoCryptoKeychainTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



#pragma Keychain Store

-(void)testKeychainStoreRetrieve{
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    QredoKey *testKey = [QredoKey keyWithHexString:@"1c68b754 1878ffff d8a7d9f2 94d90ff6 bf28b9d0 e0a72ef3 7d37d645 4d578d2a"];
    
    QredoKeyRef *ref = [keychain createKeyRef:testKey];

    XCTAssertNotNil(keychain);
    XCTAssertNotNil(ref);
    XCTAssertNotNil(testKey);

    NSData *rawKey = [keychain retrieveWithRef:ref];
    XCTAssertNotNil(rawKey);
    QredoKey *outKey = [QredoKey keyWithData:rawKey];
    XCTAssertTrue([testKey isEqual:outKey],@"Key saved in keychain arent the same");
}


#pragma Bulk encrypt/Decrypt


-(void)testKeyRefPair{
    QredoKey *pubKey  = [QredoKey keyWithHexString:@"1c68b754 1878ffff d8a7d9f2 94d90ff6 bf28b9d0 e0a72ef3 7d37d645 4d578d2a"];
    QredoKey *privKey = [QredoKey keyWithHexString:@"2368b754 1878ffff d8a7d9f2 94d90ff6 bf28b9d0 e0a72ef3 7d37d645 4d578d2a"];
    
    QredoKeyRefPair *refpair =  [QredoKeyRefPair keyPairWithPublic:pubKey private:privKey];
    
    QredoKeyRef *privRef = refpair.privateKeyRef;
    
    XCTAssertTrue([[privRef debugValue] isEqualToData:privKey.data]);
    
    
    QredoKeyRef *pubRef = refpair.publicKeyRef;
    XCTAssertTrue([[pubRef debugValue] isEqualToData:pubKey.data]);
}


-(void)testEncryptDecryptRoundTripOf1600Bytes {
    uint8_t keyDataArray[] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f
    };
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    
    //1600 bytes of random data
    uint8_t plaintextDataArray[] = {
        0x55,0x28,0xd9,0xc2,0x6e,0x2e,0x5c,0xef,0xd6,0x38,0x75,0x64,0x79,0x74,0xbb,0xb0,
        0x67,0x6f,0xb4,0xa2,0xb9,0xd7,0x08,0x27,0x5f,0xaa,0xf3,0x6e,0xf2,0x8d,0xcf,0x44,
        0x42,0x30,0x05,0xb4,0x00,0xd7,0xa8,0x84,0x73,0x05,0xb6,0x4c,0xa4,0x1e,0x44,0x6e,
        0x4b,0x8d,0xe7,0xe2,0x8f,0xa9,0xd9,0xed,0xe0,0x37,0x14,0x93,0x8b,0x6b,0x4e,0x58,
        0x67,0x8e,0x2c,0x27,0x44,0xb5,0xb4,0x0d,0x26,0x39,0x5e,0x3a,0x05,0xb3,0xe6,0x96,
        0x92,0x82,0xf8,0x6a,0x0f,0x25,0x8c,0x98,0xc0,0x44,0x69,0x5e,0x29,0xf7,0xb2,0xfc,
        0x31,0x31,0x5d,0x7c,0x97,0x1a,0x98,0xc8,0xf5,0xea,0x42,0x77,0x96,0x93,0xb4,0xe2,
        0xe5,0x37,0xa9,0x2f,0xab,0xd3,0xd2,0xbc,0x9e,0x7d,0x21,0xf7,0x89,0xdb,0xe0,0x1b,
        0xac,0x01,0x99,0x0e,0x6c,0x4f,0x23,0x44,0x66,0x39,0xc7,0xe1,0xc0,0xbf,0xf4,0x0b,
        0x62,0x2c,0x80,0x37,0xdd,0x22,0x84,0x83,0x90,0xd1,0x20,0xb9,0xb4,0x6f,0xee,0xdf,
        0x00,0x0f,0x34,0x7b,0x76,0x84,0x7f,0xf6,0x82,0xd4,0xc3,0xc0,0xcc,0x49,0xe9,0x8a,
        0xf2,0xb5,0x1d,0x49,0x77,0x2a,0x85,0x4a,0x75,0x43,0x8c,0xab,0x75,0x17,0x57,0xfd,
        0xe4,0x5e,0xb9,0x6b,0x0e,0x65,0xa6,0x99,0xc3,0x56,0x13,0xb5,0x22,0x55,0x18,0x5d,
        0x40,0xe4,0xc1,0x1e,0x47,0x95,0x89,0x7a,0x6a,0xc1,0xbb,0x07,0x93,0x4c,0x64,0x34,
        0x32,0x8d,0x49,0x9f,0x87,0xf6,0x6a,0xfc,0x81,0xb7,0xef,0x13,0x4a,0x66,0xac,0x3a,
        0xf2,0x94,0xa0,0x51,0xef,0x3a,0x1c,0x54,0xac,0x5a,0x3d,0x9b,0xd1,0xf2,0x2e,0xf7,
        0x8e,0x6b,0xe5,0x66,0x91,0xf2,0x84,0xed,0x21,0x6d,0xcb,0x68,0x3a,0x28,0x5f,0x2a,
        0x81,0xaa,0xbe,0xe5,0x18,0x6a,0x89,0x4b,0x2f,0xe8,0xe7,0xd2,0x53,0xa0,0x20,0x13,
        0x97,0xc7,0x0c,0xfc,0xf8,0xdd,0xec,0x59,0x0c,0xd9,0x06,0x92,0xff,0x6b,0x41,0x72,
        0xe0,0x30,0x92,0xe8,0x40,0xdd,0x4d,0x6a,0xff,0x2e,0x89,0x5a,0x3d,0xff,0xcb,0x5d,
        0xd1,0xc5,0x92,0xf7,0x4a,0x4d,0xcd,0x8c,0x65,0x25,0x34,0x6b,0x5c,0x53,0x27,0xc9,
        0x6c,0x47,0xe7,0x98,0xed,0x6a,0x7b,0x3e,0x63,0xc0,0x28,0x66,0xe2,0xbe,0xaa,0x6f,
        0xf1,0xd3,0xb9,0xb0,0x18,0x33,0x07,0x59,0xf3,0x64,0x6a,0xed,0x06,0xa7,0x33,0x43,
        0xcc,0x36,0x55,0x4b,0x6a,0x26,0xe2,0x98,0xd1,0x26,0x2c,0x9b,0x32,0x2a,0x28,0x6a,
        0x1a,0x9d,0x58,0x52,0x50,0x91,0x94,0x0d,0x46,0x63,0x57,0xe1,0xdc,0xcf,0x00,0xa1,
        0xa4,0xdb,0xa5,0x77,0x26,0xee,0xe2,0x65,0xfb,0x2f,0x5f,0x7f,0x49,0xe4,0xd7,0x73,
        0xa1,0xa2,0x18,0x9a,0x4a,0x3c,0x99,0x5d,0x39,0x3d,0x25,0x4e,0x2f,0xfa,0xbe,0x88,
        0x86,0x01,0xd1,0xfd,0x09,0x15,0x61,0x22,0x0c,0xbf,0x18,0x7a,0xb0,0xe2,0xa3,0xbe,
        0xed,0xd8,0x38,0x78,0x01,0xc5,0x56,0x6c,0xd9,0x06,0x91,0x21,0x2e,0xae,0x74,0x01,
        0xf3,0x50,0x76,0x36,0xc0,0x56,0xa2,0x55,0x9f,0x13,0x12,0x54,0x13,0x50,0x2d,0xb4,
        0x50,0x37,0xb4,0x98,0xe3,0xec,0x45,0xa5,0x73,0xbd,0x55,0x28,0x0e,0xe6,0xc8,0x65,
        0x1f,0x86,0x76,0x8c,0x29,0xd3,0x52,0xc9,0xbc,0xe7,0x81,0xb0,0x01,0x32,0x5c,0xe8,
        0x47,0xe7,0x16,0x59,0x79,0x35,0xdd,0xd1,0xd3,0xb4,0x8e,0xf9,0x93,0x3e,0x76,0x27,
        0xf2,0x25,0x4e,0xdb,0xb1,0x55,0x9b,0x7e,0x2e,0x45,0x74,0xe0,0x87,0xbd,0xcb,0xa8,
        0x91,0xac,0xee,0xdf,0x28,0xef,0x7e,0xb1,0xf5,0xef,0x88,0x17,0x5a,0x6e,0x8d,0x54,
        0x6c,0xaf,0xc4,0x82,0x08,0x27,0x2b,0x72,0xf1,0x68,0x3d,0x3c,0x2a,0x83,0x5b,0xa0,
        0xac,0x21,0xaa,0x6f,0xea,0xaf,0x6a,0x7c,0xb5,0x2d,0x65,0xc9,0xd3,0x08,0x3e,0xf2,
        0xda,0xdb,0x6f,0x99,0xe2,0x8e,0x19,0xbc,0x04,0x99,0x05,0x8b,0x6f,0x90,0x2a,0xeb,
        0x51,0x0e,0xd6,0xb2,0xa5,0x32,0x50,0xcf,0x6e,0xdc,0xfa,0x3a,0x0a,0x35,0x14,0x15,
        0x9d,0x1c,0xe6,0xeb,0x08,0xb1,0x21,0x6e,0x62,0x91,0xba,0xa0,0xb2,0xa3,0xa2,0x6c,
        0x3e,0xba,0x11,0x28,0x97,0x84,0x70,0x7c,0x8d,0x5a,0xb5,0x4d,0x46,0x9d,0xea,0xfb,
        0x8d,0x4f,0x21,0xc0,0xb1,0x99,0x4f,0x8b,0x40,0x6a,0x70,0x4c,0x30,0xc1,0x52,0x96,
        0x09,0xec,0x78,0x0b,0x0a,0x6d,0x1c,0xae,0x03,0x9d,0x83,0x8a,0xd1,0x5c,0xf3,0x2d,
        0x75,0xca,0xe0,0x71,0x12,0x57,0x47,0x85,0x03,0x81,0x39,0xf3,0x52,0x8c,0xfa,0xb4,
        0x48,0xf9,0x53,0xfe,0x4c,0x55,0xd3,0xdd,0xa5,0xa7,0x01,0x06,0x61,0x5f,0x1b,0xc2,
        0xf6,0x0c,0x1f,0x70,0xe8,0x27,0x17,0x79,0x7c,0x30,0x00,0x9a,0x1a,0x24,0xd0,0x84,
        0x55,0x97,0xba,0x3d,0x0d,0x65,0xcd,0xc5,0x26,0x82,0x17,0x34,0xe5,0x0a,0x7b,0xdb,
        0x5e,0x0a,0x30,0x62,0x2a,0x9e,0x89,0x4a,0xc6,0x8c,0x6a,0x19,0xf4,0x73,0x4f,0xf2,
        0x89,0x47,0xa2,0x36,0xa6,0x66,0x22,0xd7,0xa5,0x27,0x9b,0xae,0x4d,0x7d,0x47,0x6f,
        0x6a,0x40,0x87,0xda,0xd8,0x2b,0xb0,0x88,0x30,0xec,0x53,0x46,0xb1,0x8f,0x55,0x40,
        0xde,0x69,0x9e,0x06,0x8d,0x31,0xbd,0x3c,0x43,0x19,0x23,0xf3,0x01,0x0f,0x41,0x53,
        0xdc,0x69,0x65,0x2f,0xd7,0xa3,0xa9,0x33,0x1d,0x49,0x83,0xcc,0x68,0xf0,0x5a,0x10,
        0xca,0x42,0x6f,0xed,0x8b,0x1d,0xbb,0x13,0xd4,0xea,0x21,0x9e,0xff,0x96,0x6c,0x68,
        0x74,0xb4,0xdb,0xb4,0x3e,0x2a,0x20,0xba,0x24,0x69,0x92,0x04,0xaa,0x8e,0xa4,0xcd,
        0x90,0x5d,0x87,0xb3,0xfc,0x7b,0x99,0x4a,0x70,0xe4,0x0b,0x2f,0x59,0x02,0x79,0xc2,
        0xd8,0x02,0x94,0x34,0x22,0x96,0x0a,0x4c,0xbd,0x80,0x1b,0xb8,0xc7,0x5c,0xe5,0x85,
        0x5b,0x84,0x48,0xe8,0x2d,0x02,0x1d,0xb2,0xad,0x2e,0x1a,0x89,0xb6,0x8a,0x0b,0x4b,
        0xaf,0xef,0x96,0xbb,0xc7,0x5f,0xb6,0x52,0xc7,0xc2,0x81,0x5f,0x10,0xf6,0xaa,0x1d,
        0x2a,0x61,0xf9,0x35,0x3c,0x67,0x39,0x51,0xca,0xac,0x76,0x5c,0x94,0x6b,0x28,0x67,
        0xbb,0x6b,0x88,0x21,0x12,0x31,0x71,0x0d,0x07,0x4c,0x92,0x9b,0x73,0x8c,0x96,0x40,
        0xda,0x07,0xa8,0x89,0xb6,0x91,0x79,0xec,0xe5,0xff,0xe7,0xb7,0x8f,0x19,0x03,0x33,
        0x45,0xcb,0xaf,0xfe,0xed,0xfb,0x0a,0x91,0x89,0x5d,0x55,0x36,0x7a,0xe8,0xf0,0x45,
        0x3a,0x84,0xf1,0x57,0x41,0x7e,0x63,0xd9,0xf5,0x8e,0xc0,0x26,0x8b,0x69,0xf0,0x20,
        0x04,0x7a,0x39,0x9b,0x71,0x22,0x89,0x87,0x53,0x9c,0x20,0xd0,0x9e,0xd3,0x4e,0x5c,
        0x7a,0xb8,0x26,0xc7,0x2b,0xa9,0x2c,0xdf,0xb0,0x73,0x51,0xcd,0x8b,0xba,0x02,0x8a,
        0x0f,0x70,0x33,0x19,0x87,0x9e,0x5f,0xbc,0xf2,0x6c,0x0f,0xe9,0xf9,0x90,0xc0,0x43,
        0x35,0x6d,0xe6,0xe0,0x62,0x1c,0xf1,0x06,0x76,0x0b,0xc7,0xe5,0x78,0x0e,0xbd,0xbd,
        0xf7,0x9a,0x39,0xe6,0xc3,0x6a,0xae,0xf7,0x7a,0x4d,0x0c,0x60,0x50,0xf1,0xcc,0xc8,
        0xea,0xd6,0x31,0xe1,0x08,0x8d,0x38,0xba,0x7d,0x9f,0xbb,0x8f,0xb2,0x71,0xdc,0xd7,
        0x92,0xf3,0x9f,0xfe,0x3d,0xd8,0xce,0x43,0x81,0x33,0xa8,0x64,0x3b,0x6f,0x8a,0xa5,
        0xe2,0x65,0xa7,0xa4,0xad,0x2b,0x36,0xa9,0xc6,0x6c,0x66,0x5f,0xfd,0x43,0x41,0x8d,
        0x5a,0x09,0x7e,0x15,0x5b,0x1c,0x73,0x95,0x5b,0x88,0xf4,0x08,0x5b,0xe9,0x02,0xa6,
        0x20,0x76,0xac,0xc4,0x10,0xeb,0xcd,0x57,0xaf,0x34,0x36,0x36,0x3a,0x5d,0x37,0xdb,
        0xc5,0x9e,0x00,0xe6,0x37,0xd1,0x17,0x95,0x76,0xab,0x57,0xc9,0xc6,0x48,0x2a,0x48,
        0xd8,0xad,0x08,0x17,0x93,0xf6,0x9f,0xbf,0x7b,0x8a,0xe8,0x2d,0x80,0xe0,0xa9,0x9d,
        0x11,0x2a,0x66,0xb0,0xdc,0x01,0x14,0xc0,0x55,0xbe,0xe5,0x50,0xfc,0xa3,0x1a,0xf9,
        0xe9,0xcb,0xea,0x11,0xbc,0x8a,0x98,0xdd,0x24,0x6c,0x92,0x8b,0x6e,0xd8,0xe0,0x1f,
        0x4e,0x97,0x1f,0x3b,0x42,0x97,0x57,0x7a,0xc1,0x6b,0x22,0xc0,0xb2,0x97,0x87,0xa4,
        0x10,0x46,0xdd,0xd7,0xe1,0x76,0x5f,0x8b,0x3e,0x12,0x1c,0xd8,0xa4,0x1c,0xfe,0x83,
        0xe8,0x15,0x00,0xc2,0xb0,0xe5,0xf8,0xfe,0x9e,0x95,0x21,0xf1,0xaf,0xe4,0x7c,0xc2,
        0x5e,0x6d,0x98,0x82,0xdf,0xbe,0x42,0x57,0x5f,0x3c,0x46,0xbe,0xc0,0x21,0xc5,0xae,
        0xdd,0x5d,0x44,0xef,0x94,0x87,0x3c,0x64,0x76,0x8f,0x2a,0x19,0xeb,0xf4,0x12,0x91,
        0xea,0xfb,0x4d,0xc6,0xde,0xdb,0xac,0x50,0xb7,0x59,0x0d,0x8b,0x86,0xfb,0x1c,0xed,
        0x8d,0x3d,0x38,0x7d,0xa8,0x9d,0x0d,0xdd,0x98,0xbb,0x93,0x50,0xd7,0x49,0xb4,0xce,
        0xdb,0x06,0xf1,0x44,0x9d,0x6c,0x52,0x41,0x68,0x2d,0x22,0xba,0x7a,0x66,0x68,0x35,
        0xc9,0x9f,0x23,0x58,0x4d,0xbb,0xbe,0x7a,0x05,0x93,0x76,0x67,0x7c,0x97,0xa4,0x9b,
        0x94,0xec,0xb4,0x3e,0xcd,0x83,0xc0,0x7a,0x6c,0x56,0x65,0xba,0x05,0x8a,0x06,0x63,
        0xd8,0x27,0x82,0xc6,0x7a,0x60,0xcd,0x5d,0xbd,0xa3,0x75,0x93,0xff,0x02,0x9f,0x51,
        0x28,0x77,0x5b,0xb2,0x76,0x48,0x78,0x43,0x2d,0x21,0x12,0x20,0xb4,0x44,0x94,0x8c,
        0xce,0x03,0xc1,0xf5,0x88,0xf6,0x37,0xd9,0x2b,0x14,0x11,0xcb,0x2c,0x00,0xe2,0xf3,
        0x90,0xea,0x14,0xd8,0x67,0x21,0xaf,0xd0,0xd2,0x1f,0xa9,0x70,0xc2,0xd1,0x20,0xc0,
        0x3f,0x0f,0x7d,0x31,0x45,0xa1,0xde,0x7c,0x98,0x0a,0xb7,0x2e,0x4a,0x18,0x61,0x95,
        0xb1,0xf3,0x4b,0xfd,0x4b,0xc5,0x98,0xfa,0x1b,0x33,0x33,0x44,0x09,0x9d,0xb3,0xf7,
        0xaa,0x9c,0x7e,0xe3,0xd1,0xb2,0xbe,0x9d,0xa6,0x11,0xae,0xeb,0x47,0xc3,0xf1,0xe3,
        0xea,0xf3,0xad,0x1d,0x64,0x64,0xf7,0x6e,0xf8,0x7c,0x4e,0x1a,0x29,0x84,0x88,0x39,
        0x71,0x3e,0x1b,0x39,0x1d,0x78,0xf0,0x9a,0x34,0x44,0x73,0x88,0x64,0xe0,0xbc,0x78,
        0xf1,0x22,0x8a,0x2a,0x11,0x56,0x18,0x06,0x6b,0x18,0x78,0x16,0x82,0x71,0xaf,0xac,
        0x82,0x98,0x2e,0x9c,0xaa,0x57,0x30,0x38,0x39,0x2b,0xd1,0xc6,0xfd,0x2f,0x16,0x14,
        0xd4,0x40,0xc4,0x57,0x1d,0x6d,0x93,0x2e,0xd5,0xa8,0x45,0x1e,0x72,0xc8,0x0b,0xd0,
        0x33,0xb9,0x76,0x64,0xcd,0xb8,0xa6,0xa4,0x56,0x5c,0x02,0x86,0x75,0x33,0x18,0x32
    };
    NSData *plaintextData = [NSData dataWithBytes:plaintextDataArray length:sizeof(plaintextDataArray) / sizeof(uint8_t)];
    
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    QredoBulkEncKey *qredoAESbulkKey = [QredoBulkEncKey keyWithData:keyData];
    QredoKeyRef *bulkKeyRef = [keychain createKeyRef:qredoAESbulkKey];
    NSData *encryptedDataWithIv = [keychain encryptBulk:bulkKeyRef plaintext:plaintextData];
    XCTAssertNotNil(encryptedDataWithIv,@"Encrypted data with IV should not be nil.");
    NSData *decryptedData = [keychain decryptBulk:bulkKeyRef ciphertext:encryptedDataWithIv];
    XCTAssertNotNil(decryptedData,@"Decrypted data should not be nil.");

    XCTAssertTrue([plaintextData isEqualToData:decryptedData],@"Original plaintext and final plain text do not match.");
}


#pragma authenticate

-(void)testCreate0ByteKey {
    uint8_t keyDataArray[] = {};
    NSData *keyData = [NSData dataWithBytes:keyDataArray length:sizeof(keyDataArray) / sizeof(uint8_t)];
    uint8_t inputDataArray[] = {};
    NSData *inputData = [NSData dataWithBytes:inputDataArray length:sizeof(inputDataArray) / sizeof(uint8_t)];
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    XCTAssertThrows([QredoKey keyWithData:keyData]);;
}


-(void)testCreateNilKey {
    XCTAssertThrows([QredoKey keyWithData:nil]);;
}



-(void)testGetAuthCodeWithKey_WikipediaExampleData {
    NSString *keyString = @"key";
    NSData *keyData = [keyString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSString *inputString = @"The quick brown fox jumps over the lazy dog";
    NSData *inputData = [inputString dataUsingEncoding:NSASCIIStringEncoding];
    
    uint8_t expectedAuthCodeArray[] = {
        0xF7,0xBC,0x83,0xF4,0x30,0x53,0x84,0x24,0xB1,0x32,0x98,0xE6,0xAA,0x6F,0xB1,0x43,
        0xEF,0x4D,0x59,0xA1,0x49,0x46,0x17,0x59,0x97,0x47,0x9D,0xBC,0x2D,0x1A,0x3C,0xD8
    };
    NSData *expectedAuthCode = [NSData dataWithBytes:expectedAuthCodeArray length:sizeof(expectedAuthCodeArray) / sizeof(uint8_t)];
    
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    
    QredoKey *key = [QredoKey keyWithData:keyData];
    QredoKeyRef *keyRef = [keychain createKeyRef:key];
    
    NSData *authCode = [keychain authenticate:keyRef data:inputData];
    XCTAssertNotNil(authCode,@"Auth code should not be nil.");
    
    XCTAssertTrue([expectedAuthCode isEqualToData:authCode],@"Auth code is incorrect.");
}


#pragma verify


-(void)testVerifyAuthCodeWithKey_Valid {
    NSString *keyString = @"key";
    NSData *keyData = [keyString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSString *inputString = @"The quick brown fox jumps over the lazy dog";
    NSData *inputData = [inputString dataUsingEncoding:NSASCIIStringEncoding];
    
    uint8_t correctAuthCodeArray[] = {
        0xF7,0xBC,0x83,0xF4,0x30,0x53,0x84,0x24,0xB1,0x32,0x98,0xE6,0xAA,0x6F,0xB1,0x43,
        0xEF,0x4D,0x59,0xA1,0x49,0x46,0x17,0x59,0x97,0x47,0x9D,0xBC,0x2D,0x1A,0x3C,0xD8
    };
    NSData *correctAuthCode = [NSData dataWithBytes:correctAuthCodeArray length:sizeof(correctAuthCodeArray) / sizeof(uint8_t)];
    BOOL expectedVerification = YES;
    
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    QredoKey *key = [QredoKey keyWithData:keyData];
    QredoKeyRef *keyRef = [keychain createKeyRef:key];
    BOOL verificationResult = [keychain verify:keyRef data:inputData signature:correctAuthCode];
    XCTAssertTrue(expectedVerification == verificationResult,@"Auth code verification is not correct.");
}

-(void)testVerifyAuthCodeWithKey_Invalid_InputDifferent {
    NSString *keyString = @"key";
    NSData *keyData = [keyString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSString *inputString = @"The quick brown fox jumps over the lazy dog2";
    NSData *inputData = [inputString dataUsingEncoding:NSASCIIStringEncoding];
    
    uint8_t correctAuthCodeArray[] = {
        0xF7,0xBC,0x83,0xF4,0x30,0x53,0x84,0x24,0xB1,0x32,0x98,0xE6,0xAA,0x6F,0xB1,0x43,
        0xEF,0x4D,0x59,0xA1,0x49,0x46,0x17,0x59,0x97,0x47,0x9D,0xBC,0x2D,0x1A,0x3C,0xD8
    };
    NSData *correctAuthCode = [NSData dataWithBytes:correctAuthCodeArray length:sizeof(correctAuthCodeArray) / sizeof(uint8_t)];
    BOOL expectedVerification = NO;

    QredoCryptoKeychain *keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    QredoKey *key = [QredoKey keyWithData:keyData];
    QredoKeyRef *keyRef = [keychain createKeyRef:key];
    BOOL verificationResult = [keychain verify:keyRef data:inputData signature:correctAuthCode];
    XCTAssertTrue(expectedVerification == verificationResult,@"Auth code verification is not correct.");
}




@end
