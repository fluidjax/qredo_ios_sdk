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
    NSData *vaultKey = [QredoVaultCrypto vaultKeyWithVaultMasterKey:userMasterKey info:vaultInfo];
    
    QredoED25519SigningKey *ownershipKeyPair = [QredoVaultCrypto ownershipSigningKeyWithVaultKey:vaultKey];
    QLFVaultKeyPair *encryptionAndAuthKeys = [QredoVaultCrypto vaultKeyPairWithVaultKey:vaultKey];
    QredoQUID *vaultID = [[QredoQUID alloc] initWithQUIDData:ownershipKeyPair.verifyKey.data];
    
    QLog(@"%@:",vaultInfo);
    QLog(@" vaultKey          = %@",vaultKey);
    QLog(@" vaultID           = %@",vaultID);
    QLog(@" ownership.public  = %@",ownershipKeyPair.verifyKey.data);
    QLog(@" ownership.private = %@",ownershipKeyPair.data);
    QLog(@" encyrptionKey     = %@",encryptionAndAuthKeys.encryptionKey);
    QLog(@" authentication    = %@",encryptionAndAuthKeys.authenticationKey);
    
    
    //QredoQUID *sequenceID = [QredoQUID QUID];
    //QredoQUID *itemID = [QredoQUID QUID];
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
    
    NSDictionary *metadataValues = @{ @"key_string":@"value 1",
                                      @"key_bool":@YES,
                                      @"key_int":@12,
                                      @"key_quid":valueQUID,
                                      @"key_date":valueDate };
    
    NSSet *indexableValues = [metadataValues indexableSet];
    
    NSDate *created = [QredoNetworkTime dateTime];
    
    QredoUTCDateTime *createdDate = [[QredoUTCDateTime alloc] initWithDate:created];
    QLFVaultItemMetadata *metadata = [QLFVaultItemMetadata vaultItemMetadataWithDataType:dataType
                                                                                 created:createdDate
                                                                                  values:indexableValues];
    NSData *serializedMetadata = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:NO];
    
    QLog(@" sequenceID        = %@ (random)",sequenceID);
    QLog(@" itemID            = %@ (random)",itemID);
    QLog(@" dataType          = \"%@\"",dataType);
    QLog(@" metadata.values   = %@",metadataValues);
    
    QLog(@" metadata          = %@",serializedMetadata);
    
    QredoVaultCrypto *vaultCrypto
    = [QredoVaultCrypto vaultCryptoWithBulkKey:encryptionAndAuthKeys.encryptionKey
                             authenticationKey:encryptionAndAuthKeys.authenticationKey];
    
    QLFEncryptedVaultItemHeader *encryptedVaultItemHeader  = [vaultCrypto encryptVaultItemHeaderWithItemRef:vaultItemRef metadata:metadata];
    
    NSData *serializedEncryptedVaultItemHeader  = [QredoPrimitiveMarshallers marshalObject:encryptedVaultItemHeader includeHeader:NO];
    
    NSData *encryptedMetadataRaw   = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItemHeader.encryptedMetadata
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];
    
    NSRange ivRange = NSMakeRange(0,16);
    QLog(@" encyptedMetadata IV = %@",[encryptedMetadataRaw subdataWithRange:ivRange]);
    QLog(@" message(encryptedMetadata) = %@",encryptedVaultItemHeader.encryptedMetadata);
    QLog(@" header.authCode     = %@",encryptedVaultItemHeader.authCode);
    QLog(@" encryptedVaultItemHeader = %@",serializedEncryptedVaultItemHeader);
    
    NSString *vaultItemBodyString = @"vault item body";
    NSData *vaultItemBody = [vaultItemBodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    QLog(@" vaultItemBody (string) = \"%@\"",vaultItemBodyString);
    QLog(@" vaultItemBody (data)   = %@",vaultItemBody);
    
    QLFEncryptedVaultItem *encryptedVaultItem   = [vaultCrypto encryptVaultItemWithBody:vaultItemBody encryptedVaultItemHeader:encryptedVaultItemHeader];
    
    NSData *encryptedBodyRaw   = [QredoPrimitiveMarshallers unmarshalObject:encryptedVaultItem.encryptedBody
                                    unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]
                                     parseHeader:YES];
    
    
    QLog(@" encryptedBody IV  = %@",[encryptedBodyRaw subdataWithRange:ivRange]);
    QLog(@" message(encryptedBody) = %@",encryptedVaultItem.encryptedBody);
    QLog(@" item.authCode     = %@",encryptedVaultItem.authCode);
    
    QLog(@" item.ref          = %@",[QredoPrimitiveMarshallers marshalObject:vaultItemRef includeHeader:NO]);
    QLog(@" encryptedVaultItemHeader = %@",[QredoPrimitiveMarshallers marshalObject:encryptedVaultItemHeader includeHeader:NO]);
    QLog(@" encryptedVaultItem = %@",[QredoPrimitiveMarshallers marshalObject:encryptedVaultItem includeHeader:NO]);
    NSLog(@"DONE");
    
}


-(void)testGenerateVaultTestVectors {
    //NSData *userMasterKey = [NSData dataWithRandomBytesOfLength:32];
    NSData *userMasterKey = [NSData dataWithHexString:@"86ca9c96 7e591207 02b27f02 801e6782 69fc5d40 301ed86f 03c5d6ef 7f660d66"];
    
    QLog(@"User master key    = %@",userMasterKey);
    
    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:userMasterKey];
    QLog(@"Vault master key   = %@",vaultMasterKey);
    
    [self generateVaultKeysWithVaultInfo:@"System Vault" userMasterKey:vaultMasterKey];
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
