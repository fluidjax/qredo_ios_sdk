/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "QredoXCTestCase.h"
#import <XCTest/XCTest.h>
#import "QredoRendezvousCrypto.h"
#import "QredoCrypto.h"
#import "CryptoImpl.h"
#import "CryptoImplV1.h"
#import "NSData+ParseHex.h"

@interface QredoRendezvousCryptoTest : QredoXCTestCase
{
    QredoRendezvousCrypto *rendezvousCrypto;
}

@end

@implementation QredoRendezvousCryptoTest

- (void)setUp
{
    [super setUp];
    rendezvousCrypto = [QredoRendezvousCrypto instance];
}

- (void)common_TestDerrivedKeysNotNilWithTag:(NSString *)tag
{
    NSData *masterKey = [rendezvousCrypto masterKeyWithTag:tag];
    XCTAssertNotNil(masterKey, @"Master key should not be nil");

    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKey];
    XCTAssertNotNil(hashedTag, @"Hashed tag should not be nil");

    NSData *authKey = [rendezvousCrypto authenticationKeyWithMasterKey:masterKey];
    XCTAssertNotNil(authKey, @"Authentication key should not be nil");

    NSData *encKey = [rendezvousCrypto encryptionKeyWithMasterKey:masterKey];
    XCTAssertNotNil(encKey, @"Authentication key should not be nil");
}

- (void)testDerrivedKeysNotNil_AnonymousRendezvous
{
    [self common_TestDerrivedKeysNotNilWithTag:@"any anonymous tag"];
}

- (void)testDerrivedKeysNotNil_TrustedRendezvous
{
    [self common_TestDerrivedKeysNotNilWithTag:@"any trusted tag@public key data"];
}


- (void)common_TestVectorsWithTag:(NSString *)tag {
    NSData *masterKey = [rendezvousCrypto masterKeyWithTag:tag];
    
    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKey];
    
    NSData *authKey = [rendezvousCrypto authenticationKeyWithMasterKey:masterKey];
    
    NSData *encKey = [rendezvousCrypto encryptionKeyWithMasterKey:masterKey];
    

    QLFKeyPairLF *requesterKeyPair  = [rendezvousCrypto newRequesterKeyPair];
    NSData *requesterPublicKeyBytes = [[requesterKeyPair pubKey] bytes];
    NSString *conversationType      = @"com.qredo.chat";

    QLFRendezvousResponderInfo *responderInfo
    = [QLFRendezvousResponderInfo rendezvousResponderInfoWithRequesterPublicKey:requesterPublicKeyBytes
                                                               conversationType:conversationType
                                                                       transCap:[NSSet set]];

    [QredoPrimitiveMarshallers marshalObject:responderInfo includeHeader:NO];
    
    NSData *encryptedResponderInfo = [rendezvousCrypto encryptResponderInfo:responderInfo encryptionKey:encKey];
    [QredoPrimitiveMarshallers unmarshalObject:encryptedResponderInfo
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];
    NSMakeRange(0, 16);
    
    [rendezvousCrypto authenticationCodeWithHashedTag:hashedTag
                                                                 authenticationKey:authKey
                                                            encryptedResponderData:encryptedResponderInfo];
}

- (void)testGenerateTestVectors
{
    [self common_TestVectorsWithTag:@"simple tag"];
    [self common_TestVectorsWithTag:@"fcc989f23ff77dd956cc5cde637c2d7eb07376dcf7322565e265e7f0913b5ad9"];

    id<QredoRendezvousCreateHelper> rendezvousHelper
    = [rendezvousCrypto rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                      fullTag:@"Ed25519@"
                                              trustedRootPems:nil
                                                      crlPems:nil
                                               signingHandler:nil
                                                        error:nil];

    [self common_TestVectorsWithTag:rendezvousHelper.tag];

    rendezvousHelper
    = [rendezvousCrypto rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
                                                      fullTag:@"RSA2048@"
                                              trustedRootPems:nil
                                                      crlPems:nil
                                               signingHandler:nil
                                                        error:nil];

    [self common_TestVectorsWithTag:rendezvousHelper.tag];


    rendezvousHelper
    = [rendezvousCrypto rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                      fullTag:@"RSA4096@"
                                              trustedRootPems:nil
                                                      crlPems:nil
                                               signingHandler:nil
                                                        error:nil];

    [self common_TestVectorsWithTag:rendezvousHelper.tag];
}

- (void)common_testVectorWithRendezvousTag:(NSString *)rendezvousTag
                        requesterPublicKey:(NSData *)requesterPublicKey
                                        iv:(NSData *)iv
                         expectedMasterKey:(NSData *)expectedMasterKey
                         expectedHashedTag:(NSData *)expectedHashedTag
                 expectedAuthenticationKey:(NSData *)expectedAuthenticationKey
                     expectedEncryptionKey:(NSData *)expectedEncryptionKey
            expectedEncryptedResponderData:(NSData *)expectedEncryptedResponderData
                expectedAuthenticationCode:(NSData *)expectedAuthenticationCode
{
    NSData *masterKey = [rendezvousCrypto masterKeyWithTag:rendezvousTag];
    XCTAssertEqualObjects(masterKey, expectedMasterKey);

    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKey];
    QredoQUID *expectedHashedTagQUID = [[QredoQUID alloc] initWithQUIDData:expectedHashedTag];
    XCTAssertEqualObjects(hashedTag, expectedHashedTagQUID);

    NSData *authKey = [rendezvousCrypto authenticationKeyWithMasterKey:masterKey];
    XCTAssertEqualObjects(authKey, expectedAuthenticationKey);

    NSData *encKey = [rendezvousCrypto encryptionKeyWithMasterKey:masterKey];
    XCTAssertEqualObjects(encKey, expectedEncryptionKey);

    NSString *conversationType = @"com.qredo.chat";

    QLFRendezvousResponderInfo *responderInfo
    = [QLFRendezvousResponderInfo rendezvousResponderInfoWithRequesterPublicKey:requesterPublicKey
                                                               conversationType:conversationType
                                                                       transCap:[NSSet set]];

    NSData *encryptedResponderInfo = [rendezvousCrypto encryptResponderInfo:responderInfo encryptionKey:encKey iv:iv];
    XCTAssertEqualObjects(encryptedResponderInfo, expectedEncryptedResponderData);

    NSData *authenticationCode = [rendezvousCrypto authenticationCodeWithHashedTag:hashedTag
                                                                 authenticationKey:authKey
                                                            encryptedResponderData:encryptedResponderInfo];
    
    QLog(@"*****%@",authenticationCode);
    
    XCTAssertEqualObjects(authenticationCode, expectedAuthenticationCode);
}

- (void)testVectorAnonymous1
{
    [self common_testVectorWithRendezvousTag:@"simple tag"
                          requesterPublicKey:[NSData dataWithHexString:@"d6a8581d 8904aac0 e7a1876e f0e376bc 7a8ca442 b5b5f8e1 50924b5d 485e0b15"]
                                          iv:[NSData dataWithHexString:@"96f8ecc0 51aa4482 5dbf9000 91b37626"]
                           expectedMasterKey:[NSData dataWithHexString:@"fcc989f2 3ff77dd9 56cc5cde 637c2d7e b07376dc f7322565 e265e7f0 913b5ad9"]
                           expectedHashedTag:[NSData dataWithHexString:@"c656e308 5bb7b2fe e3211c6a b4177ef1 c3aa9b12 5ccfdf44 bd704fc1 c8ccbd6b"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"554553ec 7376420e cb0f90ad 8e13b2ac b932cba0 f58439bb 899be026 031da7f7"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"aec94f68 7f538c8e 41ba16ea c89c59e1 b845bd32 8d746eb1 cf2dc6e9 4c19ea47"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"28373a62 00000003 0000373a 62000000 03000031 37373a62 96f8ecc0 51aa4482 5dbf9000 91b37626 84a95b5d 40c7f62a 244933bd 5f3ff606 ca2e177e d93244b1 f43ebac3 5b31203f 006d110f fb2bf70d ed3fbc83 288b431e 3f61cafd 32f4adbf 985d21c1 6e425d6c acadbeec 6f0a3768 7c32c809 acf0663d 662b2b77 9b140af7 7e2dbc53 50a1b2fe 49781574 fe02ac38 663bc148 cde02d5c a113bff2 f89f1328 c35b9f12 ba22d120 7bea18e2 1f088b75 dbc0bed1 a7fe8918 302a1398 086b9360 d553d50b caca201f 29"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"2b578f91 65006cdc 744fef0c 9c744dda 28e6ffd0 fd2c1f11 ea82c497 afe8a75b"]];
}

- (void)testVectorAnonymous2
{
    [self common_testVectorWithRendezvousTag:@"fcc989f23ff77dd956cc5cde637c2d7eb07376dcf7322565e265e7f0913b5ad9"
                          requesterPublicKey:[NSData dataWithHexString:@"5b6d589e fe52fd6f caff69f1 955e0ad1 a523218d 99ef7a27 04320941 e3fb0e57"]
                                          iv:[NSData dataWithHexString:@"d24a66b7 67877955 65ab2de8 adf296b0"]
                           expectedMasterKey:[NSData dataWithHexString:@"c8b7e06c 18fdd7e2 2636f767 7f9a3ca9 e4b3f030 8867aec6 a5aad08a fff336e4"]
                           expectedHashedTag:[NSData dataWithHexString:@"df9806a9 3c8faf0d 32e275c9 f09ae242 c43b7a72 46530659 f36d9add 22f0a376"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"40361aaa 601a402a 35b1a54a 235521a6 7ce039ce 340bb4d7 2ef6a7d4 ad1e6986"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"6d41012c 3e56f1a5 98b9ca79 f7ec6d57 62f6ff90 dfe90688 8bedf97f 65b31345"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"28373a62 00000003 0000373a 62000000 03000031 37373a62 d24a66b7 67877955 65ab2de8 adf296b0 3164bcda df3a69e5 e0e79c5c aa322828 30eef730 6394b50c 2e775560 a94ca238 e2680915 5f5132fe 5cba4708 b7c4207f de8e725d 7b12576a 54fae808 b80901c5 78ce1df2 b6d0814e bdf662c3 29d689b7 735e0a05 908ce55b aabc0521 167ada48 e8357cf7 1ce41014 7333835a b5fad347 c08823d9 b80969e2 7b5fe4fd a9a448d1 f44cd54c 0ed9de7e 9b1c1944 1b208608 ea61ece0 f4a6168a 95598214 7d6327f1 29"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"b67716ad bd5a3311 c71c24b7 74835c0a bf4d518c e35b6ab4 b6736974 c4b3682e"]];
}

- (void)testVectorEd25519
{
    [self common_testVectorWithRendezvousTag:@"Ed25519@6W1sJvs4wzaFSxSY24DbsdqQ939cZKET8eTRhXJbxeBV"
                          requesterPublicKey:[NSData dataWithHexString:@"44d8d822 c18e7de7 729d1114 f3770067 22d60e8c c03dbf77 4a42b4f0 8402d04e"]
                                          iv:[NSData dataWithHexString:@"ac03d367 689ce036 bb4198a7 c52fc85a"]
                           expectedMasterKey:[NSData dataWithHexString:@"f2680364 4793c60e d2db7fce d2799fd5 01646d5c a99a6709 764ec0d8 a8066fce"]
                           expectedHashedTag:[NSData dataWithHexString:@"1257eb33 d5ae3510 102772ca d84b643d 40513d15 2fb07ab3 ada6e3b3 c7696ed8"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"fd772c6b 1c2b796c db7217a3 1f8c214f 71cb77b0 3ad71351 811fb9b1 81346ae6"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"1bdfdf1e b19cabf5 16c56efb 1e669839 1bc95b9f e706af3d 2db2b63f ab125d00"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"28373a62 00000003 0000373a 62000000 03000031 37373a62 ac03d367 689ce036 bb4198a7 c52fc85a db638f3f b9fe436c d56362c2 61fae652 40fad57f 5e401772 a1488e35 b35a5242 2815bc4e 98babee0 4c626d0c 71ff100f 82aed190 08a0f3f9 db13d0ed 008af3e8 0e028e74 7013e3fa 0eb6eadb 60bb64d4 742f283f f0113b7a 508e5423 5dcf3b75 03aa3cac bdbcd28f 4c26c95e 09453362 e735ce04 31d2929d ed7aec7e 55876eae c8c362cf e2d5a83c 18ead062 6223e260 eee865af ac402a22 fb1488ab fff6f83f 29"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"18922fa7 7b8227bb 71d268cf bc2aa669 6a3dbdff b8727e34 cf6cb9a7 822b3d7c"]];
}

- (void)testVectorRsa2048
{
    [self common_testVectorWithRendezvousTag:@"RSA2048@-----BEGIN PUBLIC KEY-----\n"
     "MIIBCgKCAQEAxttMVWcoA3YnBMPEM5W9qtNpCR0wqNifnxp80yBNBc7WaLCBqrbI\n"
     "UmiMueMdjVut+olQN/7Ha+vmkgU44j1cEbiG2lKiD/Lj/hdaUUwgjiqvGhQzaoS8\n"
     "FDm2X0hWjtHG2Qlk7uWbxjxdE94Wi0Qi/ze7/FvV7jd9akgpwXPywl+gomNQu5W6\n"
     "W90DLQh6ny0DSJJf1ymObTuBXDznxT264raQEj59LYnIGIoMYglxwPdOYFj0TtbP\n"
     "hfEZ7DnrKXUIQ8RqASvnsm+yQxDcd5+W07wpx5+NtaLoRmjbhtvqOyZCDHTHanf+\n"
     "U+hkYaLi/RMo4IZ8GBCgJe712SV/LoVSvwIDAQAB\n"
     "-----END PUBLIC KEY-----\n"
                          requesterPublicKey:[NSData dataWithHexString:@"e9902e24 2763a9a4 452bd296 1ed56c6b 836def5a 42df65ad 4d070dfc 1a36257f"]
                                          iv:[NSData dataWithHexString:@"40918efc 1d313164 3a9c3c61 9c270005"]
                           expectedMasterKey:[NSData dataWithHexString:@"17b33a12 6c5eb2ac 25808f1d 8b750fcd bd511bfa 21b64fb3 56f930e9 1924dcbb"]
                           expectedHashedTag:[NSData dataWithHexString:@"92f9a11d 63c2041a 76b92925 798f4fca 709e2544 3295c1e6 25ace5fe caec4556"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"d2d8e70e 58b86920 5595af98 6e11a33c 2c6c1332 e0a70ee6 025f2472 3ccae205"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"3e556319 fc0311b7 27b6ceac ad6b64e0 6de13967 68cbed88 325b4a2f 17c8ea1d"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"28373a62 00000003 0000373a 62000000 03000031 37373a62 40918efc 1d313164 3a9c3c61 9c270005 06f65b44 01473fdd 6b3c352a 35097dde 803337ce 05c12837 e2cdb77c 32bb7a70 f84e70d1 d6850918 df27c1dd 7656b354 236f7cdc 835aa82a 84609e22 90090114 9ff9c3ab 278bb839 258b9485 7e3f2556 00778863 6de8a647 dc678bfb 138a51e6 c7ee436a e99e5533 399ea7e2 987ad86a 62388a71 e6c91e02 582df6d3 c8f83309 ee0ca3c0 381ed3dd ebfbd53c 9c3ca1ff 9426fd03 7c74fc82 588b4cda 86c01104 29"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"d61880a8 91423c35 ed05ae0b 6bf479c5 7fde9eb1 11a03a38 33435760 09a432eb"]];
}

- (void)testVectorRsa4096
{
    [self common_testVectorWithRendezvousTag:@"RSA4096@-----BEGIN PUBLIC KEY-----\n"
     "MIICCgKCAgEA5vFN3MxfAZTYY/n4BampkmJDcobAoEMU3De54wwYaypPl23/xsRx\n"
     "0+gVjlD19BJJj3AnUmbY4OQzFLRJLlAlhO5M5Gx3NCHG1dIp2kVfuOE5IrEP1RGu\n"
     "yzF0cIyS2QKWURWYgEmSnW3JRrcoIUpcwaZngbBORM9VDRtL00SspTFkbwnR4qjW\n"
     "kRfungaMFisuBjq9xryzC0BTWgTzjQNX/+kHpQpPQKIqNO1Sa8/1icZNtwR5t5kw\n"
     "MqXT/c/krfwnOAchyjl/jdoPIU9GSVVFGeQsndZWOu9eJZ2IGGV+5nV8F0giJXiR\n"
     "viCIvkyeNPpQ0EQq6co2DWHIPcfeOVJT3EZHVzaUWWzE15Nl180VDjItGdy+3vQw\n"
     "Bxn3uSxibABDMcREuXC12JozfyfqZWgQFyRJb/cJ3EsBe05p+2XuruPmr5fMffsW\n"
     "ZCKUqtvoMOQceEiplnqnfaG43W5gYixIoc3FdjlZsWdX8VUHGNJxk3CHqNo96NrQ\n"
     "Xo4XJ8+VJM/UBDHyHIFD/KwcUgYt/aGeLNdR56YTXbzZzztDaYY4qQ28V6f0XcO7\n"
     "44v1ZgEotZcjDBOm2A1pH49jC89XS5JTAM7uiR82C7RBbQP98R2pyDlA2fjQjxM1\n"
     "kygNOQmNE5/EtNLHwqZ70J2ZTnrfAj5gMoGRuRFXIFZ+5kHlGy3Qg6ECAwEAAQ==\n"
     "-----END PUBLIC KEY-----\n"
                          requesterPublicKey:[NSData dataWithHexString:@"2f3186a3 64963c85 fdf44647 31d78a26 7448f047 257c981c ea3fe215 90098041"]
                                          iv:[NSData dataWithHexString:@"5570c5f6 9b0a9916 605150b3 fdc0a1ea"]
                           expectedMasterKey:[NSData dataWithHexString:@"63b11411 144e9263 21b6e56e f76c8c56 a3cd38aa 8fc4665a 31796840 d4b8aadb"]
                           expectedHashedTag:[NSData dataWithHexString:@"e93343c4 91d2806b 3d6652e0 273b1544 09d0b67f 36434977 0ba847a8 95d1940e"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"31562e03 50a9b6e2 05f386de 21fa7b1b 7d8d0f62 a3d2fdd7 16a71f8d 4d48d552"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"45c19e09 731b3708 fb7a481d 0cbe96cb 308cc71a fb5ce08a 9ad91c9a 9f83abce"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"28373a62 00000003 0000373a 62000000 03000031 37373a62 5570c5f6 9b0a9916 605150b3 fdc0a1ea 40c8011b e4e5433e f5101bf0 fc9d32f2 5bb56b05 0eda8e6b cee98256 725ff953 9c9fc784 086137d6 41f44330 bf624488 4645a551 99452074 b0f2defd 03a823ee 8809535e 8d77ab37 bd443c7b 3f0acd7d f00d9803 b3834634 0dab31d6 52ef3c4c 74432c14 d8acc46b 473434d1 2eaaad71 5481e64a 6f47450e 1cf7c5d3 5398e81b ae8bda1d 242d929e e432cd51 8508d6c1 3fa97136 d73c52e3 e242fa65 9a432d8c 29"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"d8fd079d 56635984 2fb4e4df cbcf3d25 b88bdd9c 47483c3a 677e4268 57607c4e"]];
}
@end
