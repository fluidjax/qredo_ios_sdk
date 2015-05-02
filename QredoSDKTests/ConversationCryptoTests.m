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

- (void)testEncryptDecrypt
{
    QredoQUID *messageID
    = [[QredoQUID alloc] initWithQUIDString:@"a774a903a9a7481a818fb2afae4aa5beb935120f29c0454681319964f129447a"];

    QLFConversationMessageMetadata *metadata
    = [QLFConversationMessageMetadata conversationMessageMetadataWithID:messageID
                                                               parentId:[NSSet set]
                                                               sequence:nil
                                                               dataType:@"blob"
                                                                 values:[NSSet set]];

    NSString *messageBodyString = @"Message value";
    NSData *messageBody = [messageBodyString dataUsingEncoding:NSUTF8StringEncoding];
    QLFConversationMessage *clearMessage = [QLFConversationMessage conversationMessageWithMetadata:metadata
                                                                                              body:messageBody];

    NSData *requesterInboundEncryptionKey
    = [NSData dataWithHexString:@"cec5ecb7 e525f907 a0d4bc52 8abd58be 6cfcffba c9976ce5 c635d543 22eb47ad"];

    NSData *requesterInboundAuthenticationKey
    = [NSData dataWithHexString:@"b591febf 55cdc4d0 9ae2a3c3 a89da88a b3516084 54ee2ee8 01cf50df d884e305"];

    NSLog(@"Message id: %@", messageID);
    NSLog(@"Message body: \"%@\"", messageBodyString);
    NSLog(@"Encryption key: %@", requesterInboundEncryptionKey);
    NSLog(@"Authentication key: %@", requesterInboundAuthenticationKey);

    QLFEncryptedConversationItem *encryptedMessage
    = [_conversationCrypto encryptMessage:clearMessage
                                  bulkKey:requesterInboundEncryptionKey
                                  authKey:requesterInboundAuthenticationKey];

    NSData *serializedMessage = [QredoPrimitiveMarshallers marshalObject:clearMessage includeHeader:NO];
    NSLog(@"message: %@", serializedMessage);
    NSData *serializedEncryptedMessage = [QredoPrimitiveMarshallers marshalObject:encryptedMessage includeHeader:NO];
    NSLog(@"encryptedMessage: %@", serializedEncryptedMessage);
    NSLog(@"authCode: %@", encryptedMessage.authCode);

    XCTAssertNotNil(encryptedMessage);
    XCTAssertNotNil(encryptedMessage.authCode);

    NSError *error = nil;
    QLFConversationMessage *decryptedMessage
    = [_conversationCrypto decryptMessage:encryptedMessage
                                  bulkKey:requesterInboundEncryptionKey
                                  authKey:requesterInboundAuthenticationKey
                                    error:&error];

    XCTAssertNotNil(decryptedMessage);
    XCTAssertNil(error);

    XCTAssertEqualObjects(decryptedMessage.body, clearMessage.body);

    XCTAssertNotNil(decryptedMessage.metadata);
    XCTAssertEqualObjects(decryptedMessage.metadata.dataType, clearMessage.metadata.dataType);


    // Wrong encryption key
    NSData *wrongEncryptionKey
    = [NSData dataWithHexString:@"cec5ecb7 e525f907 a0d4bc52 8abd58be 6cfcffba c9976ce5 c635d543 22eb47dd"];

    error = nil;
    decryptedMessage = [_conversationCrypto decryptMessage:encryptedMessage
                                                   bulkKey:wrongEncryptionKey
                                                   authKey:requesterInboundAuthenticationKey
                                                     error:&error];
    XCTAssertNil(decryptedMessage);
    XCTAssertNotNil(error);

    decryptedMessage = [_conversationCrypto decryptMessage:encryptedMessage
                                                   bulkKey:wrongEncryptionKey
                                                   authKey:requesterInboundAuthenticationKey
                                                     error:nil];
    XCTAssertNil(decryptedMessage);


    // Wrong authentication code
    NSData *wrongAuthCode
    = [NSData dataWithHexString:@"2448b16f f0c07331 7438b5c9 95f16967 0368bacb af74248b 6f7010aa f9f7ee88"];


    QLFEncryptedConversationItem *encryptedMessageWithWrongAuthCode
    = [QLFEncryptedConversationItem encryptedConversationItemWithEncryptedMessage:encryptedMessage.encryptedMessage
                                                                         authCode:wrongAuthCode];

    error = nil;
    decryptedMessage = [_conversationCrypto decryptMessage:encryptedMessageWithWrongAuthCode
                                                   bulkKey:requesterInboundEncryptionKey
                                                   authKey:requesterInboundAuthenticationKey
                                                     error:&error];
    XCTAssertNil(decryptedMessage);
    XCTAssertNotNil(error);


    decryptedMessage = [_conversationCrypto decryptMessage:encryptedMessageWithWrongAuthCode
                                                   bulkKey:requesterInboundEncryptionKey
                                                   authKey:requesterInboundAuthenticationKey
                                                     error:nil];
    XCTAssertNil(decryptedMessage);


    // Malformed encrypted data
    NSData *malformedEncryptedData = [@"jibber jabber" dataUsingEncoding:NSUTF8StringEncoding];
    QLFEncryptedConversationItem *malformedEncryptedMessage
    = [QLFEncryptedConversationItem encryptedConversationItemWithEncryptedMessage:malformedEncryptedData
                                                                         authCode:encryptedMessage.authCode];

    error = nil;
    decryptedMessage = [_conversationCrypto decryptMessage:malformedEncryptedMessage
                                                   bulkKey:requesterInboundEncryptionKey
                                                   authKey:requesterInboundAuthenticationKey
                                                     error:&error];
    XCTAssertNil(decryptedMessage);
    XCTAssertNotNil(error);

    decryptedMessage = [_conversationCrypto decryptMessage:malformedEncryptedMessage
                                                   bulkKey:requesterInboundEncryptionKey
                                                   authKey:requesterInboundAuthenticationKey
                                                     error:nil];
    XCTAssertNil(decryptedMessage);
}

- (void)testDecrypt
{
    NSData *requesterInboundEncryptionKey
    = [NSData dataWithHexString:@"cec5ecb7 e525f907 a0d4bc52 8abd58be 6cfcffba c9976ce5 c635d543 22eb47ad"];

    NSData *requesterInboundAuthenticationKey
    = [NSData dataWithHexString:@"b591febf 55cdc4d0 9ae2a3c3 a89da88a b3516084 54ee2ee8 01cf50df d884e305"];

    NSData *serializedEncryptedMessage
    = [NSData dataWithHexString:
       @"28313a43 32363a27 456e6372 79707465 64436f6e 76657273 6174696f 6e497465 6d28393a 27617574 68436f64"
       @"6533333a 622448b1 6ff0c073 317438b5 c995f169 670368ba cbaf7424 8b6f7010 aaf9f7ee 83292831 373a2765"
       @"6e637279 70746564 4d657373 61676532 38323a62 28373a62 00000002 0000373a 62000000 02000032 35373a62"
       @"b7d832f8 75a9b00b 8c2bb311 3b463cc6 6b9b1fa2 ab908856 5c5be2e7 8e17aeb7 e054f2d6 1c1c15e6 ec04b6fd"
       @"a8ab90c9 8f2413e9 52a5db0b 2413a69e 064fde5f 9b2c29b9 d5c65cf2 9d674351 0acc948d 96491537 b3b35b8f"
       @"381f1297 7dbf303b 50032a3f 93cb88a9 d76f6a08 8e8e7f9a 9c58f480 6e29e4ab 666cd48a 6e20c165 7fdbe658"
       @"d5eb8859 14bcce2e c428bcec 900c7ea9 16a069f5 084cc68f 2e981936 9bf0052c a408ae3e a5a2c04b a2c02e2d"
       @"f6352dce 51a6f581 cb3c0f6f 1a538106 22e12178 a25dbf3e 1a80a545 44206c62 0db4bbbd d5f34716 39a75e80"
       @"c40b277f 620e3088 c001089c ee04cc90 8c95c8af 0e495b32 325e89bf 49582b4b 7d1c2eea 292929"];
    QLFEncryptedConversationItem *encryptedMessage
    = [QredoPrimitiveMarshallers unmarshalObject:serializedEncryptedMessage
                                    unmarshaller:[QLFEncryptedConversationItem unmarshaller]
                                     parseHeader:NO];

    NSError *error = nil;
    QLFConversationMessage *message
    = [_conversationCrypto decryptMessage:encryptedMessage
                                  bulkKey:requesterInboundEncryptionKey
                                  authKey:requesterInboundAuthenticationKey
                                    error:&error];
    XCTAssertNotNil(message);
    XCTAssertNil(error);

    NSString *messageBodyString = @"Message value";
    NSData *messageBodyExpected = [messageBodyString dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(message.body, messageBodyExpected);
}

@end
