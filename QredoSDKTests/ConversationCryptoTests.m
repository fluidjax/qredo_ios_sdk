/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoConversationCrypto.h"
#import "CryptoImplV1.h"
#import "NSData+ParseHex.h"

@interface ConversationCryptoTests : XCTestCase
{
    QredoConversationCrypto *_conversationCrypto;
    CryptoImplV1 *_crypto;
}

@end

@implementation ConversationCryptoTests

- (void)setUp
{
    [super setUp];
    _crypto = [CryptoImplV1 sharedInstance];
    _conversationCrypto = [[QredoConversationCrypto alloc] initWithCrypto:_crypto];
}

- (void)testGenerateTestVectors
{
    NSData *myPrivateKeyData
    = [NSData dataWithHexString:@"1c68b754 1878ffff d8a7d9f2 94d90ff6 bf28b9d0 e0a72ef3 7d37d645 4d578d2a"];

    NSData *yourPublicKeyData
    = [NSData dataWithHexString:@"9572dd9c f1ea2d5f de2e4baa 40b2dceb b6735e79 2b4fa374 52b4c8cd ea2a1b0e"];

    QredoDhPrivateKey *myPrivateKey = [[QredoDhPrivateKey alloc] initWithData:myPrivateKeyData];
    QredoDhPublicKey *yourPublicKey = [[QredoDhPublicKey alloc] initWithData:yourPublicKeyData];

    NSLog(@"My private key: %@", myPrivateKeyData);
    NSLog(@"Your public key: %@", yourPublicKeyData);

    NSData *masterKey = [_conversationCrypto conversationMasterKeyWithMyPrivateKey:myPrivateKey
                                                                     yourPublicKey:yourPublicKey];

    NSData *requesterInboundEncryptionKey
    = [_conversationCrypto requesterInboundEncryptionKeyWithMasterKey:masterKey];

    NSData *requesterInboundAuthenticationKey
    = [_conversationCrypto requesterInboundAuthenticationKeyWithMasterKey:masterKey];

    NSData *requesterInboundQueueSeed
    = [_conversationCrypto requesterInboundQueueSeedWithMasterKey:masterKey];

    QredoED25519SigningKey *requesterOwnershipKeyPair
    = [_crypto qredoED25519SigningKeyWithSeed:requesterInboundQueueSeed];


    NSData *responderInboundEncryptionKey
    = [_conversationCrypto responderInboundEncryptionKeyWithMasterKey:masterKey];

    NSData *responderInboundAuthenticationKey
    = [_conversationCrypto responderInboundAuthenticationKeyWithMasterKey:masterKey];

    NSData *responderInboundQueueSeed
    = [_conversationCrypto responderInboundQueueSeedWithMasterKey:masterKey];

    QredoED25519SigningKey *responderOwnershipKeyPair
    = [_crypto qredoED25519SigningKeyWithSeed:responderInboundQueueSeed];


    QredoQUID *conversationId
    = [_conversationCrypto conversationIdWithMasterKey:masterKey];


    NSLog(@"Conversation master key: %@", masterKey);
    NSLog(@"Conversation ID: %@", conversationId);

    NSLog(@"Requester inbound:");
    NSLog(@"Encryption key: %@", requesterInboundEncryptionKey);
    NSLog(@"Authentication key: %@", requesterInboundAuthenticationKey);
    NSLog(@"Queue seed: %@", requesterInboundQueueSeed);

    NSLog(@"Onwership.public: %@", requesterOwnershipKeyPair.verifyKey.data);
    NSLog(@"Onwership.private: %@", requesterOwnershipKeyPair.data);

    NSLog(@"Queue ID: %@", requesterOwnershipKeyPair.verifyKey.data);


    NSLog(@"Responder inbound:");
    NSLog(@"Encryption key: %@", responderInboundEncryptionKey);
    NSLog(@"Authentication key: %@", responderInboundAuthenticationKey);
    NSLog(@"Queue seed: %@", responderInboundQueueSeed);

    NSLog(@"Onwership.public: %@", responderOwnershipKeyPair.verifyKey.data);
    NSLog(@"Onwership.private: %@", responderOwnershipKeyPair.data);

    NSLog(@"Queue ID: %@", responderOwnershipKeyPair.verifyKey.data);
}


- (void)testVectors
{
    NSData *myPrivateKeyData
    = [NSData dataWithHexString:@"1c68b754 1878ffff d8a7d9f2 94d90ff6 bf28b9d0 e0a72ef3 7d37d645 4d578d2a"];

    NSData *yourPublicKeyData
    = [NSData dataWithHexString:@"9572dd9c f1ea2d5f de2e4baa 40b2dceb b6735e79 2b4fa374 52b4c8cd ea2a1b0e"];

    QredoDhPrivateKey *myPrivateKey = [[QredoDhPrivateKey alloc] initWithData:myPrivateKeyData];
    QredoDhPublicKey *yourPublicKey = [[QredoDhPublicKey alloc] initWithData:yourPublicKeyData];

    NSData *masterKey = [_conversationCrypto conversationMasterKeyWithMyPrivateKey:myPrivateKey
                                                                     yourPublicKey:yourPublicKey];

    NSData *requesterInboundEncryptionKey
    = [_conversationCrypto requesterInboundEncryptionKeyWithMasterKey:masterKey];

    NSData *requesterInboundAuthenticationKey
    = [_conversationCrypto requesterInboundAuthenticationKeyWithMasterKey:masterKey];

    NSData *requesterInboundQueueSeed
    = [_conversationCrypto requesterInboundQueueSeedWithMasterKey:masterKey];

    QredoED25519SigningKey *requesterOwnershipKeyPair
    = [_crypto qredoED25519SigningKeyWithSeed:requesterInboundQueueSeed];


    NSData *responderInboundEncryptionKey
    = [_conversationCrypto responderInboundEncryptionKeyWithMasterKey:masterKey];

    NSData *responderInboundAuthenticationKey
    = [_conversationCrypto responderInboundAuthenticationKeyWithMasterKey:masterKey];

    NSData *responderInboundQueueSeed
    = [_conversationCrypto responderInboundQueueSeedWithMasterKey:masterKey];

    QredoED25519SigningKey *responderOwnershipKeyPair
    = [_crypto qredoED25519SigningKeyWithSeed:responderInboundQueueSeed];


    QredoQUID *conversationId
    = [_conversationCrypto conversationIdWithMasterKey:masterKey];


    NSData *requesterInboundEncryptionKeyExpected
    = [NSData dataWithHexString:@"cec5ecb7 e525f907 a0d4bc52 8abd58be 6cfcffba c9976ce5 c635d543 22eb47ad"];
    XCTAssertEqualObjects(requesterInboundEncryptionKey, requesterInboundEncryptionKeyExpected);

    NSData *requesterInboundAuthenticationKeyExpected
    = [NSData dataWithHexString:@"b591febf 55cdc4d0 9ae2a3c3 a89da88a b3516084 54ee2ee8 01cf50df d884e305"];
    XCTAssertEqualObjects(requesterInboundAuthenticationKey, requesterInboundAuthenticationKeyExpected);

    NSData *requesterInboundQueueSeedExpected
    = [NSData dataWithHexString:@"aeb221ad 4d97afc4 8fe77157 8d25e6ce 6faae08a e6732cf9 9e8fded7 234e1429"];
    XCTAssertEqualObjects(requesterInboundQueueSeed, requesterInboundQueueSeedExpected);

    NSData *requesterOwnershipSigningKeyExpected
    = [NSData dataWithHexString:
       @"aeb221ad 4d97afc4 8fe77157 8d25e6ce 6faae08a e6732cf9 9e8fded7 234e1429"
       @"0bdb0e7e 9ce4a729 710af80f 6804274e 154db05a 68129551 aa2c73ef b6cd8947"];
    XCTAssertEqualObjects(requesterOwnershipKeyPair.data, requesterOwnershipSigningKeyExpected);

    NSData *requesterOwnershipVerifyingKeyExpected
    = [NSData dataWithHexString:@"0bdb0e7e 9ce4a729 710af80f 6804274e 154db05a 68129551 aa2c73ef b6cd8947"];
    XCTAssertEqualObjects(requesterOwnershipKeyPair.verifyKey.data, requesterOwnershipVerifyingKeyExpected);

    NSData *responderInboundEncryptionKeyExpected
    = [NSData dataWithHexString:@"c4ac481f 569c7d9b 86c7a893 dd6b1870 32207ec3 0778fe2c 438ca30e de4f249a"];
    XCTAssertEqualObjects(responderInboundEncryptionKey, responderInboundEncryptionKeyExpected);

    NSData *responderInboundAuthenticationKeyExpected
    = [NSData dataWithHexString:@"3171bad3 c3560af1 5d936284 d4fe9f85 b3c61718 11d55e41 f803c2f5 c84c820e"];
    XCTAssertEqualObjects(responderInboundAuthenticationKey, responderInboundAuthenticationKeyExpected);

    NSData *responderInboundQueueSeedExpected
    = [NSData dataWithHexString:@"a144f830 e9a97d70 20422ec1 5021375b f5735f31 289ab9a9 9885fe4c dae06245"];
    XCTAssertEqualObjects(responderInboundQueueSeed, responderInboundQueueSeedExpected);

    NSData *responderOwnershipSigningKeyExpected
    = [NSData dataWithHexString:
       @"a144f830 e9a97d70 20422ec1 5021375b f5735f31 289ab9a9 9885fe4c dae06245"
       @"96d0e8ee 198c1701 a8e5dc0e 2eff4d0d e776b7d8 337d4cf4 6c68b1df 0b27b41f"];
    XCTAssertEqualObjects(responderOwnershipKeyPair.data, responderOwnershipSigningKeyExpected);

    NSData *responderOwnershipVerifyingKeyExpected
    = [NSData dataWithHexString:@"96d0e8ee 198c1701 a8e5dc0e 2eff4d0d e776b7d8 337d4cf4 6c68b1df 0b27b41f"];
    XCTAssertEqualObjects(responderOwnershipKeyPair.verifyKey.data, responderOwnershipVerifyingKeyExpected);

    QredoQUID *conversationIdExpected
    = [[QredoQUID alloc] initWithQUIDString:@"fb4ef86f357624ca56fe8b11d5386e0e118e12e05220f0d5cc71296552f0bf7b"];
    XCTAssertEqualObjects(conversationId, conversationIdExpected);
}

@end
