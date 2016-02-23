/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoVaultCrypto.h"
#import "NSData+QredoRandomData.h"
#import "NSDictionary+IndexableSet.h"
#import "NSData+ParseHex.h"

@interface VaultCryptoTests : QredoXCTestCase

@end

@implementation VaultCryptoTests

- (void)generateVaultKeysWithVaultInfo:(NSString *)vaultInfo userMasterKey:(NSData *)userMasterKey
{
    NSData *vaultKey = [QredoVaultCrypto vaultKeyWithVaultMasterKey:userMasterKey info:vaultInfo];

    QredoED25519SigningKey *ownershipKeyPair = [QredoVaultCrypto ownershipSigningKeyWithVaultKey:vaultKey];
    QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKey:vaultKey];
    QredoQUID *vaultID = [[QredoQUID alloc] initWithQUIDData:ownershipKeyPair.verifyKey.data];

    QLog(@"%@:", vaultInfo);
    QLog(@" vaultKey          = %@", vaultKey);
    QLog(@" vaultID           = %@", vaultID);
    QLog(@" ownership.public  = %@", ownershipKeyPair.verifyKey.data);
    QLog(@" ownership.private = %@", ownershipKeyPair.data);
    QLog(@" encyrptionKey     = %@", encryptionAndAuthKeys.encryptionKey);
    QLog(@" authentication    = %@", encryptionAndAuthKeys.authenticationKey);


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
    
    NSDate* created = [NSDate date];
    
    QredoUTCDateTime* createdDate = [[QredoUTCDateTime alloc] initWithDate: created];
    QLFVaultItemMetadata *metadata = [QLFVaultItemMetadata vaultItemMetadataWithDataType:dataType
                                                                                 created:createdDate
                                                                                  values:indexableValues];
    NSData *serializedMetadata = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:NO];

    QLog(@" sequenceID        = %@ (random)", sequenceID);
    QLog(@" itemID            = %@ (random)", itemID);
    QLog(@" dataType          = \"%@\"", dataType);
    QLog(@" metadata.values   = %@", metadataValues);

    QLog(@" metadata          = %@", serializedMetadata);

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
    QLog(@" encyptedMetadata IV = %@", [encryptedMetadataRaw subdataWithRange:ivRange]);
    QLog(@" message(encryptedMetadata) = %@", encryptedVaultItemHeader.encryptedMetadata);
    QLog(@" header.authCode     = %@", encryptedVaultItemHeader.authCode);
    QLog(@" encryptedVaultItemHeader = %@", serializedEncryptedVaultItemHeader);

    NSString *vaultItemBodyString = @"vault item body";
    NSData *vaultItemBody = [vaultItemBodyString dataUsingEncoding:NSUTF8StringEncoding];

    QLog(@" vaultItemBody (string) = \"%@\"", vaultItemBodyString);
    QLog(@" vaultItemBody (data)   = %@", vaultItemBody);

    QLFEncryptedVaultItem *encryptedVaultItem
    = [vaultCrypto encryptVaultItemWithBody:vaultItemBody encryptedVaultItemHeader:encryptedVaultItemHeader];

    NSData *encryptedBodyRaw
    = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItem.encryptedBody
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];


    QLog(@" encryptedBody IV  = %@", [encryptedBodyRaw subdataWithRange:ivRange]);
    QLog(@" message(encryptedBody) = %@", encryptedVaultItem.encryptedBody);
    QLog(@" item.authCode     = %@", encryptedVaultItem.authCode);

    QLog(@" item.ref          = %@", [QredoPrimitiveMarshallers marshalObject:vaultItemRef includeHeader:NO]);
    QLog(@" encryptedVaultItemHeader = %@", [QredoPrimitiveMarshallers marshalObject:encryptedVaultItemHeader includeHeader:NO]);
    QLog(@" encryptedVaultItem = %@", [QredoPrimitiveMarshallers marshalObject:encryptedVaultItem includeHeader:NO]);
}

- (void)testGenerateVaultTestVectors
{
//    NSData *userMasterKey = [NSData dataWithRandomBytesOfLength:32];
    NSData *userMasterKey
    = [NSData dataWithHexString:@"86ca9c96 7e591207 02b27f02 801e6782 69fc5d40 301ed86f 03c5d6ef 7f660d66"];

    QLog(@"User master key    = %@", userMasterKey);

    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:userMasterKey];
    QLog(@"Vault master key   = %@", vaultMasterKey);

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
       @"28373a62000000020000373a620000000200003532393a6242143b53c63ae5abf54569b602cefd1637bc39cb2b4d7ea9d20b05b59c0d00d602dc7e0aec28cd39819a3377e8278af1d2e48bc10fa30954e747e832eb71163c5d97a05dfe29ff4aabfd8467065c89880f8b2788868e5725fed5675a7dbe71e3483e38d1da8b0f00d66ddbf31d01e9e2b2547beccef5459cd29d0d7be5c9c5a84d3f8a66c74348a5466d5702cfe17f24da283855c3bc0785e7dee33a3ba4ad5d4549bd940eeacecad4b3a1a030f588b8eb1e09e8ca405af346788c1e5992a50913b0414326caaaed551a749ce53327edcb0db6d282d556d2ae541af387b4a419d145f9c7cf4ac9c89c5f7038b43c01af7cb5aa6eda091aafe0533349b9c7eec86015fe2227a8b50755976d8177ace04cbc01985049c1570a715acb2b2377e60cbf5d4b2e533423313a05ec617f0a19130815c58f740cf54908e0e6844b6d9d3448bb6f992663285bca40992d00df96644113938f4d0c266453f63daccffd1452d516f5e514d5c787fdb99c2620ba3fbcd6bdb5b5433933924e683cb894ab88d40a50391f7a64164c1e11f4f95101929cd0ebd8e6cf67a83d805a8857aa84042168cb18f74469f30294939c23300a0b4d08e9ef4bb17e577c67c69886f39bcd70250df142bcfd139416c91ced994a01d435ba507ce744b4e8ef71278c88c193a9d2b99bd4cf955d46259953c212870b77105d399f00af59aa258bee70ed12e6ee96883da45ede2b058323ed4676a0ab1c29"];

    NSData *encryptedVaultItemHeaderData
    = [NSData dataWithHexString:
       @"28313a4332353a27456e637279707465645661756c744974656d48656164657228393a27617574684"
       @"36f646533333a62d4137137e34f7786d97832a9e606f035780c54d815480d0b3afea0cd11f0dedb29"
       @"2831383a27656e637279707465644d657461646174613535343a6228373a62000000020000373a620"
       @"000000200003532393a6242143b53c63ae5abf54569b602cefd1637bc39cb2b4d7ea9d20b05b59c0d"
       @"00d602dc7e0aec28cd39819a3377e8278af1d2e48bc10fa30954e747e832eb71163c5d97a05dfe29f"
       @"f4aabfd8467065c89880f8b2788868e5725fed5675a7dbe71e3483e38d1da8b0f00d66ddbf31d01e9"
       @"e2b2547beccef5459cd29d0d7be5c9c5a84d3f8a66c74348a5466d5702cfe17f24da283855c3bc078"
       @"5e7dee33a3ba4ad5d4549bd940eeacecad4b3a1a030f588b8eb1e09e8ca405af346788c1e5992a509"
       @"13b0414326caaaed551a749ce53327edcb0db6d282d556d2ae541af387b4a419d145f9c7cf4ac9c89"
       @"c5f7038b43c01af7cb5aa6eda091aafe0533349b9c7eec86015fe2227a8b50755976d8177ace04cbc"
       @"01985049c1570a715acb2b2377e60cbf5d4b2e533423313a05ec617f0a19130815c58f740cf54908e"
       @"0e6844b6d9d3448bb6f992663285bca40992d00df96644113938f4d0c266453f63daccffd1452d516"
       @"f5e514d5c787fdb99c2620ba3fbcd6bdb5b5433933924e683cb894ab88d40a50391f7a64164c1e11f"
       @"4f95101929cd0ebd8e6cf67a83d805a8857aa84042168cb18f74469f30294939c23300a0b4d08e9ef"
       @"4bb17e577c67c69886f39bcd70250df142bcfd139416c91ced994a01d435ba507ce744b4e8ef71278"
       @"c88c193a9d2b99bd4cf955d46259953c212870b77105d399f00af59aa258bee70ed12e6ee96883da4"
       @"5ede2b058323ed4676a0ab1c292928343a2772656628313a4331333a275661756c744974656d52656"
       @"628373a276974656d496433333a5196b9a6c3a366401f9e42e006c61689ae5c29c4a2835d4e4d992c"
       @"98eb56cddfd1292831313a2773657175656e6365496433333a51536153cde3e743a5b34c5dac49281"
       @"e261a3acccacb314473bc143ee24f87c0a9292831343a2773657175656e636556616c7565393a4900"
       @"000000000000012928383a277661756c74496433333a5124c6e66640a6eb44b7e1eaf6d93bb0b332c"
       @"e45cbf0d1a0f8e1b9d8f2ffb8ea2029292929"];

    NSData *authCodeData
    = [NSData dataWithHexString:@"d4137137 e34f7786 d97832a9 e606f035 780c54d8 15480d0b 3afea0cd 11f0dedb"];

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
       @"28313a4331393a27456e637279707465645661756c744974656d28393a2761757468436f646533333a62e3afb47ed878abe17b7ecc1f9873985ea3f4a914a1f4aaa2bbadea7b05d05477292831343a27656e63727970746564426f647935373a6228373a62000000020000373a6200000002000033333a6272aa9c0611911f7cce15a5735e4c8a98240d1726262e7d0c185541bc8d8c6805292928373a2768656164657228313a4332353a27456e637279707465645661756c744974656d48656164657228393a2761757468436f646533333a62d4137137e34f7786d97832a9e606f035780c54d815480d0b3afea0cd11f0dedb292831383a27656e637279707465644d657461646174613535343a6228373a62000000020000373a620000000200003532393a6242143b53c63ae5abf54569b602cefd1637bc39cb2b4d7ea9d20b05b59c0d00d602dc7e0aec28cd39819a3377e8278af1d2e48bc10fa30954e747e832eb71163c5d97a05dfe29ff4aabfd8467065c89880f8b2788868e5725fed5675a7dbe71e3483e38d1da8b0f00d66ddbf31d01e9e2b2547beccef5459cd29d0d7be5c9c5a84d3f8a66c74348a5466d5702cfe17f24da283855c3bc0785e7dee33a3ba4ad5d4549bd940eeacecad4b3a1a030f588b8eb1e09e8ca405af346788c1e5992a50913b0414326caaaed551a749ce53327edcb0db6d282d556d2ae541af387b4a419d145f9c7cf4ac9c89c5f7038b43c01af7cb5aa6eda091aafe0533349b9c7eec86015fe2227a8b50755976d8177ace04cbc01985049c1570a715acb2b2377e60cbf5d4b2e533423313a05ec617f0a19130815c58f740cf54908e0e6844b6d9d3448bb6f992663285bca40992d00df96644113938f4d0c266453f63daccffd1452d516f5e514d5c787fdb99c2620ba3fbcd6bdb5b5433933924e683cb894ab88d40a50391f7a64164c1e11f4f95101929cd0ebd8e6cf67a83d805a8857aa84042168cb18f74469f30294939c23300a0b4d08e9ef4bb17e577c67c69886f39bcd70250df142bcfd139416c91ced994a01d435ba507ce744b4e8ef71278c88c193a9d2b99bd4cf955d46259953c212870b77105d399f00af59aa258bee70ed12e6ee96883da45ede2b058323ed4676a0ab1c292928343a2772656628313a4331333a275661756c744974656d52656628373a276974656d496433333a5196b9a6c3a366401f9e42e006c61689ae5c29c4a2835d4e4d992c98eb56cddfd1292831313a2773657175656e6365496433333a51536153cde3e743a5b34c5dac49281e261a3acccacb314473bc143ee24f87c0a9292831343a2773657175656e636556616c7565393a4900000000000000012928383a277661756c74496433333a5124c6e66640a6eb44b7e1eaf6d93bb0b332ce45cbf0d1a0f8e1b9d8f2ffb8ea20292929292929"];

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
