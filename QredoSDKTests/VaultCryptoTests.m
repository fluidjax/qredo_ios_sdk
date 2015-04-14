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
       @"28373a62 00000002 0000373a 62000000 02000035 31333a62 42143b53 c63ae5ab f54569b6 02cefd16 37bc39cb"
       @"2b4d7ea9 d20b05b5 9c0d00d6 770cb338 76f7aeda f02b22a3 f7366d8e 34723dc7 177ee82f 3d940bc0 3783e3d5"
       @"5686c063 0923abc4 f33944fe 7e65bed8 2a378ad0 ce5b4b4d 18ca3a29 8fff5850 3b58c33d 165dbad6 98ce4bd4"
       @"9fd01f1f 33114429 7531ea31 cda62c5e 2bc28aea c2d0406c f68821ef 54a30bed 64bda17a b9a7f07f 32550a08"
       @"a80941ab 57549084 486fea4f bbf7eeb3 b2f66bde 344871df a3ac7913 44f4b682 cd50d142 5dfbc710 1cc5559b"
       @"02d3ba4f 1841ba1a 841c57cf 317e548b 9c4fb182 14981f9b ec999e03 e28c2977 02455a97 30f4caaf ec5ec18d"
       @"a7006436 80913c40 984fedec ef5e0c09 f0242453 228dccf7 84dc55df 01644467 651bc55f b9dff754 107716dc"
       @"6e60df18 1410ef60 0a8ec9cb fd6bc3c0 f1fd023a bcbbb5aa 32e40df1 7086b801 f051eea0 19c092fa 72ec6845"
       @"0278c11b 47d21e5c c9e1718a f36eeab2 6c95e4cd 571741ad 831844f2 85b6a580 9fe0baf9 36f7625e 34a12c78"
       @"40c94d42 c33c6d0e 244bdc92 8ae78205 1eec129a f407fd09 d670f768 514fb984 10b5e6f8 045283b5 88bbae60"
       @"12f4e59d 1c833a27 6d37fb69 dbdb6fe1 0b39d5e7 42372fb7 dc755ab0 6dc48f9f a1803050 4941acc3 7ec97bfa"
       @"ebc06da4 704d9625 7f464a4e ca918d81 9a248c1d cf64e2af 7fe47835 76690237 3fd0311a 4492bda1 9dd1581b"
       @"c8b3d421 9fad2e47 29"];

    NSData *encryptedVaultItemHeaderData
    = [NSData dataWithHexString:
       @"28313a43 32353a27 456e6372 79707465 64566175 6c744974 656d4865 61646572 28393a27 61757468 436f6465"
       @"33333a62 233dde76 47497274 709d5628 4ab0d8a8 fe02ef92 7828350c 4e6ee3f9 9e82267a 29283138 3a27656e"
       @"63727970 7465644d 65746164 61746135 33383a62 28373a62 00000002 0000373a 62000000 02000035 31333a62"
       @"42143b53 c63ae5ab f54569b6 02cefd16 37bc39cb 2b4d7ea9 d20b05b5 9c0d00d6 770cb338 76f7aeda f02b22a3"
       @"f7366d8e 34723dc7 177ee82f 3d940bc0 3783e3d5 5686c063 0923abc4 f33944fe 7e65bed8 2a378ad0 ce5b4b4d"
       @"18ca3a29 8fff5850 3b58c33d 165dbad6 98ce4bd4 9fd01f1f 33114429 7531ea31 cda62c5e 2bc28aea c2d0406c"
       @"f68821ef 54a30bed 64bda17a b9a7f07f 32550a08 a80941ab 57549084 486fea4f bbf7eeb3 b2f66bde 344871df"
       @"a3ac7913 44f4b682 cd50d142 5dfbc710 1cc5559b 02d3ba4f 1841ba1a 841c57cf 317e548b 9c4fb182 14981f9b"
       @"ec999e03 e28c2977 02455a97 30f4caaf ec5ec18d a7006436 80913c40 984fedec ef5e0c09 f0242453 228dccf7"
       @"84dc55df 01644467 651bc55f b9dff754 107716dc 6e60df18 1410ef60 0a8ec9cb fd6bc3c0 f1fd023a bcbbb5aa"
       @"32e40df1 7086b801 f051eea0 19c092fa 72ec6845 0278c11b 47d21e5c c9e1718a f36eeab2 6c95e4cd 571741ad"
       @"831844f2 85b6a580 9fe0baf9 36f7625e 34a12c78 40c94d42 c33c6d0e 244bdc92 8ae78205 1eec129a f407fd09"
       @"d670f768 514fb984 10b5e6f8 045283b5 88bbae60 12f4e59d 1c833a27 6d37fb69 dbdb6fe1 0b39d5e7 42372fb7"
       @"dc755ab0 6dc48f9f a1803050 4941acc3 7ec97bfa ebc06da4 704d9625 7f464a4e ca918d81 9a248c1d cf64e2af"
       @"7fe47835 76690237 3fd0311a 4492bda1 9dd1581b c8b3d421 9fad2e47 29292834 3a277265 6628313a 4331333a"
       @"27566175 6c744974 656d5265 6628373a 27697465 6d496433 333a5196 b9a6c3a3 66401f9e 42e006c6 1689ae5c"
       @"29c4a283 5d4e4d99 2c98eb56 cddfd129 2831313a 27736571 75656e63 65496433 333a5153 6153cde3 e743a5b3"
       @"4c5dac49 281e261a 3acccacb 314473bc 143ee24f 87c0a929 2831343a 27736571 75656e63 6556616c 7565393a"
       @"49000000 00000000 01292838 3a277661 756c7449 6433333a 5124c6e6 6640a6eb 44b7e1ea f6d93bb0 b332ce45"
       @"cbf0d1a0 f8e1b9d8 f2ffb8ea 20292929 29"];

    NSData *authCodeData
    = [NSData dataWithHexString:@"233dde76 47497274 709d5628 4ab0d8a8 fe02ef92 7828350c 4e6ee3f9 9e82267a"];

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
       @"28313a43 31393a27 456e6372 79707465 64566175 6c744974 656d2839 3a276175 7468436f 64653333 3a62e3af"
       @"b47ed878 abe17b7e cc1f9873 985ea3f4 a914a1f4 aaa2bbad ea7b05d0 54772928 31343a27 656e6372 79707465"
       @"64426f64 7935373a 6228373a 62000000 02000037 3a620000 00020000 33333a62 72aa9c06 11911f7c ce15a573"
       @"5e4c8a98 240d1726 262e7d0c 185541bc 8d8c6805 29292837 3a276865 61646572 28313a43 32353a27 456e6372"
       @"79707465 64566175 6c744974 656d4865 61646572 28393a27 61757468 436f6465 33333a62 233dde76 47497274"
       @"709d5628 4ab0d8a8 fe02ef92 7828350c 4e6ee3f9 9e82267a 29283138 3a27656e 63727970 7465644d 65746164"
       @"61746135 33383a62 28373a62 00000002 0000373a 62000000 02000035 31333a62 42143b53 c63ae5ab f54569b6"
       @"02cefd16 37bc39cb 2b4d7ea9 d20b05b5 9c0d00d6 770cb338 76f7aeda f02b22a3 f7366d8e 34723dc7 177ee82f"
       @"3d940bc0 3783e3d5 5686c063 0923abc4 f33944fe 7e65bed8 2a378ad0 ce5b4b4d 18ca3a29 8fff5850 3b58c33d"
       @"165dbad6 98ce4bd4 9fd01f1f 33114429 7531ea31 cda62c5e 2bc28aea c2d0406c f68821ef 54a30bed 64bda17a"
       @"b9a7f07f 32550a08 a80941ab 57549084 486fea4f bbf7eeb3 b2f66bde 344871df a3ac7913 44f4b682 cd50d142"
       @"5dfbc710 1cc5559b 02d3ba4f 1841ba1a 841c57cf 317e548b 9c4fb182 14981f9b ec999e03 e28c2977 02455a97"
       @"30f4caaf ec5ec18d a7006436 80913c40 984fedec ef5e0c09 f0242453 228dccf7 84dc55df 01644467 651bc55f"
       @"b9dff754 107716dc 6e60df18 1410ef60 0a8ec9cb fd6bc3c0 f1fd023a bcbbb5aa 32e40df1 7086b801 f051eea0"
       @"19c092fa 72ec6845 0278c11b 47d21e5c c9e1718a f36eeab2 6c95e4cd 571741ad 831844f2 85b6a580 9fe0baf9"
       @"36f7625e 34a12c78 40c94d42 c33c6d0e 244bdc92 8ae78205 1eec129a f407fd09 d670f768 514fb984 10b5e6f8"
       @"045283b5 88bbae60 12f4e59d 1c833a27 6d37fb69 dbdb6fe1 0b39d5e7 42372fb7 dc755ab0 6dc48f9f a1803050"
       @"4941acc3 7ec97bfa ebc06da4 704d9625 7f464a4e ca918d81 9a248c1d cf64e2af 7fe47835 76690237 3fd0311a"
       @"4492bda1 9dd1581b c8b3d421 9fad2e47 29292834 3a277265 6628313a 4331333a 27566175 6c744974 656d5265"
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
       @"28373a62 00000002 0000373a 62000000 02000033 333a6272 aa9c0611 911f7cce 15a5735e 4c8a9824 0d172626"
       @"2e7d0c18 5541bc8d 8c680529"];

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
