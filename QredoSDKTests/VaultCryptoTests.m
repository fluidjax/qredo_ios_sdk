/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "QredoVaultCrypto.h"
#import "QredoVaultPrivate.h"
#import "NSData+QredoRandomData.h"
#import "NSDictionary+IndexableSet.h"
#import "NSData+ParseHex.h"

@interface VaultCryptoTests : XCTestCase

@end

@implementation VaultCryptoTests

- (void)generateVaultKeysWithVaultInfo:(NSString *)vaultInfo userMasterKey:(NSData *)userMasterKey
{
    NSData *vaultKey = [QredoVaultCrypto vaultKeyWithVaultMasterKey:userMasterKey info:vaultInfo];

    QredoED25519SigningKey *ownershipKeyPair = [QredoVaultCrypto ownershipSigningKeyWithVaultKey:vaultKey];
    QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKey:vaultKey];
    QredoQUID *vaultID = [[QredoQUID alloc] initWithQUIDData:ownershipKeyPair.verifyKey.data];

    NSLog(@"%@:", vaultInfo);
    NSLog(@" vaultKey          = %@", vaultKey);
    NSLog(@" vaultID           = %@", vaultID);
    NSLog(@" ownership.public  = %@", ownershipKeyPair.verifyKey.data);
    NSLog(@" ownership.private = %@", ownershipKeyPair.data);
    NSLog(@" encyrptionKey     = %@", encryptionAndAuthKeys.encryptionKey);
    NSLog(@" authentication    = %@", encryptionAndAuthKeys.authenticationKey);


//    QredoQUID *sequenceID = [QredoQUID QUID];
//    QredoQUID *itemID = [QredoQUID QUID];
    QredoQUID *sequenceID = [[QredoQUID alloc] initWithQUIDString:@"536153cde3e743a5b34c5dac49281e261a3acccacb314473bc143ee24f87c0a9"];
    QredoQUID *itemID = [[QredoQUID alloc] initWithQUIDString:@"96b9a6c3a366401f9e42e006c61689ae5c29c4a2835d4e4d992c98eb56cddfd1"];

    int64_t sequenceValue = 1;
    QLFVaultItemRef *vaultItemRef = [QLFVaultItemRef vaultItemRefWithVaultId:vaultID
                                                                  sequenceId:sequenceID
                                                               sequenceValue:sequenceValue
                                                                      itemId:itemID];
    XCTAssertNotNil(vaultItemRef);

    NSString *dataType = @"com.qredo.plaintext";

    NSDate *valueDate = [NSDate dateWithTimeIntervalSince1970:1234567];
    QredoQUID *valueQUID = [QredoQUID QUIDByHashingData:[@"hello" dataUsingEncoding:NSUTF8StringEncoding]];

    NSDictionary *metadataValues = @{@"key_string" : @"value 1",
                                     @"key_bool": @YES,
                                     @"key_int": @12,
                                     @"key_quid": valueQUID,
                                     @"key_date": valueDate};

    NSSet *indexableValues = [metadataValues indexableSet];
    QLFVaultItemMetadata *metadata = [QLFVaultItemMetadata vaultItemMetadataWithDataType:dataType
                                                                                  values:indexableValues];

    NSData *serializedMetadata = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:NO];

    NSLog(@" sequenceID        = %@ (random)", sequenceID);
    NSLog(@" itemID            = %@ (random)", itemID);
    NSLog(@" dataType          = \"%@\"", dataType);
    NSLog(@" metadata.values   = %@", metadataValues);

    NSLog(@" metadata          = %@", serializedMetadata);

    QredoVaultCrypto *vaultCrypto
    = [QredoVaultCrypto vaultCryptoWithBulkKey:encryptionAndAuthKeys.encryptionKey
                             authenticationKey:encryptionAndAuthKeys.authenticationKey];

    QLFEncryptedVaultItemHeader *encryptedVaultItemHeader
    = [vaultCrypto encryptVaultItemHeaderWithItemRef:vaultItemRef metadata:metadata];

    NSData *serializedEncryptedVaultItemHeader
    = [QredoPrimitiveMarshallers marshalObject:encryptedVaultItemHeader includeHeader:NO];

    NSData *encryptedMetadataRaw
    = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItemHeader.encryptedMetadata
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];

    NSRange ivRange = NSMakeRange(0, 16);
    NSLog(@" encyptedMetadata IV = %@", [encryptedMetadataRaw subdataWithRange:ivRange]);
    NSLog(@" message(encryptedMetadata) = %@", encryptedVaultItemHeader.encryptedMetadata);
    NSLog(@" header.authCode     = %@", encryptedVaultItemHeader.authCode);
    NSLog(@" encryptedVaultItemHeader = %@", serializedEncryptedVaultItemHeader);

    NSString *vaultItemBodyString = @"vault item body";
    NSData *vaultItemBody = [vaultItemBodyString dataUsingEncoding:NSUTF8StringEncoding];

    NSLog(@" vaultItemBody (string) = \"%@\"", vaultItemBodyString);
    NSLog(@" vaultItemBody (data)   = %@", vaultItemBody);

    QLFEncryptedVaultItem *encryptedVaultItem
    = [vaultCrypto encryptVaultItemWithBody:vaultItemBody encryptedVaultItemHeader:encryptedVaultItemHeader];

    NSData *encryptedBodyRaw
    = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItem.encryptedBody
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];


    NSLog(@" encryptedBody IV  = %@", [encryptedBodyRaw subdataWithRange:ivRange]);
    NSLog(@" message(encryptedBody) = %@", encryptedVaultItem.encryptedBody);
    NSLog(@" item.authCode     = %@", encryptedVaultItem.authCode);

    NSLog(@" item.ref          = %@", [QredoPrimitiveMarshallers marshalObject:vaultItemRef includeHeader:NO]);
    NSLog(@" encryptedVaultItemHeader = %@", [QredoPrimitiveMarshallers marshalObject:encryptedVaultItemHeader includeHeader:NO]);
    NSLog(@" encryptedVaultItem = %@", [QredoPrimitiveMarshallers marshalObject:encryptedVaultItem includeHeader:NO]);
}

- (void)testGenerateVaultTestVectors
{
//    NSData *userMasterKey = [NSData dataWithRandomBytesOfLength:32];
    NSData *userMasterKey
    = [NSData dataWithHexString:@"86ca9c96 7e591207 02b27f02 801e6782 69fc5d40 301ed86f 03c5d6ef 7f660d66"];

    NSLog(@"User master key    = %@", userMasterKey);

    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:userMasterKey];
    NSLog(@"Vault master key   = %@", vaultMasterKey);

    [self generateVaultKeysWithVaultInfo:@"System Vault" userMasterKey:vaultMasterKey];
    [self generateVaultKeysWithVaultInfo:@"User Vault" userMasterKey:vaultMasterKey];

    XCTAssertNotNil(userMasterKey);
}

- (void)testVaultKeysTestVectors
{
    NSData *userMasterKey
    = [NSData dataWithHexString:@"86ca9c96 7e591207 02b27f02 801e6782 69fc5d40 301ed86f 03c5d6ef 7f660d66"];

    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:userMasterKey];

    NSData *vaultMasterKeyExpected
    = [NSData dataWithHexString:@"35eb9b03 4ceffd10 2778457c 04c6fc24 ea50f845 10173fa5 479184c4 9eff52d5"];
    XCTAssertEqualObjects(vaultMasterKey, vaultMasterKeyExpected);

    // System vault
    NSData *vaultKey = [QredoVaultCrypto systemVaultKeyWithVaultMasterKey:vaultMasterKey];
    NSData *vaultKeyExpected
    = [NSData dataWithHexString:@"b63d366a 815fc76d 8268aaa3 4e607e86 c2e964bd 9c445310 3ee696a5 e82b08de"];

    XCTAssertEqualObjects(vaultKey, vaultKeyExpected);

    QredoED25519SigningKey *ownershipKeyPair = [QredoVaultCrypto ownershipSigningKeyWithVaultKey:vaultKey];
    NSData *signingKeyExpected
    = [NSData dataWithHexString:
       @"b63d366a 815fc76d 8268aaa3 4e607e86 c2e964bd 9c445310 3ee696a5 e82b08de 24c6e666 40a6eb44 b7e1eaf6"
       @"d93bb0b3 32ce45cb f0d1a0f8 e1b9d8f2 ffb8ea20"];

    NSData *verifyingKeyExpected
    = [NSData dataWithHexString:@"24c6e666 40a6eb44 b7e1eaf6 d93bb0b3 32ce45cb f0d1a0f8 e1b9d8f2 ffb8ea20"];

    XCTAssertEqualObjects(ownershipKeyPair.data, signingKeyExpected);
    XCTAssertEqualObjects(ownershipKeyPair.verifyKey.data, verifyingKeyExpected);


    QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKey:vaultKey];
    NSData *encryptionKeyExpected
    = [NSData dataWithHexString:@"cb5e8fc6 0596ebf3 99d01185 45e99425 8567cdbd 82fa8f09 7a5260d1 945ba30c"];

    NSData *authenticationKeyExpected
    = [NSData dataWithHexString:@"7eca67be 841c1f08 e828a0be abdcb160 08cb8752 f2bc34e3 578e3117 2793c820"];

    XCTAssertEqualObjects(encryptionAndAuthKeys.encryptionKey, encryptionKeyExpected);
    XCTAssertEqualObjects(encryptionAndAuthKeys.authenticationKey, authenticationKeyExpected);
}

- (void)testHeaderDecryption
{
    NSData *encryptionKeyExpected
    = [NSData dataWithHexString:@"cb5e8fc6 0596ebf3 99d01185 45e99425 8567cdbd 82fa8f09 7a5260d1 945ba30c"];

    NSData *authenticationKeyExpected
    = [NSData dataWithHexString:@"7eca67be 841c1f08 e828a0be abdcb160 08cb8752 f2bc34e3 578e3117 2793c820"];

    QredoVaultCrypto *vaultCrypto = [[QredoVaultCrypto alloc] initWithBulkKey:encryptionKeyExpected
                                                            authenticationKey:authenticationKeyExpected];


    QredoQUID *vaultId
    = [[QredoQUID alloc] initWithQUIDString:@"24c6e66640a6eb44b7e1eaf6d93bb0b332ce45cbf0d1a0f8e1b9d8f2ffb8ea20"];

    QredoQUID *sequenceId
    = [[QredoQUID alloc] initWithQUIDString:@"536153cde3e743a5b34c5dac49281e261a3acccacb314473bc143ee24f87c0a9"];

    QredoQUID *itemId
    = [[QredoQUID alloc] initWithQUIDString:@"96b9a6c3a366401f9e42e006c61689ae5c29c4a2835d4e4d992c98eb56cddfd1"];

    int64_t sequenceValue = 1;
    QLFVaultItemRef *vaultItemRef = [QLFVaultItemRef vaultItemRefWithVaultId:vaultId
                                                                  sequenceId:sequenceId
                                                               sequenceValue:sequenceValue
                                                                      itemId:itemId];

    NSData *encryptedMetadataData
    = [NSData dataWithHexString:
       @"28373a62 00000002 0000373a 62000000 01000035 31333a62 c774033c 9c481aae 3bf2987f c304675b dec98cf5"
       @"10f2200c 89ce7c31 81e9903e 59d12dd5 f81ae48e 9ccfac8a 0213b83e cab3fa93 5c896704 d24a4416 519a22f5"
       @"79af6a7c d9219c05 c0250578 8fdf580c e5b939f4 b431a5de 5cd2aec7 6f447959 26c353e1 43b2b28d 92e3e37e"
       @"59de1e59 3991629f 6cfc1cbc df5bc158 cce2b704 5c4ebd91 d13aea2d 20257aae 2752ea35 7c71ef2d 6fce791a"
       @"e45bb660 8a55802e 9b791aa7 79459572 572fb161 533be334 7ce0b0ec bfe849c9 76cb18cc 35e23e12 f47cd7b8"
       @"c7ce750a 5354fd28 b21fba49 2d107cef 4e481efe 3f92cef7 af5e8bb8 32426a2a 4fc18380 6415a54e 569dcf93"
       @"e93712a6 5f1140f2 f92d345b 217cf18b 9a6f7f30 e07af193 85ae7aaa 9518d837 6bca8b47 021039a3 2a902bd4"
       @"41c69eb8 c38076ff bb2fba5c 7c408c5d 4eebb165 d11a24ff d38465a4 454a21f3 d610f855 d9ad2116 12e72f40"
       @"3344ce97 76d0bb9a 6b6f950e 6f9cd494 1ba35613 918a62c6 3d9260fa 9181843c 25b4a4cc 7fef968d 2137d229"
       @"9f09869e b88ea85d a10dc000 f37aa68f 7572c497 24b50daf c645b4eb fb749355 dbfe70ac 83276c6f 84e7addd"
       @"e15d7762 5ce7b781 7aa62925 bcce4f98 1972d213 69ab6957 f7e63de3 59891fe8 faf1ff2c 622648c7 aee08c25"
       @"b5948d2b 6fb8c98d f29a1b54 bba8122b 9775a4e1 eb8acf03 58bd7726 df3d502d 04fe2a26 68a1f571 1bb1e8e8"
       @"90a9348b 0643743c 29"];

    NSData *encryptedVaultItemHeaderData
    = [NSData dataWithHexString:
       @"28313a43 32353a27 456e6372 79707465 64566175 6c744974 656d4865 61646572 28393a27 61757468 436f6465"
       @"33333a62 752531e7 232d517a 363cc5a5 d01347f6 9c7b34d2 1e6c7dcb 36df68ec 04303851 29283138 3a27656e"
       @"63727970 7465644d 65746164 61746135 33383a62 28373a62 00000002 0000373a 62000000 01000035 31333a62"
       @"c774033c 9c481aae 3bf2987f c304675b dec98cf5 10f2200c 89ce7c31 81e9903e 59d12dd5 f81ae48e 9ccfac8a"
       @"0213b83e cab3fa93 5c896704 d24a4416 519a22f5 79af6a7c d9219c05 c0250578 8fdf580c e5b939f4 b431a5de"
       @"5cd2aec7 6f447959 26c353e1 43b2b28d 92e3e37e 59de1e59 3991629f 6cfc1cbc df5bc158 cce2b704 5c4ebd91"
       @"d13aea2d 20257aae 2752ea35 7c71ef2d 6fce791a e45bb660 8a55802e 9b791aa7 79459572 572fb161 533be334"
       @"7ce0b0ec bfe849c9 76cb18cc 35e23e12 f47cd7b8 c7ce750a 5354fd28 b21fba49 2d107cef 4e481efe 3f92cef7"
       @"af5e8bb8 32426a2a 4fc18380 6415a54e 569dcf93 e93712a6 5f1140f2 f92d345b 217cf18b 9a6f7f30 e07af193"
       @"85ae7aaa 9518d837 6bca8b47 021039a3 2a902bd4 41c69eb8 c38076ff bb2fba5c 7c408c5d 4eebb165 d11a24ff"
       @"d38465a4 454a21f3 d610f855 d9ad2116 12e72f40 3344ce97 76d0bb9a 6b6f950e 6f9cd494 1ba35613 918a62c6"
       @"3d9260fa 9181843c 25b4a4cc 7fef968d 2137d229 9f09869e b88ea85d a10dc000 f37aa68f 7572c497 24b50daf"
       @"c645b4eb fb749355 dbfe70ac 83276c6f 84e7addd e15d7762 5ce7b781 7aa62925 bcce4f98 1972d213 69ab6957"
       @"f7e63de3 59891fe8 faf1ff2c 622648c7 aee08c25 b5948d2b 6fb8c98d f29a1b54 bba8122b 9775a4e1 eb8acf03"
       @"58bd7726 df3d502d 04fe2a26 68a1f571 1bb1e8e8 90a9348b 0643743c 29292834 3a277265 6628313a 4331333a"
       @"27566175 6c744974 656d5265 6628373a 27697465 6d496433 333a5196 b9a6c3a3 66401f9e 42e006c6 1689ae5c"
       @"29c4a283 5d4e4d99 2c98eb56 cddfd129 2831313a 27736571 75656e63 65496433 333a5153 6153cde3 e743a5b3"
       @"4c5dac49 281e261a 3acccacb 314473bc 143ee24f 87c0a929 2831343a 27736571 75656e63 6556616c 7565393a"
       @"49000000 00000000 01292838 3a277661 756c7449 6433333a 5124c6e6 6640a6eb 44b7e1ea f6d93bb0 b332ce45"
       @"cbf0d1a0 f8e1b9d8 f2ffb8ea 20292929 29"];

    NSData *authCodeData
    = [NSData dataWithHexString:@"752531e7 232d517a 363cc5a5 d01347f6 9c7b34d2 1e6c7dcb 36df68ec 04303851"];

    QLFEncryptedVaultItemHeader *encryptedVaultItemHeaderParsed
    = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItemHeaderData
                                    unmarshaller:[QLFEncryptedVaultItemHeader unmarshaller]
                                     parseHeader:NO];

    QLFEncryptedVaultItemHeader *encryptedVaultItemHeader
    = [QLFEncryptedVaultItemHeader encryptedVaultItemHeaderWithRef:vaultItemRef
                                                 encryptedMetadata:encryptedMetadataData
                                                          authCode:authCodeData];

    XCTAssertEqualObjects(encryptedVaultItemHeader.encryptedMetadata, encryptedVaultItemHeaderParsed.encryptedMetadata);
    XCTAssertTrue([encryptedVaultItemHeader.ref isEqualToVaultItemRef:encryptedVaultItemHeaderParsed.ref]);
    XCTAssertEqualObjects(encryptedVaultItemHeader.ref.vaultId, encryptedVaultItemHeaderParsed.ref.vaultId);
    XCTAssertEqualObjects(encryptedVaultItemHeader.ref.sequenceId, encryptedVaultItemHeaderParsed.ref.sequenceId);
    XCTAssertEqual(encryptedVaultItemHeader.ref.sequenceValue, encryptedVaultItemHeaderParsed.ref.sequenceValue);

    NSError *error = nil;
    QLFVaultItemMetadata *metadata =
    [vaultCrypto decryptEncryptedVaultItemHeader:encryptedVaultItemHeader error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(metadata);

    NSString *dataTypeExpected = @"com.qredo.plaintext";


    XCTAssertEqualObjects(metadata.dataType, dataTypeExpected);
    XCTAssertEqual(metadata.values.count, 5);

    // Verify auth code
    NSData *wrongAuthCodeData
    = [NSData dataWithHexString:@"aa206a01 a2260a1c 1083bb41 3ed5a1ec d79ccdac b497db3f b6d1081b 646231aa"];

    QLFEncryptedVaultItemHeader *encryptedVaultItemHeaderWithWrongAuthCode
    = [QLFEncryptedVaultItemHeader encryptedVaultItemHeaderWithRef:vaultItemRef
                                                 encryptedMetadata:encryptedMetadataData
                                                          authCode:wrongAuthCodeData];
    QLFVaultItemMetadata *metadataWithWrongAuthCode =
    [vaultCrypto decryptEncryptedVaultItemHeader:encryptedVaultItemHeaderWithWrongAuthCode error:&error];

    XCTAssertNil(metadataWithWrongAuthCode);
    XCTAssertNotNil(error);

}

- (void)testItemDecryption
{
    NSData *encryptionKeyExpected
    = [NSData dataWithHexString:@"cb5e8fc6 0596ebf3 99d01185 45e99425 8567cdbd 82fa8f09 7a5260d1 945ba30c"];

    NSData *authenticationKeyExpected
    = [NSData dataWithHexString:@"7eca67be 841c1f08 e828a0be abdcb160 08cb8752 f2bc34e3 578e3117 2793c820"];

    QredoVaultCrypto *vaultCrypto = [[QredoVaultCrypto alloc] initWithBulkKey:encryptionKeyExpected
                                                            authenticationKey:authenticationKeyExpected];

    NSData *encryptedItemData
    = [NSData dataWithHexString:
       @"28313a43 31393a27 456e6372 79707465 64566175 6c744974 656d2839 3a276175 7468436f 64653333 3a623722"
       @"b30e3180 f532fd73 64b0decd 7120405d a5e14c2a 86f8fd84 8d9af068 3f792928 31343a27 656e6372 79707465"
       @"64426f64 7935373a 6228373a 62000000 02000037 3a620000 00010000 33333a62 aa8eee91 b851abfd 88dffe56"
       @"ef1c4734 a8696881 a529d3bc df9416d2 e969662f 29292837 3a276865 61646572 28313a43 32353a27 456e6372"
       @"79707465 64566175 6c744974 656d4865 61646572 28393a27 61757468 436f6465 33333a62 752531e7 232d517a"
       @"363cc5a5 d01347f6 9c7b34d2 1e6c7dcb 36df68ec 04303851 29283138 3a27656e 63727970 7465644d 65746164"
       @"61746135 33383a62 28373a62 00000002 0000373a 62000000 01000035 31333a62 c774033c 9c481aae 3bf2987f"
       @"c304675b dec98cf5 10f2200c 89ce7c31 81e9903e 59d12dd5 f81ae48e 9ccfac8a 0213b83e cab3fa93 5c896704"
       @"d24a4416 519a22f5 79af6a7c d9219c05 c0250578 8fdf580c e5b939f4 b431a5de 5cd2aec7 6f447959 26c353e1"
       @"43b2b28d 92e3e37e 59de1e59 3991629f 6cfc1cbc df5bc158 cce2b704 5c4ebd91 d13aea2d 20257aae 2752ea35"
       @"7c71ef2d 6fce791a e45bb660 8a55802e 9b791aa7 79459572 572fb161 533be334 7ce0b0ec bfe849c9 76cb18cc"
       @"35e23e12 f47cd7b8 c7ce750a 5354fd28 b21fba49 2d107cef 4e481efe 3f92cef7 af5e8bb8 32426a2a 4fc18380"
       @"6415a54e 569dcf93 e93712a6 5f1140f2 f92d345b 217cf18b 9a6f7f30 e07af193 85ae7aaa 9518d837 6bca8b47"
       @"021039a3 2a902bd4 41c69eb8 c38076ff bb2fba5c 7c408c5d 4eebb165 d11a24ff d38465a4 454a21f3 d610f855"
       @"d9ad2116 12e72f40 3344ce97 76d0bb9a 6b6f950e 6f9cd494 1ba35613 918a62c6 3d9260fa 9181843c 25b4a4cc"
       @"7fef968d 2137d229 9f09869e b88ea85d a10dc000 f37aa68f 7572c497 24b50daf c645b4eb fb749355 dbfe70ac"
       @"83276c6f 84e7addd e15d7762 5ce7b781 7aa62925 bcce4f98 1972d213 69ab6957 f7e63de3 59891fe8 faf1ff2c"
       @"622648c7 aee08c25 b5948d2b 6fb8c98d f29a1b54 bba8122b 9775a4e1 eb8acf03 58bd7726 df3d502d 04fe2a26"
       @"68a1f571 1bb1e8e8 90a9348b 0643743c 29292834 3a277265 6628313a 4331333a 27566175 6c744974 656d5265"
       @"6628373a 27697465 6d496433 333a5196 b9a6c3a3 66401f9e 42e006c6 1689ae5c 29c4a283 5d4e4d99 2c98eb56"
       @"cddfd129 2831313a 27736571 75656e63 65496433 333a5153 6153cde3 e743a5b3 4c5dac49 281e261a 3acccacb"
       @"314473bc 143ee24f 87c0a929 2831343a 27736571 75656e63 6556616c 7565393a 49000000 00000000 01292838"
       @"3a277661 756c7449 6433333a 5124c6e6 6640a6eb 44b7e1ea f6d93bb0 b332ce45 cbf0d1a0 f8e1b9d8 f2ffb8ea"
       @"20292929 292929"];

    QLFEncryptedVaultItem *encryptedVaultItem
    = [QredoPrimitiveMarshallers unmarshalObject:encryptedItemData
                                    unmarshaller:[QLFEncryptedVaultItem unmarshaller]
                                     parseHeader:NO];

    NSData *encryptedBodyExpected
    = [NSData dataWithHexString:
       @"28373a62 00000002 0000373a 62000000 01000033 333a62aa 8eee91b8 51abfd88 dffe56ef 1c4734a8 696881a5"
       @"29d3bcdf 9416d2e9 69662f29"];

    XCTAssertEqualObjects(encryptedVaultItem.encryptedBody, encryptedBodyExpected);

    NSError *error = nil;
    QLFVaultItem *vaultItem = [vaultCrypto decryptEncryptedVaultItem:encryptedVaultItem error:&error];
    XCTAssertNotNil(vaultItem);
    XCTAssertNil(error);

    NSString *dataTypeExpected = @"com.qredo.plaintext";
    NSString *vaultItemBodyStringExpected = @"vault item body";

    XCTAssertNotNil(vaultItem.metadata);
    XCTAssertNotNil(vaultItem.body);

    XCTAssertEqualObjects(vaultItem.metadata.dataType, dataTypeExpected);
    XCTAssertEqualObjects(vaultItem.body, [vaultItemBodyStringExpected dataUsingEncoding:NSUTF8StringEncoding]);

    NSData *wrongAuthCodeData
    = [NSData dataWithHexString:@"aa206a01 a2260a1c 1083bb41 3ed5a1ec d79ccdac b497db3f b6d1081b 646231aa"];

    QLFEncryptedVaultItem *encryptedVaultItemWithWrongAuthCode
    = [QLFEncryptedVaultItem encryptedVaultItemWithHeader:encryptedVaultItem.header
                                            encryptedBody:encryptedVaultItem.encryptedBody
                                                 authCode:wrongAuthCodeData];

    QLFVaultItem *vaultItemWithWrongAuthCode
    = [vaultCrypto decryptEncryptedVaultItem:encryptedVaultItemWithWrongAuthCode error:&error];
    XCTAssertNil(vaultItemWithWrongAuthCode);
    XCTAssertNotNil(error);
}

@end
