/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoRendezvousCrypto.h"
#import "QredoCrypto.h"
#import "CryptoImpl.h"
#import "CryptoImplV1.h"
#import "NSData+ParseHex.h"

@interface QredoRendezvousCryptoTest : XCTestCase
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
    NSLog(@"============ BEGIN ============");
    NSData *masterKey = [rendezvousCrypto masterKeyWithTag:tag];
    NSLog(@"Rendezvous tag: \"%@\"", tag);
    NSLog(@"Master key: %@", masterKey);

    QLFRendezvousHashedTag *hashedTag = [rendezvousCrypto hashedTagWithMasterKey:masterKey];
    NSLog(@"Hashed tag: %@", [hashedTag data]);

    NSData *authKey = [rendezvousCrypto authenticationKeyWithMasterKey:masterKey];
    NSLog(@"Authentication key: %@", authKey);

    NSData *encKey = [rendezvousCrypto encryptionKeyWithMasterKey:masterKey];
    NSLog(@"Encryption key: %@", encKey);


    QLFKeyPairLF *requesterKeyPair  = [rendezvousCrypto newRequesterKeyPair];
    NSData *requesterPublicKeyBytes = [[requesterKeyPair pubKey] bytes];
    NSString *conversationType      = @"com.qredo.chat";

    NSLog(@"---");
    NSLog(@"Responder Info:");
    NSLog(@"Requester public key: %@", requesterPublicKeyBytes);
    NSLog(@"Conversation type: \"%@\"", conversationType);




    QLFRendezvousResponderInfo *responderInfo
    = [QLFRendezvousResponderInfo rendezvousResponderInfoWithRequesterPublicKey:requesterPublicKeyBytes
                                                               conversationType:conversationType
                                                                       transCap:[NSSet set]];

    NSData *marshalledResponderInfo = [QredoPrimitiveMarshallers marshalObject:responderInfo];
    NSLog(@"Marshalled responder info %@", marshalledResponderInfo);
    NSLog(@"---");

    NSData *encryptedResponderInfo = [rendezvousCrypto encryptResponderInfo:responderInfo encryptionKey:encKey];
    NSLog(@"Encrypted responder info %@", encryptedResponderInfo);

    NSData *authenticationCode = [rendezvousCrypto authenticationCodeWithHashedTag:hashedTag
                                                                 authenticationKey:authKey
                                                            encryptedResponderData:encryptedResponderInfo];

    NSLog(@"Authentication code: %@", authenticationCode);
    NSLog(@"============ END ============");
}

- (void)testGenerateTestVectors
{
    [self common_TestVectorsWithTag:@"simple tag"];
    [self common_TestVectorsWithTag:@"fcc989f23ff77dd956cc5cde637c2d7eb07376dcf7322565e265e7f0913b5ad9"];

    id<QredoRendezvousCreateHelper> rendezvousHelper
    = [rendezvousCrypto rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeEd25519
                                                      fullTag:@"Ed25519@"
                                              trustedRootPems:nil
                                               signingHandler:nil
                                                        error:nil];

    [self common_TestVectorsWithTag:rendezvousHelper.tag];

    rendezvousHelper
    = [rendezvousCrypto rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa2048Pem
                                                      fullTag:@"RSA2048@"
                                              trustedRootPems:nil
                                               signingHandler:nil
                                                        error:nil];

    [self common_TestVectorsWithTag:rendezvousHelper.tag];


    rendezvousHelper
    = [rendezvousCrypto rendezvousHelperForAuthenticationType:QredoRendezvousAuthenticationTypeRsa4096Pem
                                                      fullTag:@"RSA4096@"
                                              trustedRootPems:nil
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
    XCTAssertEqualObjects(authenticationCode, expectedAuthenticationCode);
}

- (void)testVectorAnonymous1
{
    [self common_testVectorWithRendezvousTag:@"simple tag"
                          requesterPublicKey:[NSData dataWithHexString:@"170da4b3 f0cdd9b0 7b750def 37a3222a 6eb7ced5 f59584b3 a2d0dafa aa646d78"]
                                          iv:[NSData dataWithHexString:@"654c27de 2e445b0e 07b021d1 ed289226"]
                           expectedMasterKey:[NSData dataWithHexString:@"fcc989f2 3ff77dd9 56cc5cde 637c2d7e b07376dc f7322565 e265e7f0 913b5ad9"]
                           expectedHashedTag:[NSData dataWithHexString:@"45e11a5d 5376f6b2 a7190445 6386752a 77a532b6 95e61666 97191a07 1efc762e"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"5e223be2 19ace014 1e642433 922da0dc 79b69c1b 9ab5e168 f1cc161f f43520a5"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"82492e20 fba5e460 78c32bb3 fcd71fb4 65510833 f95c4caf c4380a91 516b2af8"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"654c27de 2e445b0e 07b021d1 ed289226 189cfd6f 4982e208 00384ed8 bcdecb07 fbe22e09 71ecbcbd 01669fd0 66fba748 056d3644 8acaf6ee 71c50cdf 96e42905 a42253d6 433c9517 fcd52e80 e402bb24 2234064b 6d901667 fde4438b a1042fe9 a8496b2b db1a9201 c8fa5a21 f2d6c0a5 3de5caa4 b2cf0a94 1152ae3c 924cef28 0fbc24f3 d56c8693 07233ccd e322c426 89d4f79a becf45fd 9f78161b b7ee6a7d 18b17435 0f482be6 30a35ded 3c5ec3cc f525cb56 2b4dcf98 d047b4b1 60eadbc1"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"3180e9b8 39f7660f c3fc29f1 5b5e77cc 697a2b00 f8f20bd7 6a699110 54933fe9"]];
}

- (void)testVectorAnonymous2
{
    [self common_testVectorWithRendezvousTag:@"fcc989f23ff77dd956cc5cde637c2d7eb07376dcf7322565e265e7f0913b5ad9"
                          requesterPublicKey:[NSData dataWithHexString:@"a9e433b6 d53fb533 31803d8b 2eeb0a46 7f738d84 b95fbf06 8e9c5d39 b232283b"]
                                          iv:[NSData dataWithHexString:@"45dd4f82 e3d9aa0e 50ea33ad 5c53f3d0"]
                           expectedMasterKey:[NSData dataWithHexString:@"c8b7e06c 18fdd7e2 2636f767 7f9a3ca9 e4b3f030 8867aec6 a5aad08a fff336e4"]
                           expectedHashedTag:[NSData dataWithHexString:@"c9690da0 3fb47251 02df5c82 ecbff02c 4876c40e 5b28a432 4d95a6d1 56aa8870"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"211f0f19 7862b138 0d11f10c 4f271f59 833f82a9 6a5a1672 b3d28f3b 84b32306"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"a0bd48dc 0e966902 e59c5edd 41a78746 1a23e7b0 b252c81a c8d7543a 1f6ae4b8"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"45dd4f82 e3d9aa0e 50ea33ad 5c53f3d0 7ff9d352 a88a4eea 5bd8906a 54d41562 502f5cf9 f7e963b5 04261bce ded8677d 79e68cb6 8710d236 26b4333b 097179a1 aaff97c2 6550da1f 9bad6ced 7f971300 e8778a72 0494792c 929eff65 6e9a7dba fc3312fa 00c4b105 8f1d40a8 5d9ad4d5 5fbbfda2 b7cfd129 e483f257 49564cc4 94b0f431 2c6f1c7e d97dbbc7 290e67c9 61450578 0115f643 dad2cd67 b4d30e50 7238816c 841e7c65 96a9d3da def6dcfc 52d9ec7b 64f5313c 05b025c1 7d0b89c5"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"f092c7c5 257d5737 a18ba467 c185cfab 8ed8cf0c 0b05d11a 8d05f931 c9ac4212"]];
}

- (void)testVectorEd25519
{
    [self common_testVectorWithRendezvousTag:@"Ed25519@EnsTU9pNJqRvZCdDEi8v2UomYKbYYatVxT9BjJYnPhDm"
                          requesterPublicKey:[NSData dataWithHexString:@"b0d5e6a2 9f1ef48c 8bda0428 136ab1d4 adcdcc4c 14c64197 c5cb2c77 b15b0964"]
                                          iv:[NSData dataWithHexString:@"ea874509 ffdf4960 03bd5dba f199f3bc"]
                           expectedMasterKey:[NSData dataWithHexString:@"91b7ccfc 0ca921a2 d57589cd 2a9e29e2 62b68d46 15a5cb1c 996f23cf fc261dca"]
                           expectedHashedTag:[NSData dataWithHexString:@"1d9ef515 cc3ad1ea 34a0d56f 3fd607f8 d6ab2189 c92f3129 20955afa aea7c564"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"45d5fd3e fc7a2b0c 43efa7e9 2f52dc66 cf14bf6d 51a6952c 67861526 67e2b239"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"e37fb166 840015b1 891decdf 61c7b359 1630b902 c152e1b5 15cd9358 1f2f96aa"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"ea874509 ffdf4960 03bd5dba f199f3bc 3888341b 3f47d0a6 7dd7996d 95e0cc82 35178b0a b413c0ab b70e2e50 95c0ea5e 319f67c7 552eb911 e93e7bcc a1dac672 dccdbac4 0f0c3e8d f77dc44d 8791cd29 64e3883f 7996508b 931dbb51 49b06f71 9faf19df 0561af4b 945fa9fa ffb51661 8f737b93 46da4498 095a52db 95c8cf31 aa4d7259 576252b5 9d737928 50abe10b a3434acb 5c9ff31d fd3a29ce 16791b62 c2f297c5 c16b2f13 72d6d50f 73f1de74 f9d4d5e8 8a0e9195 0d077491 3f25fb39"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"280acb82 38fdc637 90abb382 7fda72d9 e9881417 57cf2411 4af356a1 265f024b"]];
}

- (void)testVectorRsa2048
{
    [self common_testVectorWithRendezvousTag:@"RSA2048@-----BEGIN PUBLIC KEY-----\n"
     "MIIBCgKCAQEAmWXyJIrVRUdXcwsIaWHoqjhPqoDLLnEuSuc4b9qGxOxJhubTTbZa\n"
     "dAPtv0+uYVjDPX+vccGEXJ6RKTHbA9XH5+arTtQ20FGRQj4eB+AW1yXIpVVMPmrt\n"
     "q/HOGBqGwXtjafNfXxv05tUK9+Hr9po5TVTnzhsiCgQ33i/qT4HGx90F9oI0+RMB\n"
     "WeikBJNZ9fAi7hCGQGOUK1bqbAhAgOJThMHjbFEoH48zJetcQCwCxLn8AgjtUUbx\n"
     "Omi8tOzkck2Q6CZ/Ef4Cni5R5qOiM+CvLg/E/p0W1gkd2M0Vlh6OhsQmDGtspF5k\n"
     "sEKUcxUWR/ph88rpheanrGISurrw1BNawQIDAQAB\n"
     "-----END PUBLIC KEY-----\n"
                          requesterPublicKey:[NSData dataWithHexString:@"ea3a2249 8b5376e1 b8c28c55 20a36e48 b25b4481 b07931a4 53b0cae5 a21b825c"]
                                          iv:[NSData dataWithHexString:@"171b2b05 c688d91d c3f56e4e c6a888f8"]
                           expectedMasterKey:[NSData dataWithHexString:@"9715d83b 0e41ed4d 2800c031 d10557c8 3ae03d23 e8b42b6e ec2cf8bc 8c578a96"]
                           expectedHashedTag:[NSData dataWithHexString:@"ffe888e8 24affbe0 a5425d7a c1609360 6e5422ba 1098d7a3 12a314f6 4aba4bf8"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"3e3dee63 315c07f7 83fa7293 45c47e1e 9308a733 d65b369e cb60beb1 011766f8"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"54c7a96a 54a22ddf 4b8f8f6d f1463410 15f0ae14 709713cb 1eca0697 438d9ab5"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"171b2b05 c688d91d c3f56e4e c6a888f8 ca180a49 be9605e6 190f8d58 9c63bf24 122198c6 ca97a894 93173b22 f1ad0f3c 413d992b b4c069e8 b8c64dba 8ea3c63d f72a33e2 9ed032a7 c72b38ab 64f758aa 656a1170 6b369808 2b189aff 58f952b4 68efe3d6 c77110de 62e5add5 f6b6e578 20d832c9 bb8cf208 d0009264 579f915b 68a452cd 8af408f2 f067a59f 465f3fdc 42ee32f4 d4ea8c3b 5e9efb55 7f61424a 3161a864 fc07fa9d d0f75bb9 39157820 06725305 50be7d12 cfa8114f ae71e8bf"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"32081c5b 234afc5c 14eed8b6 2ec556e5 e3857e7d c961d79b ac59fded bfe7a6dd"]];
}

- (void)testVectorRsa4096
{
    [self common_testVectorWithRendezvousTag:@"RSA4096@-----BEGIN PUBLIC KEY-----\n"
     "MIICCgKCAgEAyodmGOQiEkc4/emmx5hj242mls73dYFwpoxFHCupMji2V39Hx2pC\n"
     "Qkdqk9rWsrK5YXvccMxqm4tMi7u4iuXLeE5FiD/VHyOCQO6W6nQgH9aBnmTBm14d\n"
     "DTv65To7Dj/0OLnKMMvM3zTfNAtSHb/fWAIe60mSF7q4iJJglUr6V4gIohZAsZS6\n"
     "X1+7V7noVhZeKFXT2/UwUqH4ZECKgjZO4cyz1dfOkw+JWRgQSksDMzzbgZzC9oz2\n"
     "g9JZNtCHLtWQJi0Dhy0VEeyPqKiMqCRsUUtIst2j83k97GeicPDpOZalHpzBQ/m0\n"
     "g79mDX2F2Z/OlR5zN8U+jn0VMa7SvRaFFEsVLqg7DfAFzcW/KTrU24sKTIvmtqBS\n"
     "EMk49v26KHSgaNNCfi4euRcy7BFHYwF3LLsECcLytx3HxkHuCFOdN7RloB1TWB4z\n"
     "AJZnIiYfPca4QvUvIUridnCEOJeYaK9QkmZQNmWjPpMe67FVG5hVeG/ccGFU59yc\n"
     "fpIkMLDqBplVcHkT7nnp7A+cplJqJi7JdI8JX8BhQm5SsqxJf6y+fZANtuz6T2Bt\n"
     "Hy/9kbbnirScNckuyyFCl02n7Au7sIX0IsO0Apd771G4Xt2UI+yE/5SlV+8qPqqN\n"
     "U93/J9hAE7LX4Xxcn/J7QwMpjVxly1qxH5Vjy8JqxLMuJ3MhKAXhhWkCAwEAAQ==\n"
     "-----END PUBLIC KEY-----\n"
                          requesterPublicKey:[NSData dataWithHexString:@"5f6fa0f6 866be6b8 69dc52cd a516b1c3 4ac15fc8 bce4a470 64d60967 2b557810"]
                                          iv:[NSData dataWithHexString:@"f6909f6d b0fcea1d a08ba8d1 ee17eeb9"]
                           expectedMasterKey:[NSData dataWithHexString:@"a93af642 de141850 e504eaf6 b9cbedde 2534623c 7c58326d 83219d1a fcd14661"]
                           expectedHashedTag:[NSData dataWithHexString:@"000af09d c4ef21c4 74d37f14 688f1f3a f5ea9ac4 84311923 fd8a5d19 16b2cb60"]
                   expectedAuthenticationKey:[NSData dataWithHexString:@"4d1423d8 d7983ce2 193fe98f f56d7f19 a8c098c5 0c05abe7 7818f3bf db7d3772"]
                       expectedEncryptionKey:[NSData dataWithHexString:@"9340c2dc 8bd6e767 1f4ff065 579e5e6d c6c1baf4 80a0f239 91a6b3a6 50d4139d"]
              expectedEncryptedResponderData:[NSData dataWithHexString:@"f6909f6d b0fcea1d a08ba8d1 ee17eeb9 75787327 8027bda6 ca68525b 0c63b8be 03a5d9e7 d6df3a8e 14ed1dd8 6d833ce4 53abad97 5cd97eb0 abce1cce 6a13ff77 e01daed2 85b926b2 3244c782 39e6d39f c0fb5a97 495b7c59 522e1935 2febb947 83e5beb1 e9697b07 1fd36f81 237d1d46 7245243e 054eed2c 2f46ccec 6279ba31 da74cf09 dd19f96b edff0179 c76d5302 abdd64db 193f3b8b 12f1fa2a 7d97b564 5bdaecce ab435c87 ba23689b deb051a8 d8900e24 1aaa2906 17747f8e 4bfc7b66"]
                  expectedAuthenticationCode:[NSData dataWithHexString:@"2a67cdb5 ff8a1208 ebd16aa5 f2d22c69 2426ee03 81d7f807 8a8f2d92 74190ac6"]];
}
@end
