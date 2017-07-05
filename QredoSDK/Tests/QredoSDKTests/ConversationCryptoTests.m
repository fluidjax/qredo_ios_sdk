/* HEADER GOES HERE */
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoConversationCrypto.h"
#import "CryptoImplV1.h"
#import "QredoXCTestCase.h"
#import "NSData+ParseHex.h"
#import "QredoNetworkTime.h"

@interface ConversationCryptoTests :QredoXCTestCase
{
    QredoConversationCrypto *_conversationCrypto;
    CryptoImplV1 *_crypto;
}

@end

@implementation ConversationCryptoTests

-(void)setUp {
    [super setUp];
    _crypto = [CryptoImplV1 sharedInstance];
    _conversationCrypto = [[QredoConversationCrypto alloc] initWithCrypto:_crypto];
}


-(void)testGenerateTestVectors {
    NSData *myPrivateKeyData
    = [NSData dataWithHexString:@"1c68b754 1878ffff d8a7d9f2 94d90ff6 bf28b9d0 e0a72ef3 7d37d645 4d578d2a"];
    
    NSData *yourPublicKeyData
    = [NSData dataWithHexString:@"9572dd9c f1ea2d5f de2e4baa 40b2dceb b6735e79 2b4fa374 52b4c8cd ea2a1b0e"];
    
    QredoDhPrivateKey *myPrivateKey = [[QredoDhPrivateKey alloc] initWithData:myPrivateKeyData];
    QredoDhPublicKey *yourPublicKey = [[QredoDhPublicKey alloc] initWithData:yourPublicKeyData];
    
    NSData *masterKey = [_conversationCrypto conversationMasterKeyWithMyPrivateKey:myPrivateKey
                                                                     yourPublicKey:yourPublicKey];
    
    [_conversationCrypto requesterInboundEncryptionKeyWithMasterKey:masterKey];
    [_conversationCrypto requesterInboundAuthenticationKeyWithMasterKey:masterKey];
    NSData *requesterInboundQueueSeed = [_conversationCrypto requesterInboundQueueSeedWithMasterKey:masterKey];
    [_crypto qredoED25519SigningKeyWithSeed:requesterInboundQueueSeed];
    [_conversationCrypto responderInboundEncryptionKeyWithMasterKey:masterKey];
    [_conversationCrypto responderInboundAuthenticationKeyWithMasterKey:masterKey];
    NSData *responderInboundQueueSeed = [_conversationCrypto responderInboundQueueSeedWithMasterKey:masterKey];
    [_crypto qredoED25519SigningKeyWithSeed:responderInboundQueueSeed];
    [_conversationCrypto conversationIdWithMasterKey:masterKey];
}


-(void)testVectors {
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
    
    XCTAssertEqualObjects(requesterInboundEncryptionKey,requesterInboundEncryptionKeyExpected);
    
    NSData *requesterInboundAuthenticationKeyExpected
    = [NSData dataWithHexString:@"b591febf 55cdc4d0 9ae2a3c3 a89da88a b3516084 54ee2ee8 01cf50df d884e305"];
    XCTAssertEqualObjects(requesterInboundAuthenticationKey,requesterInboundAuthenticationKeyExpected);
    
    NSData *requesterInboundQueueSeedExpected
    = [NSData dataWithHexString:@"aeb221ad 4d97afc4 8fe77157 8d25e6ce 6faae08a e6732cf9 9e8fded7 234e1429"];
    XCTAssertEqualObjects(requesterInboundQueueSeed,requesterInboundQueueSeedExpected);
    
    NSData *requesterOwnershipSigningKeyExpected
    = [NSData dataWithHexString:
       @"aeb221ad 4d97afc4 8fe77157 8d25e6ce 6faae08a e6732cf9 9e8fded7 234e1429"
       @"0bdb0e7e 9ce4a729 710af80f 6804274e 154db05a 68129551 aa2c73ef b6cd8947"];
    XCTAssertEqualObjects(requesterOwnershipKeyPair.data,requesterOwnershipSigningKeyExpected);
    
    NSData *requesterOwnershipVerifyingKeyExpected
    = [NSData dataWithHexString:@"0bdb0e7e 9ce4a729 710af80f 6804274e 154db05a 68129551 aa2c73ef b6cd8947"];
    XCTAssertEqualObjects(requesterOwnershipKeyPair.verifyKey.data,requesterOwnershipVerifyingKeyExpected);
    
    NSData *responderInboundEncryptionKeyExpected
    = [NSData dataWithHexString:@"c4ac481f 569c7d9b 86c7a893 dd6b1870 32207ec3 0778fe2c 438ca30e de4f249a"];
    XCTAssertEqualObjects(responderInboundEncryptionKey,responderInboundEncryptionKeyExpected);
    
    NSData *responderInboundAuthenticationKeyExpected
    = [NSData dataWithHexString:@"3171bad3 c3560af1 5d936284 d4fe9f85 b3c61718 11d55e41 f803c2f5 c84c820e"];
    XCTAssertEqualObjects(responderInboundAuthenticationKey,responderInboundAuthenticationKeyExpected);
    
    NSData *responderInboundQueueSeedExpected
    = [NSData dataWithHexString:@"a144f830 e9a97d70 20422ec1 5021375b f5735f31 289ab9a9 9885fe4c dae06245"];
    XCTAssertEqualObjects(responderInboundQueueSeed,responderInboundQueueSeedExpected);
    
    NSData *responderOwnershipSigningKeyExpected
    = [NSData dataWithHexString:
       @"a144f830 e9a97d70 20422ec1 5021375b f5735f31 289ab9a9 9885fe4c dae06245"
       @"96d0e8ee 198c1701 a8e5dc0e 2eff4d0d e776b7d8 337d4cf4 6c68b1df 0b27b41f"];
    XCTAssertEqualObjects(responderOwnershipKeyPair.data,responderOwnershipSigningKeyExpected);
    
    NSData *responderOwnershipVerifyingKeyExpected
    = [NSData dataWithHexString:@"96d0e8ee 198c1701 a8e5dc0e 2eff4d0d e776b7d8 337d4cf4 6c68b1df 0b27b41f"];
    XCTAssertEqualObjects(responderOwnershipKeyPair.verifyKey.data,responderOwnershipVerifyingKeyExpected);
    
    QredoQUID *conversationIdExpected
    = [[QredoQUID alloc] initWithQUIDString:@"fb4ef86f357624ca56fe8b11d5386e0e118e12e05220f0d5cc71296552f0bf7b"];
    XCTAssertEqualObjects(conversationId,conversationIdExpected);
}


-(void)testEncryptDecrypt {
    QredoQUID *messageID  = [[QredoQUID alloc] initWithQUIDString:@"a774a903a9a7481a818fb2afae4aa5beb935120f29c0454681319964f129447a"];
    
    NSDate *created = [QredoNetworkTime dateTime];
    QredoUTCDateTime *createdDate = [[QredoUTCDateTime alloc] initWithDate:created];
    
    QLFConversationMessageMetadata *metadata     = [QLFConversationMessageMetadata conversationMessageMetadataWithID:messageID
                                                                                                            parentId:[NSSet set]
                                                                                                            sequence:nil
                                                                                                            sentByMe:true
                                                                                                             created:createdDate
                                                                                                            dataType:@"blob"
                                                                                                              values:[NSSet set]];
    
    NSString *messageBodyString = @"Message value";
    NSData *messageBody = [messageBodyString dataUsingEncoding:NSUTF8StringEncoding];
    QLFConversationMessage *clearMessage = [QLFConversationMessage conversationMessageWithMetadata:metadata
                                                                                              body:messageBody];
    
    NSData *requesterInboundEncryptionKey      = [NSData dataWithHexString:@"cec5ecb7 e525f907 a0d4bc52 8abd58be 6cfcffba c9976ce5 c635d543 22eb47ad"];
    
    NSData *requesterInboundAuthenticationKey  = [NSData dataWithHexString:@"b591febf 55cdc4d0 9ae2a3c3 a89da88a b3516084 54ee2ee8 01cf50df d884e305"];
    
    QLFEncryptedConversationItem *encryptedMessage = [_conversationCrypto encryptMessage:clearMessage
                                                                                   bulkKey:requesterInboundEncryptionKey
                                                                                   authKey:requesterInboundAuthenticationKey];
    
    [QredoPrimitiveMarshallers marshalObject:clearMessage includeHeader:NO];
    [QredoPrimitiveMarshallers marshalObject:encryptedMessage includeHeader:NO];
    
    XCTAssertNotNil(encryptedMessage);
    XCTAssertNotNil(encryptedMessage.authCode);
    
    NSError *error = nil;
    QLFConversationMessage *decryptedMessage   = [_conversationCrypto decryptMessage:encryptedMessage
                                                                             bulkKey:requesterInboundEncryptionKey
                                                                             authKey:requesterInboundAuthenticationKey
                                                                               error:&error];
    
    XCTAssertNotNil(decryptedMessage);
    XCTAssertNil(error);
    
    XCTAssertEqualObjects(decryptedMessage.body,clearMessage.body);
    
    XCTAssertNotNil(decryptedMessage.metadata);
    XCTAssertEqualObjects(decryptedMessage.metadata.dataType,clearMessage.metadata.dataType);
    
    
    //Wrong encryption key
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
    
    
    //Wrong authentication code
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
    
    
    //Malformed encrypted data
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


//-(void)testDecrypt {
//    NSData *requesterInboundEncryptionKey
//    = [NSData dataWithHexString:@"cec5ecb7 e525f907 a0d4bc52 8abd58be 6cfcffba c9976ce5 c635d543 22eb47ad"];
//    
//    NSData *requesterInboundAuthenticationKey
//    = [NSData dataWithHexString:@"b591febf 55cdc4d0 9ae2a3c3 a89da88a b3516084 54ee2ee8 01cf50df d884e305"];
//    
//    NSData *serializedEncryptedMessage
//    = [NSData dataWithHexString:
//       @"28313a43 32363a27 456e6372 79707465 64436f6e 76657273 6174696f 6e497465 6d28393a 27617574 68436f64"
//       @"6533333a 622163d3 2af2c6e4 8faa5d17 a82ecac9 9a49774d 80fb76f0 1621d259 d7f57b62 b1292831 373a2765"
//       @"6e637279 70746564 4d657373 61676533 33303a62 28373a62 00000002 0000373a 62000000 02000033 30353a62"
//       @"bc38b889 fa0c1552 d9410fb3 61a8f4b5 ccfadf92 3a1cfa24 18403212 8f2f182f 5220aafd 68dfc986 97c13b5f"
//       @"ba978562 020a37df cdc18fb5 b4de6ca4 61e5d742 eaa85ba1 a8b18a35 e302a9be 82bd59c4 b9eda3f4 66263475"
//       @"b9a5f759 5355e1a5 d5060ca8 4bf4399c 549e1fc4 d0a20193 4b995a5e 152a10a8 7c39521e 9b182777 7e958251"
//       @"e3f89eca 45d8d5dd 3def194d 57f267e0 d84851c3 6ebde159 bb934a80 d4ea3eff 24a67092 f18151c0 e3df1e86"
//       @"9413e4f0 fb2c2b11 a4e89cce b9aefde3 64927d9f 799232e1 57145c7a b9e27326 a15c8fbe 7f57d7d8 8241ba82"
//       @"96587b27 ebd7be7b 78f77c09 1b080f1e d0786349 e87ebb64 be0707f3 2826f0dd ad05e395 7971241a b392a95c"
//       @"b7fd3bf7 b4349ed7 24c89e27 cacf0967 01103fda 47e04874 c1fb6889 a0f24b64 dab7f779 745dfd61 292929"];
//    
//    QLFEncryptedConversationItem *encryptedMessage = [QredoPrimitiveMarshallers unmarshalObject:serializedEncryptedMessage
//                                                                                   unmarshaller:[QLFEncryptedConversationItem unmarshaller]
//                                                                                    parseHeader:NO];
//    
//    NSError *error = nil;
//    QLFConversationMessage *message  = [_conversationCrypto decryptMessage:encryptedMessage
//                                                                   bulkKey:requesterInboundEncryptionKey
//                                                                   authKey:requesterInboundAuthenticationKey
//                                                                     error:&error];
//    
//    XCTAssertNotNil(message);
//    XCTAssertNil(error);
//    
//    NSString *messageBodyString = @"Message value";
//    NSData *messageBodyExpected = [messageBodyString dataUsingEncoding:NSUTF8StringEncoding];
//    XCTAssertEqualObjects(message.body,messageBodyExpected);
//}
//

@end
