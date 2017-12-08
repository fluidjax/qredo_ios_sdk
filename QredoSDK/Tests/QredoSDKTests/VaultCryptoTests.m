/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoVaultCrypto.h"
#import "NSData+QredoRandomData.h"
#import "NSDictionary+IndexableSet.h"
#import "NSData+HexTools.h"
#import "QredoNetworkTime.h"
#import "QredoKeyRef.h"
#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"
#import "QredoCryptoImplV1.h"
@interface VaultCryptoTests :QredoXCTestCase

@end

@implementation VaultCryptoTests

-(void)generateVaultKeysWithVaultInfo:(NSString *)vaultInfo userMasterKey:(NSData *)userMasterKey {
    //Expected results from https://github.com/qredo/qredo_ios_sdk/wiki/Vault-crypto-test-vectors
    
    NSData *expectedMetadata =  [NSData dataWithHexString:@"28313a43 31383a27 5661756c 74497465 6d4d6574 61646174 6128383a 27637265 61746564 31303a44 07b2010f 017cf758 55292839 3a276461 74615479 70653230 3a53636f 6d2e7172 65646f2e 706c6169 6e746578 74292837 3a277661 6c756573 28313a7b 28313a43 31303a27 496e6465 7861626c 6528343a 276b6579 393a536b 65795f62 6f6f6c29 28363a27 76616c75 6528313a 43363a27 53426f6f 6c28323a 2776313a 54292929 2928313a 4331303a 27496e64 65786162 6c652834 3a276b65 79393a53 6b65795f 64617465 2928363a 2776616c 75652831 3a43343a 27534454 28323a27 7631303a 4407b201 0f017cf7 58552929 29292831 3a433130 3a27496e 64657861 626c6528 343a276b 6579383a 536b6579 5f696e74 2928363a 2776616c 75652831 3a43373a 2753496e 74363428 323a2776 393a4900 00000000 00000c29 29292928 313a4331 303a2749 6e646578 61626c65 28343a27 6b657939 3a536b65 795f7175 69642928 363a2776 616c7565 28313a43 363a2753 51554944 28323a27 7633333a 512cf24d ba5fb0a3 0e26e83b 2ac5b9e2 9e1b161e 5c1fa742 5e730433 62938b98 24292929 2928313a 4331303a 27496e64 65786162 6c652834 3a276b65 7931313a 536b6579 5f737472 696e6729 28363a27 76616c75 6528313a 43383a27 53537472 696e6728 323a2776 383a5376 616c7565 20312929 29292929 29"];
    NSData *expectedHeaderAuthCode = [NSData dataWithHexString:@"cc37b482 6c517206 78257576 7f6e8966 b016b980 e6273beb bcb9f6e3 a30e1210"];
    NSData *expectedEncryptedVaultItemHeader = [NSData dataWithHexString:@"28313a43 32353a27 456e6372 79707465 64566175 6c744974 656d4865 61646572 28393a27 61757468 436f6465 33333a62 cc37b482 6c517206 78257576 7f6e8966 b016b980 e6273beb bcb9f6e3 a30e1210 29283138 3a27656e 63727970 7465644d 65746164 61746135 35313a62 28373a62 00000003 0000373a 62000000 03000035 32363a62 29357e81 ba6f9a38 00000000 00000000 1d7b2a05 5725b399 ea179b9c 32d071e5 fdc10c95 5fb067ce cab5f55e 290dec2a 58206605 23168b62 d7b1d17c 4dcf6c0d 487ef548 df52b3a1 b781c80c 507118c7 831df3c9 5b9bc406 193fb6ba ab00d002 a0ac46a4 aa62f96b 8c4b2ec7 aa9eb5d7 5ce10f06 0b2a77cf 090fc6a8 e904b207 6ae6cfd5 3ffb9dc0 0c12c3e3 e1aea3ff ad0f68a5 27a95b3b 9f85924a 37376d40 2df2f7f9 ff451c56 b7254b46 be9f9f12 8021ecf8 6a642ce1 84cba944 f1d5784b 3cfc2f5b f42087b4 83934e92 979e3506 1c5cb4e2 8c8ff600 9d09e9e3 98a8823d 0de7582e 64bddd56 79e375c7 3c59de8a c8c3fda3 3102f155 a53cc5c9 f297c175 ff226b78 46d56291 6d350913 bbaf362c ac5181f1 fcea9d2d b5fba2a5 b279d7cf dd720e9a e9ef3d51 ceb5bff0 6d8b6765 db4d0150 ea0993ac 18540a23 dc650d44 40a63d19 ec44432d bb65e2a4 4598310d d49bffd0 6fb13cf7 e9d9c674 24ec26a3 3ad30089 bbb4b007 ce331956 3f5ee406 ae1d54fe 92a67100 80b3ea67 a2e1b578 21fe3e0d cbf56d77 3e71b941 85fe1871 68571e75 97d1f138 52b26bce a658c810 e982ea41 605007b5 2bc02d17 b3b8049e 055f37d7 99698b3a 4646bc73 5afb142e e719861e 322caeca 6ee6ee39 6211995a 6709d1e0 bd70f025 dd9e9837 013c3f6d 9dcead33 a8c87042 15f3a321 ff1b05cb facd9357 c509fb56 65ab8751 cd9cb408 5dc93fbc 9e2dd2e9 e9f54cfc 11292928 343a2772 65662831 3a433133 3a275661 756c7449 74656d52 65662837 3a276974 656d4964 33333a51 96b9a6c3 a366401f 9e42e006 c61689ae 5c29c4a2 835d4e4d 992c98eb 56cddfd1 29283131 3a277365 7175656e 63654964 33333a51 536153cd e3e743a5 b34c5dac 49281e26 1a3accca cb314473 bc143ee2 4f87c0a9 29283134 3a277365 7175656e 63655661 6c756539 3a490000 00000000 00012928 383a2776 61756c74 49643333 3a51008c 907b0fd4 9818d4ba d9943856 77636b92 3b317761 b9f09c03 214b79d4 a7642929 2929"];
    NSData *expectedItemAuthCode = [NSData dataWithHexString:@"6023f901 5f7e3ffe b91023fa 65bf72ef c6af5938 b744a764 ec01a1e4 019ee7e3"];
    NSData *expectedItemRef = [NSData dataWithHexString:@"28313a43 31333a27 5661756c 74497465 6d526566 28373a27 6974656d 49643333 3a5196b9 a6c3a366 401f9e42 e006c616 89ae5c29 c4a2835d 4e4d992c 98eb56cd dfd12928 31313a27 73657175 656e6365 49643333 3a515361 53cde3e7 43a5b34c 5dac4928 1e261a3a cccacb31 4473bc14 3ee24f87 c0a92928 31343a27 73657175 656e6365 56616c75 65393a49 00000000 00000001 2928383a 27766175 6c744964 33333a51 008c907b 0fd49818 d4bad994 38567763 6b923b31 7761b9f0 9c03214b 79d4a764 2929"];
    NSData *expectedEncryptedVaultItem = [NSData dataWithHexString:@"28313a43 31393a27 456e6372 79707465 64566175 6c744974 656d2839 3a276175 7468436f 64653333 3a626023 f9015f7e 3ffeb910 23fa65bf 72efc6af 5938b744 a764ec01 a1e4019e e7e32928 31343a27 656e6372 79707465 64426f64 7935363a 6228373a 62000000 03000037 3a620000 00030000 33323a62 861b5d78 c367ca58 00000000 00000000 79fbd801 3818ae8b 2530385f a35f2e29 2928373a 27686561 64657228 313a4332 353a2745 6e637279 70746564 5661756c 74497465 6d486561 64657228 393a2761 75746843 6f646533 333a62cc 37b4826c 51720678 2575767f 6e8966b0 16b980e6 273bebbc b9f6e3a3 0e121029 2831383a 27656e63 72797074 65644d65 74616461 74613535 313a6228 373a6200 00000300 00373a62 00000003 00003532 363a6229 357e81ba 6f9a3800 00000000 0000001d 7b2a0557 25b399ea 179b9c32 d071e5fd c10c955f b067ceca b5f55e29 0dec2a58 20660523 168b62d7 b1d17c4d cf6c0d48 7ef548df 52b3a1b7 81c80c50 7118c783 1df3c95b 9bc40619 3fb6baab 00d002a0 ac46a4aa 62f96b8c 4b2ec7aa 9eb5d75c e10f060b 2a77cf09 0fc6a8e9 04b2076a e6cfd53f fb9dc00c 12c3e3e1 aea3ffad 0f68a527 a95b3b9f 85924a37 376d402d f2f7f9ff 451c56b7 254b46be 9f9f1280 21ecf86a 642ce184 cba944f1 d5784b3c fc2f5bf4 2087b483 934e9297 9e35061c 5cb4e28c 8ff6009d 09e9e398 a8823d0d e7582e64 bddd5679 e375c73c 59de8ac8 c3fda331 02f155a5 3cc5c9f2 97c175ff 226b7846 d562916d 350913bb af362cac 5181f1fc ea9d2db5 fba2a5b2 79d7cfdd 720e9ae9 ef3d51ce b5bff06d 8b6765db 4d0150ea 0993ac18 540a23dc 650d4440 a63d19ec 44432dbb 65e2a445 98310dd4 9bffd06f b13cf7e9 d9c67424 ec26a33a d30089bb b4b007ce 3319563f 5ee406ae 1d54fe92 a6710080 b3ea67a2 e1b57821 fe3e0dcb f56d773e 71b94185 fe187168 571e7597 d1f13852 b26bcea6 58c810e9 82ea4160 5007b52b c02d17b3 b8049e05 5f37d799 698b3a46 46bc735a fb142ee7 19861e32 2caeca6e e6ee3962 11995a67 09d1e0bd 70f025dd 9e983701 3c3f6d9d cead33a8 c8704215 f3a321ff 1b05cbfa cd9357c5 09fb5665 ab8751cd 9cb4085d c93fbc9e 2dd2e9e9 f54cfc11 29292834 3a277265 6628313a 4331333a 27566175 6c744974 656d5265 6628373a 27697465 6d496433 333a5196 b9a6c3a3 66401f9e 42e006c6 1689ae5c 29c4a283 5d4e4d99 2c98eb56 cddfd129 2831313a 27736571 75656e63 65496433 333a5153 6153cde3 e743a5b3 4c5dac49 281e261a 3acccacb 314473bc 143ee24f 87c0a929 2831343a 27736571 75656e63 6556616c 7565393a 49000000 00000000 01292838 3a277661 756c7449 6433333a 51008c90 7b0fd498 18d4bad9 94385677 636b923b 317761b9 f09c0321 4b79d4a7 64292929 292929"];

    
    //Preset Test Values
    NSData *encyptedMetadataIV = [NSData dataWithHexString:@"29357e81 ba6f9a38 00000000 00000000"];
    NSData *encryptedBodyIV = [NSData dataWithHexString:@"861b5d78 c367ca58 00000000 00000000"];
    QredoQUID *sequenceID = [QredoQUID QUIDWithString:@"536153cde3e743a5b34c5dac49281e261a3acccacb314473bc143ee24f87c0a9"];
    QredoQUID *itemID = [QredoQUID QUIDWithString:@"96b9a6c3a366401f9e42e006c61689ae5c29c4a2835d4e4d992c98eb56cddfd1"];
    NSDate *valueDate = [NSDate dateWithTimeIntervalSince1970:1234567];
    NSDate *created = [NSDate dateWithTimeIntervalSince1970:1234567];
    int64_t sequenceValue = 1;
    QredoQUID *valueQUID = [QredoQUID QUIDByHashingData:[@"hello" dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *dataType = @"com.qredo.plaintext";
    NSDictionary *metadataValues = @{ @"key_string":@"value 1",
                                      @"key_bool":@YES,
                                      @"key_int":@12,
                                      @"key_quid":valueQUID,
                                      @"key_date":valueDate };
    NSString *vaultItemBodyString = @"vault item body";
    
    
    
    //Build Item & Metadata
    QredoKeyRef *userMasterKeyRef = [QredoKeyRef keyRefWithKeyData:userMasterKey];
    QredoKeyRef *vaultKeyRef = [QredoVaultCrypto vaultKeyRefWithVaultMasterKeyRef:userMasterKeyRef info:vaultInfo];
    NSData *vaultKey = [vaultKeyRef debugValue];
    
    QredoED25519SigningKey *ownershipKeyPair = [[QredoCryptoImplV1 sharedInstance] qredoED25519SigningKeyWithSeed:vaultKey];
    QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKeyRef:vaultKeyRef];
    
    
    QredoQUID *vaultID = [QredoQUID QUIDWithData:ownershipKeyPair.verifyKey.data];
    
    QLFVaultItemRef *vaultItemRef = [QLFVaultItemRef vaultItemRefWithVaultId:vaultID
                                                                  sequenceId:sequenceID
                                                               sequenceValue:sequenceValue
                                                                      itemId:itemID];
    NSSet *indexableValues = [metadataValues indexableSet];
    QredoUTCDateTime *createdDate = [[QredoUTCDateTime alloc] initWithDate:created];
    QLFVaultItemMetadata *metadata = [QLFVaultItemMetadata vaultItemMetadataWithDataType:dataType
                                                                                 created:createdDate
                                                                                  values:indexableValues];
    NSData *serializedMetadata = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:NO];
    QredoVaultCrypto *vaultCrypto = [QredoVaultCrypto vaultCryptoWithBulkKeyRef:[QredoKeyRef keyRefWithKeyData:encryptionAndAuthKeys.encryptionKey]
                                                           authenticationKeyRef:[QredoKeyRef keyRefWithKeyData:encryptionAndAuthKeys.authenticationKey]];
    QLFEncryptedVaultItemHeader *encryptedVaultItemHeader  = [vaultCrypto encryptVaultItemHeaderWithItemRef:vaultItemRef metadata:metadata iv:encyptedMetadataIV];
    NSData *serializedEncryptedVaultItemHeader  = [QredoPrimitiveMarshallers marshalObject:encryptedVaultItemHeader includeHeader:NO];
    NSData *encryptedMetadataRaw   = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItemHeader.encryptedMetadata
                                                                   unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                                                    parseHeader:YES];

    
    //Test Metadata
    XCTAssert([serializedMetadata isEqualToData:expectedMetadata],@"Bad expected Metadata");
    XCTAssert([encryptedVaultItemHeader.authCode isEqualToData:expectedHeaderAuthCode],@"Bad expected Header Auth Code");
    XCTAssert([serializedEncryptedVaultItemHeader isEqualToData:expectedEncryptedVaultItemHeader],@"Bad EncryptedVaultItemHeader");
    
    
    //Build Body & Item
    NSRange ivRange = NSMakeRange(0,16);
    NSData *vaultItemBody = [vaultItemBodyString dataUsingEncoding:NSUTF8StringEncoding];
    QLFEncryptedVaultItem *encryptedVaultItem   = [vaultCrypto encryptVaultItemWithBody:vaultItemBody encryptedVaultItemHeader:encryptedVaultItemHeader iv:encryptedBodyIV];
    NSData *encryptedBodyRaw   = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItem.encryptedBody
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];
    NSData *itemRefData = [QredoPrimitiveMarshallers marshalObject:vaultItemRef includeHeader:NO];
    NSData *encryptedVaultItemData = [QredoPrimitiveMarshallers marshalObject:encryptedVaultItem includeHeader:NO];
    
    //Test Item
    XCTAssert([encryptedVaultItem.authCode isEqualToData:expectedItemAuthCode],@"Bad expected Item Auth Code");
    XCTAssert([itemRefData isEqualToData:expectedItemRef],@"Bad expected Item Ref");
    XCTAssert([encryptedVaultItemData isEqualToData:expectedEncryptedVaultItem],@"Bad EncryptedVaultItem");
    

    //#define QLog(fmt, ...) NSLog((@" " fmt), ##__VA_ARGS__)
    
    //Dump values
    QredoLogInfo(@"%@:",vaultInfo);
    QredoLogInfo(@" vaultKey          = %@",vaultKey);
    QredoLogInfo(@" vaultID           = %@",vaultID);
    QredoLogInfo(@" ownership.public  = %@",ownershipKeyPair.verifyKey.data);
    QredoLogInfo(@" ownership.private = %@",ownershipKeyPair.data);
    QredoLogInfo(@" encyrptionKey     = %@",encryptionAndAuthKeys.encryptionKey);
    QredoLogInfo(@" authentication    = %@",encryptionAndAuthKeys.authenticationKey);
    
    QredoLogInfo(@" sequenceID        = %@ (random)",sequenceID);
    QredoLogInfo(@" itemID            = %@ (random)",itemID);
    QredoLogInfo(@" dataType          = \"%@\"",dataType);
    QredoLogInfo(@" metadata.values   = %@",metadataValues);
    QredoLogInfo(@" metadata          = %@",serializedMetadata);
    
    QredoLogInfo(@" encyptedMetadata IV = %@",[encryptedMetadataRaw subdataWithRange:ivRange]);
    QredoLogInfo(@" message(encryptedMetadata) = %@",encryptedVaultItemHeader.encryptedMetadata);
    QredoLogInfo(@" header.authCode     = %@",encryptedVaultItemHeader.authCode);
    QredoLogInfo(@" encryptedVaultItemHeader = %@",serializedEncryptedVaultItemHeader);
    QredoLogInfo(@" vaultItemBody (string) = \"%@\"",vaultItemBodyString);
    QredoLogInfo(@" vaultItemBody (data)   = %@",vaultItemBody);

    QredoLogInfo(@" encryptedBody IV  = %@",[encryptedBodyRaw subdataWithRange:ivRange]);
    QredoLogInfo(@" message(encryptedBody) = %@",encryptedVaultItem.encryptedBody);
    QredoLogInfo(@" item.authCode     = %@",encryptedVaultItem.authCode);
    QredoLogInfo(@" item.ref          = %@",itemRefData);
    QredoLogInfo(@" encryptedVaultItemHeader = %@",encryptedVaultItemData);
    QredoLogInfo(@" encryptedVaultItem = %@",[QredoPrimitiveMarshallers marshalObject:encryptedVaultItem includeHeader:NO]);
}


-(void)testGenerateVaultTestVectors {
    QredoKeyRef *userMasterKeyRef = [QredoKeyRef keyRefWithKeyHexString:@"86ca9c96 7e591207 02b27f02 801e6782 69fc5d40 301ed86f 03c5d6ef 7f660d66"];
    QredoLogInfo(@"User master key    = %@",[userMasterKeyRef debugValue]);
    QredoKeyRef *vaultMasterKeyRef = [QredoVaultCrypto vaultMasterKeyRefWithUserMasterKeyRef:userMasterKeyRef];
    QredoLogInfo(@"Vault master key   = %@",[vaultMasterKeyRef debugValue]);
    [self generateVaultKeysWithVaultInfo:@"User Vault" userMasterKey:[vaultMasterKeyRef debugValue]];
    XCTAssertNotNil([userMasterKeyRef debugValue]);
}


-(void)testVaultKeysTestVectors {
    QredoKeyRef *userMasterKeyRef = [QredoKeyRef keyRefWithKeyHexString:@"86ca9c96 7e591207 02b27f02 801e6782 69fc5d40 301ed86f 03c5d6ef 7f660d66"];
    QredoKeyRef *vaultMasterKeyRef = [QredoVaultCrypto vaultMasterKeyRefWithUserMasterKeyRef:userMasterKeyRef];
    
    NSData *vaultMasterKeyExpected
    = [NSData dataWithHexString:@"35eb9b03 4ceffd10 2778457c 04c6fc24 ea50f845 10173fa5 479184c4 9eff52d5"];
    
    XCTAssertEqualObjects([vaultMasterKeyRef debugValue],vaultMasterKeyExpected);
    
    //System vault
    QredoKeyRef *vaultKeyRef = [QredoVaultCrypto systemVaultKeyRefWithVaultMasterKeyRef:vaultMasterKeyRef];
    NSData *vaultKeyExpected
    = [NSData dataWithHexString:@"b63d366a 815fc76d 8268aaa3 4e607e86 c2e964bd 9c445310 3ee696a5 e82b08de"];
    
    XCTAssertEqualObjects([vaultKeyRef debugValue],vaultKeyExpected);
    
    QredoED25519SigningKey *ownershipKeyPair = [[QredoCryptoImplV1 sharedInstance] qredoED25519SigningKeyWithSeed:[vaultKeyRef debugValue]];
    NSData *signingKeyExpected
    = [NSData dataWithHexString:
       @"b63d366a 815fc76d 8268aaa3 4e607e86 c2e964bd 9c445310 3ee696a5 e82b08de 24c6e666 40a6eb44 b7e1eaf6"
       @"d93bb0b3 32ce45cb f0d1a0f8 e1b9d8f2 ffb8ea20"];
    
    NSData *verifyingKeyExpected
    = [NSData dataWithHexString:@"24c6e666 40a6eb44 b7e1eaf6 d93bb0b3 32ce45cb f0d1a0f8 e1b9d8f2 ffb8ea20"];
    
    
    XCTAssertEqualObjects(ownershipKeyPair.data,signingKeyExpected);
    
    XCTAssertEqualObjects(ownershipKeyPair.verifyKey.data,verifyingKeyExpected);
    
    
    QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKeyRef:vaultKeyRef];
    NSData *encryptionKeyExpected
    = [NSData dataWithHexString:@"cb5e8fc6 0596ebf3 99d01185 45e99425 8567cdbd 82fa8f09 7a5260d1 945ba30c"];
    
    NSData *authenticationKeyExpected
    = [NSData dataWithHexString:@"7eca67be 841c1f08 e828a0be abdcb160 08cb8752 f2bc34e3 578e3117 2793c820"];
    
    XCTAssertEqualObjects(encryptionAndAuthKeys.encryptionKey,encryptionKeyExpected);
    XCTAssertEqualObjects(encryptionAndAuthKeys.authenticationKey,authenticationKeyExpected);
}


@end
