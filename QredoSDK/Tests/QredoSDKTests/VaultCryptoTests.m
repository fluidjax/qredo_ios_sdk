/* HEADER GOES HERE */
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoVaultCrypto.h"
#import "NSData+QredoRandomData.h"
#import "NSDictionary+IndexableSet.h"
#import "NSData+HexTools.h"
#import "QredoNetworkTime.h"

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
    
    NSData *expectedEncryptedVaultItem = [NSData dataWithHexString:@"28313a43 32353a27 456e6372 79707465 64566175 6c744974 656d4865 61646572 28393a27 61757468 436f6465 33333a62 cc37b482 6c517206 78257576 7f6e8966 b016b980 e6273beb bcb9f6e3 a30e1210 29283138 3a27656e 63727970 7465644d 65746164 61746135 35313a62 28373a62 00000003 0000373a 62000000 03000035 32363a62 29357e81 ba6f9a38 00000000 00000000 1d7b2a05 5725b399 ea179b9c 32d071e5 fdc10c95 5fb067ce cab5f55e 290dec2a 58206605 23168b62 d7b1d17c 4dcf6c0d 487ef548 df52b3a1 b781c80c 507118c7 831df3c9 5b9bc406 193fb6ba ab00d002 a0ac46a4 aa62f96b 8c4b2ec7 aa9eb5d7 5ce10f06 0b2a77cf 090fc6a8 e904b207 6ae6cfd5 3ffb9dc0 0c12c3e3 e1aea3ff ad0f68a5 27a95b3b 9f85924a 37376d40 2df2f7f9 ff451c56 b7254b46 be9f9f12 8021ecf8 6a642ce1 84cba944 f1d5784b 3cfc2f5b f42087b4 83934e92 979e3506 1c5cb4e2 8c8ff600 9d09e9e3 98a8823d 0de7582e 64bddd56 79e375c7 3c59de8a c8c3fda3 3102f155 a53cc5c9 f297c175 ff226b78 46d56291 6d350913 bbaf362c ac5181f1 fcea9d2d b5fba2a5 b279d7cf dd720e9a e9ef3d51 ceb5bff0 6d8b6765 db4d0150 ea0993ac 18540a23 dc650d44 40a63d19 ec44432d bb65e2a4 4598310d d49bffd0 6fb13cf7 e9d9c674 24ec26a3 3ad30089 bbb4b007 ce331956 3f5ee406 ae1d54fe 92a67100 80b3ea67 a2e1b578 21fe3e0d cbf56d77 3e71b941 85fe1871 68571e75 97d1f138 52b26bce a658c810 e982ea41 605007b5 2bc02d17 b3b8049e 055f37d7 99698b3a 4646bc73 5afb142e e719861e 322caeca 6ee6ee39 6211995a 6709d1e0 bd70f025 dd9e9837 013c3f6d 9dcead33 a8c87042 15f3a321 ff1b05cb facd9357 c509fb56 65ab8751 cd9cb408 5dc93fbc 9e2dd2e9 e9f54cfc 11292928 343a2772 65662831 3a433133 3a275661 756c7449 74656d52 65662837 3a276974 656d4964 33333a51 96b9a6c3 a366401f 9e42e006 c61689ae 5c29c4a2 835d4e4d 992c98eb 56cddfd1 29283131 3a277365 7175656e 63654964 33333a51 536153cd e3e743a5 b34c5dac 49281e26 1a3accca cb314473 bc143ee2 4f87c0a9 29283134 3a277365 7175656e 63655661 6c756539 3a490000 00000000 00012928 383a2776 61756c74 49643333 3a51008c 907b0fd4 9818d4ba d9943856 77636b92 3b317761 b9f09c03 214b79d4 a7642929 2929"];

    
    //Preset Test Values
    NSData *encyptedMetadataIV = [NSData dataWithHexString:@"29357e81 ba6f9a38 00000000 00000000"];
    NSData *encryptedBodyIV = [NSData dataWithHexString:@"861b5d78 c367ca58 00000000 00000000"];
    QredoQUID *sequenceID = [[QredoQUID alloc] initWithQUIDString:@"536153cde3e743a5b34c5dac49281e261a3acccacb314473bc143ee24f87c0a9"];
    QredoQUID *itemID = [[QredoQUID alloc] initWithQUIDString:@"96b9a6c3a366401f9e42e006c61689ae5c29c4a2835d4e4d992c98eb56cddfd1"];
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
    NSData *vaultKey = [QredoVaultCrypto vaultKeyWithVaultMasterKey:userMasterKey info:vaultInfo];
    QredoED25519SigningKey *ownershipKeyPair = [QredoVaultCrypto ownershipSigningKeyWithVaultKey:vaultKey];
    QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKey:vaultKey];
    QredoQUID *vaultID = [[QredoQUID alloc] initWithQUIDData:ownershipKeyPair.verifyKey.data];
    
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
    QredoVaultCrypto *vaultCrypto = [QredoVaultCrypto vaultCryptoWithBulkKey:encryptionAndAuthKeys.encryptionKey
                                                           authenticationKey:encryptionAndAuthKeys.authenticationKey];
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
    NSData *encryptedVaultItemData = [QredoPrimitiveMarshallers marshalObject:encryptedVaultItemHeader includeHeader:NO];
    
    //Test Item
    XCTAssert([encryptedVaultItem.authCode isEqualToData:expectedItemAuthCode],@"Bad expected Item Auth Code");
    XCTAssert([itemRefData isEqualToData:expectedItemRef],@"Bad expected Item Ref");
    XCTAssert([encryptedVaultItemData isEqualToData:expectedEncryptedVaultItem],@"Bad EncryptedVaultItem");
    
    
    
    //Dump values
    QLog(@"%@:",vaultInfo);
    QLog(@" vaultKey          = %@",vaultKey);
    QLog(@" vaultID           = %@",vaultID);
    QLog(@" ownership.public  = %@",ownershipKeyPair.verifyKey.data);
    QLog(@" ownership.private = %@",ownershipKeyPair.data);
    QLog(@" encyrptionKey     = %@",encryptionAndAuthKeys.encryptionKey);
    QLog(@" authentication    = %@",encryptionAndAuthKeys.authenticationKey);
    
    QLog(@" sequenceID        = %@ (random)",sequenceID);
    QLog(@" itemID            = %@ (random)",itemID);
    QLog(@" dataType          = \"%@\"",dataType);
    QLog(@" metadata.values   = %@",metadataValues);
    QLog(@" metadata          = %@",serializedMetadata);
    
    QLog(@" encyptedMetadata IV = %@",[encryptedMetadataRaw subdataWithRange:ivRange]);
    QLog(@" message(encryptedMetadata) = %@",encryptedVaultItemHeader.encryptedMetadata);
    QLog(@" header.authCode     = %@",encryptedVaultItemHeader.authCode);
    QLog(@" encryptedVaultItemHeader = %@",serializedEncryptedVaultItemHeader);
    QLog(@" vaultItemBody (string) = \"%@\"",vaultItemBodyString);
    QLog(@" vaultItemBody (data)   = %@",vaultItemBody);

    QLog(@" encryptedBody IV  = %@",[encryptedBodyRaw subdataWithRange:ivRange]);
    QLog(@" message(encryptedBody) = %@",encryptedVaultItem.encryptedBody);
    QLog(@" item.authCode     = %@",encryptedVaultItem.authCode);
    QLog(@" item.ref          = %@",itemRefData);
    QLog(@" encryptedVaultItemHeader = %@",encryptedVaultItemData);
    QLog(@" encryptedVaultItem = %@",[QredoPrimitiveMarshallers marshalObject:encryptedVaultItem includeHeader:NO]);
}


-(void)testGenerateVaultTestVectors {
    NSData *userMasterKey = [NSData dataWithHexString:@"86ca9c96 7e591207 02b27f02 801e6782 69fc5d40 301ed86f 03c5d6ef 7f660d66"];
    QLog(@"User master key    = %@",userMasterKey);
    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:userMasterKey];
    QLog(@"Vault master key   = %@",vaultMasterKey);
    [self generateVaultKeysWithVaultInfo:@"User Vault" userMasterKey:vaultMasterKey];
    XCTAssertNotNil(userMasterKey);
}


-(void)testVaultKeysTestVectors {
    NSData *userMasterKey
    = [NSData dataWithHexString:@"86ca9c96 7e591207 02b27f02 801e6782 69fc5d40 301ed86f 03c5d6ef 7f660d66"];
    
    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:userMasterKey];
    
    NSData *vaultMasterKeyExpected
    = [NSData dataWithHexString:@"35eb9b03 4ceffd10 2778457c 04c6fc24 ea50f845 10173fa5 479184c4 9eff52d5"];
    
    XCTAssertEqualObjects(vaultMasterKey,vaultMasterKeyExpected);
    
    //System vault
    NSData *vaultKey = [QredoVaultCrypto systemVaultKeyWithVaultMasterKey:vaultMasterKey];
    NSData *vaultKeyExpected
    = [NSData dataWithHexString:@"b63d366a 815fc76d 8268aaa3 4e607e86 c2e964bd 9c445310 3ee696a5 e82b08de"];
    
    XCTAssertEqualObjects(vaultKey,vaultKeyExpected);
    
    QredoED25519SigningKey *ownershipKeyPair = [QredoVaultCrypto ownershipSigningKeyWithVaultKey:vaultKey];
    NSData *signingKeyExpected
    = [NSData dataWithHexString:
       @"b63d366a 815fc76d 8268aaa3 4e607e86 c2e964bd 9c445310 3ee696a5 e82b08de 24c6e666 40a6eb44 b7e1eaf6"
       @"d93bb0b3 32ce45cb f0d1a0f8 e1b9d8f2 ffb8ea20"];
    
    NSData *verifyingKeyExpected
    = [NSData dataWithHexString:@"24c6e666 40a6eb44 b7e1eaf6 d93bb0b3 32ce45cb f0d1a0f8 e1b9d8f2 ffb8ea20"];
    
    XCTAssertEqualObjects(ownershipKeyPair.data,signingKeyExpected);
    XCTAssertEqualObjects(ownershipKeyPair.verifyKey.data,verifyingKeyExpected);
    
    
    QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKey:vaultKey];
    NSData *encryptionKeyExpected
    = [NSData dataWithHexString:@"cb5e8fc6 0596ebf3 99d01185 45e99425 8567cdbd 82fa8f09 7a5260d1 945ba30c"];
    
    NSData *authenticationKeyExpected
    = [NSData dataWithHexString:@"7eca67be 841c1f08 e828a0be abdcb160 08cb8752 f2bc34e3 578e3117 2793c820"];
    
    XCTAssertEqualObjects(encryptionAndAuthKeys.encryptionKey,encryptionKeyExpected);
    XCTAssertEqualObjects(encryptionAndAuthKeys.authenticationKey,authenticationKeyExpected);
}


@end
