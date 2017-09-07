#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoCryptoRaw.h"
#import "QredoCryptoImplV1.h"
#import <CommonCrypto/CommonCrypto.h>
#import "QredoLoggerPrivate.h"
#import "QredoUtils.h"
#import "QredoConversationCrypto.h"
#import "QredoXCTestCase.h"

@interface QredoCryptoTests :XCTestCase

@end

@implementation QredoCryptoTests

-(void)setUp {
    [super setUp];
}



-(void)tearDown {
    [super tearDown];
}


-(void)testED25519Sign{
    QredoCryptoImplV1 *crypto = [QredoCryptoImplV1 sharedInstance];
    QredoConversationCrypto *conversationCrypto = [[QredoConversationCrypto alloc] init];
    
    NSData *myPrivateKeyData  = [QredoUtils hexStringToData:@"1c68b754 1878ffff d8a7d9f2 94d90ff6 bf28b9d0 e0a72ef3 7d37d645 4d578d2a"];
    NSData *yourPublicKeyData = [QredoUtils hexStringToData:@"9572dd9c f1ea2d5f de2e4baa 40b2dceb b6735e79 2b4fa374 52b4c8cd ea2a1b0e"];
    QredoKeyRef *myPrivateKey = [QredoKeyRef keyRefWithKeyData:myPrivateKeyData];
    QredoKeyRef *yourPublicKeyRef = [QredoKeyRef keyRefWithKeyData:yourPublicKeyData];
    
    QredoKeyRef *masterKeyRef = [conversationCrypto conversationMasterKeyWithMyPrivateKeyRef:myPrivateKey yourPublicKeyRef:yourPublicKeyRef];
    QredoKeyRef *requesterInboundEncryptionKeyRef = [conversationCrypto requesterInboundEncryptionKeyWithMasterKeyRef:masterKeyRef];
    QredoKeyRef *requesterInboundAuthenticationKey = [conversationCrypto requesterInboundAuthenticationKeyWithMasterKeyRef:masterKeyRef];
    QredoKeyRef *requesterInboundQueueSeedRef = [conversationCrypto requesterInboundQueueSeedWithMasterKeyRef:masterKeyRef];
    QredoED25519SigningKey *requesterOwnershipKeyPair = [crypto qredoED25519SigningKeyWithSeed:[requesterInboundQueueSeedRef debugValue]];
    
    NSData *message     = [QredoUtils hexStringToData:@"0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"];
    NSData *expected = [QredoUtils hexStringToData:@"e439f1f2 a42e13a1 94c54887 55432003 7fbadbaa 0cc70a56 209b4b38 081486fb 7b5af188 c4c45f3a 4cfe6944 cfa4153a 89e48999 58ee5fe5 3d2367dd b8e6db0e"];
    
    NSData *result = [crypto qredoED25519SignMessage:message withKey:requesterOwnershipKeyPair error:nil];
    
    XCTAssertTrue([result isEqualToData:expected],@"Failed to sign");
}


-(void)testHkdfRFC5869TestCase1{
    NSData *ikm     = [QredoUtils hexStringToData:@"0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"];
    NSData *salt    = [QredoUtils hexStringToData:@"000102030405060708090a0b0c"];
    NSData *info    = [QredoUtils hexStringToData:@"f0f1f2f3f4f5f6f7f8f9"];
    int length = 42;
    NSData *expected    = [QredoUtils hexStringToData:@"3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865"];
    NSData *prk = [QredoCryptoRaw hkdfSha256Extract:ikm salt:salt];
    NSData *okm = [QredoCryptoRaw hkdfSha256Expand:prk info:info outputLength:length];
    XCTAssertTrue([okm isEqualToData:expected],@"hkdf fails RFC Test1");
}


-(void)testHkdfRFC5869TestCase2{
    NSData *ikm     = [QredoUtils hexStringToData:@"000102030405060708090a0b0c0d0e0f\
                       101112131415161718191a1b1c1d1e1f\
                       202122232425262728292a2b2c2d2e2f\
                       303132333435363738393a3b3c3d3e3f\
                       404142434445464748494a4b4c4d4e4f"];
    NSData *salt    = [QredoUtils hexStringToData:@"606162636465666768696a6b6c6d6e6f\
                       707172737475767778797a7b7c7d7e7f\
                       808182838485868788898a8b8c8d8e8f\
                       909192939495969798999a9b9c9d9e9f\
                       a0a1a2a3a4a5a6a7a8a9aaabacadaeaf"];
    NSData *info    = [QredoUtils hexStringToData:@"b0b1b2b3b4b5b6b7b8b9babbbcbdbebf\
                       c0c1c2c3c4c5c6c7c8c9cacbcccdcecf\
                       d0d1d2d3d4d5d6d7d8d9dadbdcdddedf\
                       e0e1e2e3e4e5e6e7e8e9eaebecedeeef\
                       f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff"];
    int length = 82;
    NSData *expected= [QredoUtils hexStringToData:@"b11e398dc80327a1c8e7f78c596a4934\
                       4f012eda2d4efad8a050cc4c19afa97c\
                       59045a99cac7827271cb41c65e590e09\
                       da3275600c2f09b8367793a9aca3db71\
                       cc30c58179ec3e87c14c01d5c1f3434f\
                       1d87"];

    NSData *prk = [QredoCryptoRaw hkdfSha256Extract:ikm salt:salt];
    NSData *okm = [QredoCryptoRaw hkdfSha256Expand:prk info:info outputLength:length];
    XCTAssertTrue([okm isEqualToData:expected],@"hkdf fails RFC Test2");
}



-(void)testEncryptDecryptAES{
    NSData *key                 = [QredoUtils hexStringToData:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *iv                  = [QredoUtils hexStringToData:@"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff"];
    
    [self encryptDecrypt:[QredoUtils hexStringToData:@""] key:key iv:iv];
    [self encryptDecrypt:[QredoUtils hexStringToData:@"01"] key:key iv:iv];
    [self encryptDecrypt:[QredoUtils hexStringToData:@"0102030405060708090a0b0c0d0e0f"] key:key iv:iv];
    [self encryptDecrypt:[QredoUtils hexStringToData:@"0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f"] key:key iv:iv];
    [self encryptDecrypt:[QredoUtils hexStringToData:@"ffff"] key:key iv:iv];
}



-(void)encryptDecrypt:(NSData*)plaintext key:(NSData*)key iv:(NSData*)iv{
    NSData *encrypted = [QredoCryptoRaw aes256CtrEncrypt:plaintext key:key iv:iv];
    NSData *decrypted = [QredoCryptoRaw aes256CtrDecrypt:encrypted key:key iv:iv];
    XCTAssertNotNil(decrypted,@"Encrypted data should not be nil.");
    if (plaintext.length>0) XCTAssertFalse([encrypted isEqualToData:plaintext],@"If plaintext is not 0 bytes, encrypted shouldn't be the same as plaintext.");
    XCTAssertTrue([decrypted isEqualToData:plaintext],@"Encrypted data incorrect.");
}


-(void)testDecryptData256BitKey {
    NSData *key                 = [QredoUtils hexStringToData:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *iv                  = [QredoUtils hexStringToData:@"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff"];
    NSData *plaintext           = [QredoUtils hexStringToData:@"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710"];
    NSData *encrypted           = [QredoUtils hexStringToData:@"601ec313775789a5b7a7f504bbf3d228f443e3ca4d62b59aca84e990cacaf5c52b0930daa23de94ce87017ba2d84988ddfc9c58db67aada613c2dd08457941a6"];
    
    NSData *result = [QredoCryptoRaw aes256CtrDecrypt:encrypted key:key iv:iv];
    XCTAssertNotNil(result,@"Encrypted data should not be nil.");
    XCTAssertTrue([result isEqualToData:plaintext],@"Encrypted data incorrect.");
}


-(void)testDecryptData256ZeroCounter {
    NSData *key                 = [QredoUtils hexStringToData:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *iv                  = [QredoUtils hexStringToData:@"44444444444444440000000000000000"];
    NSData *plaintext           = [QredoUtils hexStringToData:@"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710"];
    NSData *encrypted           = [QredoUtils hexStringToData:@"5b50fe7bf8ffccf20188aba99aeebc7294192b348a0050083ea85e801c5c4b44309f6073e442bb54e07a810f655ded190de58c497a4763a1e70acf21cc1a582d"];
    NSData *result = [QredoCryptoRaw aes256CtrDecrypt:encrypted key:key iv:iv];
    XCTAssertNotNil(result,@"Encrypted data should not be nil.");
    XCTAssertTrue([result isEqualToData:plaintext],@"Encrypted data incorrect.");
}







-(void)testDecryptData256BitKey_NilIv {
    NSData *key                 = [QredoUtils hexStringToData:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *plaintext           = [QredoUtils hexStringToData:@"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710"];
    NSData *encrypted           = [QredoUtils hexStringToData:@"8ea94863ba8fe940fe7032d13083bf7e3f38940a1579b3875e60c37ceb91dfb527c63f97d00036c49c1dfb9161c39afcbe9218a879799e723852f46d728e8f3e"];
    XCTAssertThrows([QredoCryptoRaw aes256CtrDecrypt:encrypted key:key iv:[NSData data]],@"Should throw an exception");
}


-(void)testDecryptData256BitNilInput {
    NSData *key                 = [QredoUtils hexStringToData:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *iv                  = [QredoUtils hexStringToData:@"00000000000000000000000000000000"];
    NSData *plaintext           = [QredoUtils hexStringToData:@"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([QredoCryptoRaw aes256CtrDecrypt:nil key:key iv:iv],@"Should throw an exception");
#pragma clang diagnostic pop
    
    
}



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

    XCTAssertThrows([QredoCryptoRaw aes256CtrDecrypt:encryptedData key:keyData iv:ivData],@"Invalid IV length but NSInvalidArgumentException not thrown.");
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
    
    XCTAssertThrows([QredoCryptoRaw aes256CtrDecrypt:encryptedData key:keyData iv:ivData],@"Invalid IV length but NSInvalidArgumentException not thrown.");
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
    
    XCTAssertThrows([QredoCryptoRaw aes256CtrEncrypt:plaintextData key:keyData iv:ivData],@"Invalid key length but NSInvalidArgumentException not thrown.");
}




-(void)testEncryptData256BitKeyRollOver {
    NSData *key                 = [QredoUtils hexStringToData:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *iv                  = [QredoUtils hexStringToData:@"6666666666666666ffffffffffffffff"];

    NSData *plaintext           = [QredoUtils hexStringToData:@"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710"];
    NSData *encrypted           = [QredoUtils hexStringToData:@"1fb6d992fafa44500fe03c61781d111710e1078e8609529cc4f9e8be68d4d38bcd0f55c344a974af029b79b28960e8c943bc75428d46b51457dc261246a075ac"];
    
    NSData *result = [QredoCryptoRaw aes256CtrEncrypt:plaintext key:key iv:iv];
    XCTAssertNotNil(result,@"Encrypted data should not be nil.");
    XCTAssertTrue([result isEqualToData:encrypted],@"Encrypted data incorrect.");
}



-(void)testEncryptData256BitKey {
    NSData *key                 = [QredoUtils hexStringToData:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *iv                  = [QredoUtils hexStringToData:@"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff"];
    NSData *plaintext           = [QredoUtils hexStringToData:@"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710"];
    NSData *encrypted           = [QredoUtils hexStringToData:@"601ec313775789a5b7a7f504bbf3d228f443e3ca4d62b59aca84e990cacaf5c52b0930daa23de94ce87017ba2d84988ddfc9c58db67aada613c2dd08457941a6"];
    
    NSData *result = [QredoCryptoRaw aes256CtrEncrypt:plaintext key:key iv:iv];
    XCTAssertNotNil(result,@"Encrypted data should not be nil.");
    XCTAssertTrue([result isEqualToData:encrypted],@"Encrypted data incorrect.");
}



-(void)testEncryptData256BitKey_NilIv {
    NSData *key                 = [QredoUtils hexStringToData:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *plaintext           = [QredoUtils hexStringToData:@"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([QredoCryptoRaw aes256CtrEncrypt:plaintext key:key iv:nil],@"Should throw an exception");
#pragma clang diagnostic pop
    
    
}

-(void)testEncryptData256BitNilInput {
    NSData *key                 = [QredoUtils hexStringToData:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *iv                  = [QredoUtils hexStringToData:@"0000000000000000"];
    NSData *plaintext           = [QredoUtils hexStringToData:@"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710"];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([QredoCryptoRaw aes256CtrEncrypt:nil key:key iv:iv],@"Should throw an exception");
#pragma clang diagnostic pop
    
    }


 
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
    
    XCTAssertThrows([QredoCryptoRaw aes256CtrEncrypt:plaintextData key:keyData iv:ivData],@"Invalid IV length but NSInvalidArgumentException not thrown.");
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
    
    XCTAssertThrows([QredoCryptoRaw aes256CtrEncrypt:plaintextData key:keyData iv:ivData],@"Invalid IV length but NSInvalidArgumentException not thrown.");
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
    
    NSData *prk = [QredoCryptoRaw hkdfSha256Extract:ikmData salt:saltData];
    
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
    
    NSData *okm = [QredoCryptoRaw hkdfSha256Expand:keyData info:infoData outputLength:outputLength];
    
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

    NSData *prk = [QredoCryptoRaw hkdfSha256Extract:ikmData salt:saltData];
    NSData *okm = [QredoCryptoRaw hkdfSha256Expand:prk info:infoData outputLength:CC_SHA256_DIGEST_LENGTH];

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
    
    NSData *derivedKey = [QredoCryptoRaw pbkdf2Sha256:passwordData salt:saltData outputLength:keyLength iterations:iterations];
    
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
    
    NSData *derivedKey = [QredoCryptoRaw pbkdf2Sha256WithSalt:saltData  passwordData:passwordData requiredKeyLengthBytes:keyLength iterations:iterations];
    
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
    
    
    NSData *mac = [QredoCryptoRaw hmacSha256:data key:keyData outputLen:data.length];
    
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
    NSData *mac = [QredoCryptoRaw hmacSha256:data key:keyData outputLen:64];
    
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
    
    NSData *hash = [QredoCryptoRaw sha256:data];
    
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
    
    NSData *hash = [QredoCryptoRaw sha256:data];
    
    XCTAssertNotNil(hash,@"Hash should not be nil.");
    XCTAssertTrue([expectedHashData isEqualToData:hash],@"Hash data incorrect.");
}


-(void)testSecureRandom {
    NSData *randomBytes1 = [QredoCryptoRaw secureRandom:32];
    NSData *randomBytes2 = [QredoCryptoRaw secureRandom:32];
    NSData *randomBytes3 = [QredoCryptoRaw secureRandom:64];
    NSData *randomBytes4 = [QredoCryptoRaw secureRandom:128];
    NSData *randomBytes5 = [QredoCryptoRaw secureRandom:256];
    NSData *randomBytes6 = [QredoCryptoRaw secureRandom:131072];
    
    XCTAssertEqual([randomBytes1 length],32);
    XCTAssertEqual([randomBytes2 length],32);
    XCTAssertEqual([randomBytes3 length],64);
    XCTAssertEqual([randomBytes4 length],128);
    XCTAssertEqual([randomBytes5 length],256);
    XCTAssertEqual([randomBytes6 length],131072);
    XCTAssertFalse([randomBytes1 isEqualToData:randomBytes2]);
}


-(void)testConstantEquals_SameData {
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
    
    BOOL comparisonResult = [QredoCryptoRaw constantEquals:leftData rhs:rightData];
    
    XCTAssertTrue(expectedComparisonResult == comparisonResult,@"Comparison check failed.");
}


-(void)testConstantEquals_DifferentLengths {
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
    
    BOOL comparisonResult = [QredoCryptoRaw constantEquals:leftData rhs:rightData];
    
    XCTAssertTrue(expectedComparisonResult == comparisonResult,@"Comparison check failed.");
}


-(void)testConstantEquals_EmptyData {
    uint8_t leftDataArray[] = {
    };
    NSData *leftData = [NSData dataWithBytes:leftDataArray length:sizeof(leftDataArray) / sizeof(uint8_t)];
    
    uint8_t rightDataArray[] = {
    };
    NSData *rightData = [NSData dataWithBytes:rightDataArray length:sizeof(rightDataArray) / sizeof(uint8_t)];
    
    BOOL expectedComparisonResult = YES;
    
    BOOL comparisonResult = [QredoCryptoRaw constantEquals:leftData rhs:rightData];
    
    XCTAssertTrue(expectedComparisonResult == comparisonResult,@"Comparison check failed.");
}


-(void)testConstantEquals_CheckComparisonTimesCorrect {
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
            [QredoCryptoRaw constantEquals:leftData rhs:rightCorrectData];
        }
    }];
}


-(void)testConstantEquals_CheckComparisonTimesWithFirstByteWrong {
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
            [QredoCryptoRaw constantEquals:leftData rhs:rightIncorrectData];
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





@end
