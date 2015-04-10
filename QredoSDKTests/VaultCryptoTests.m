/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "QredoVaultCrypto.h"
#import "QredoVaultPrivate.h"
#import "NSData+QredoRandomData.h"
#import "NSDictionary+IndexableSet.h"

@interface VaultCryptoTests : XCTestCase

@end

@implementation VaultCryptoTests

- (void)generateVaultKeysWithVaultInfo:(NSString *)vaultInfo userMasterKey:(NSData *)userMasterKey
{
    NSData *vaultKey = [QredoVaultCrypto vaultKeyWithVaultMasterKey:userMasterKey info:@"System Vault"];

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

    QredoQUID *sequenceID = [QredoQUID QUID];
    QredoQUID *itemID = [QredoQUID QUID];


    QLFVaultItemRef *vaultItemRef = [QLFVaultItemRef vaultItemRefWithVaultId:vaultID
                                                                  sequenceId:sequenceID
                                                               sequenceValue:1
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

    QLFVaultItemMetadata *metadata = [QLFVaultItemMetadata vaultItemMetadataWithDataType:dataType
                                                                                  values:[metadataValues indexableSet]];

    NSData *serializedMetadata = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:NO];
    NSData *serializedMetadataWithMessage = [QredoPrimitiveMarshallers marshalObject:metadata includeHeader:YES];



    NSLog(@" sequenceID        = %@ (random)", sequenceID);
    NSLog(@" itemID            = %@ (random)", itemID);
    NSLog(@" dataType          = \"%@\"", dataType);
    NSLog(@" metadata.values   = %@", metadataValues);

    NSLog(@" metadata          = %@", serializedMetadata);
    NSLog(@" message(metadata) = %@", serializedMetadataWithMessage);

    QredoVaultCrypto *vaultCrypto = [QredoVaultCrypto vaultCryptoWithBulkKey:encryptionAndAuthKeys.encryptionKey
                                                           authenticationKey:encryptionAndAuthKeys.authenticationKey];

    QLFEncryptedVaultItemHeader *encryptedVaultItemHeader
    = [vaultCrypto encryptVaultItemHeaderWithItemRef:vaultItemRef metadata:metadata];

    NSData *serializedEncryptedVaultItemHeader
    = [QredoPrimitiveMarshallers marshalObject:encryptedVaultItemHeader includeHeader:NO];

    NSRange ivRange = NSMakeRange(0, 16);
    NSLog(@" encyptedMetadata IV = %@", [encryptedVaultItemHeader.encryptedMetadata subdataWithRange:ivRange]);
    NSLog(@" encryptedMetadata   = %@", encryptedVaultItemHeader.encryptedMetadata);
    NSLog(@" header.authCode     = %@", encryptedVaultItemHeader.authCode);
    NSLog(@" encryptedVaultItemHeader = %@", serializedEncryptedVaultItemHeader);

    NSString *vaultItemBodyString = @"vault item body";
    NSData *vaultItemBody = [vaultItemBodyString dataUsingEncoding:NSUTF8StringEncoding];

    NSLog(@" vaultItemBody (string) = \"%@\"", vaultItemBodyString);
    NSLog(@" vaultItemBody (data)   = %@", vaultItemBody);

    QLFEncryptedVaultItem *encryptedVaultItem
    = [vaultCrypto encryptVaultItemWithBody:vaultItemBody encryptedVaultItemHeader:encryptedVaultItemHeader];

    NSLog(@" encryptedBody IV  = %@", [encryptedVaultItem.encryptedBody subdataWithRange:ivRange]);
    NSLog(@" encryptedBody     = %@", encryptedVaultItem.encryptedBody);
    NSLog(@" item.authCode     = %@", encryptedVaultItem.authCode);

    NSLog(@" item.ref          = %@", [QredoPrimitiveMarshallers marshalObject:vaultItemRef includeHeader:NO]);
    NSLog(@" encryptedVaultItemHeader = %@", [QredoPrimitiveMarshallers marshalObject:encryptedVaultItemHeader includeHeader:NO]);
    NSLog(@" encryptedVaultItem = %@", [QredoPrimitiveMarshallers marshalObject:encryptedVaultItem includeHeader:NO]);
}

- (void)testGenerateVaultTestVectors
{
    NSData *userMasterKey = [NSData dataWithRandomBytesOfLength:32];

    NSLog(@"User master key    = %@", userMasterKey);

    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:userMasterKey];
    NSLog(@"Vault master key   = %@", vaultMasterKey);

    [self generateVaultKeysWithVaultInfo:@"System Vault" userMasterKey:vaultMasterKey];
    [self generateVaultKeysWithVaultInfo:@"User Vault" userMasterKey:vaultMasterKey];

    XCTAssertNotNil(userMasterKey);
}

@end
