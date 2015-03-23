/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "QLFOwnershipSignature+FactoryMethods.h"
#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoClient.h"
#import "QredoSigner.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "CryptoImplV1.h"


// =============================================================================================================
#pragma mark - Test data -
// =============================================================================================================

static char privateKeyBytes[] = {
    0x50, 0xde, 0xf6, 0x18, 0x5a, 0x14, 0xe1, 0x13, 0x9c, 0x46, 0x37, 0xd3,
    0xc2, 0x18, 0x98, 0xb5, 0x8a, 0x8e, 0xbb, 0xac, 0xb6, 0x52, 0xbf, 0x18,
    0x91, 0x95, 0xf9, 0xa5, 0xbb, 0x0c, 0xa1, 0x45
};

static char publicKeyBytes[] = {
    0xb2, 0x1b, 0xd4, 0x8d, 0x1e, 0x9b, 0xdc, 0x3a, 0xe0, 0x53, 0xc1, 0x9c,
    0x23, 0x10, 0x03, 0x24, 0xce, 0xa7, 0x48, 0xf3, 0xb2, 0xbe, 0x71, 0x6f,
    0xa7, 0xe9, 0xbd, 0x72, 0xce, 0xa3, 0x24, 0x08
};

static char vaultIdBytes[] = {
    0xb2, 0x1b, 0xd4, 0x8d, 0x1e, 0x9b, 0xdc, 0x3a, 0xe0, 0x53, 0xc1, 0x9c,
    0x23, 0x10, 0x03, 0x24, 0xce, 0xa7, 0x48, 0xf3, 0xb2, 0xbe, 0x71, 0x6f,
    0xa7, 0xe9, 0xbd, 0x72, 0xce, 0xa3, 0x24, 0x08
};

static char sequenceIdBytes[] = {
    0x08, 0x2f, 0x8b, 0xaa, 0x44, 0x56, 0x7c, 0xb4, 0xae, 0x76, 0x37, 0x34,
    0x32, 0xcd, 0xf5, 0xe2, 0x19, 0x9c, 0x85, 0xc6, 0xfb, 0x3f, 0x59, 0x74,
    0x2c, 0x7e, 0xb0, 0x34, 0x41, 0xde, 0x02, 0x66
};

static char itemIdvalBytes[] = {
    0x0c, 0x4d, 0x4a, 0xb8, 0xc5, 0x1d, 0x14, 0x41, 0x55, 0xde, 0x99, 0xd6,
    0x20, 0x80, 0x7a, 0xef, 0x34, 0x7d, 0x3f, 0xdd, 0x72, 0xad, 0xc2, 0xa7,
    0xf7, 0x50, 0x4e, 0x21, 0x58, 0x3b, 0xa6, 0x78
};

static char randBytesForMetaBytes[] = {
    0x1b, 0x01, 0xbb, 0x0e, 0xda, 0x60, 0x37, 0x8e, 0x87, 0x34, 0xa0, 0x79,
    0x1c, 0x44, 0x26, 0x59, 0x44, 0x95, 0x59, 0x6b, 0x8c, 0x0a, 0x89, 0xc5,
    0x8b, 0xac, 0xcd, 0x10, 0x25, 0x22, 0x9d, 0x2e, 0x96, 0x3a, 0x4a, 0x9b,
    0x91, 0x40, 0x59, 0xdb, 0x39, 0x26, 0x5b, 0x1e, 0xe8, 0x52, 0x64, 0x72,
    0xbd, 0x39, 0xe4, 0x8a, 0x91, 0x1b, 0x54, 0xe9, 0x81, 0xcd, 0x7a, 0xed,
    0x76, 0x3b, 0xf6, 0xd9, 0xa0, 0x4a, 0x66, 0xf8, 0xa8, 0x94, 0x41, 0x03,
    0x14, 0x85, 0x55, 0xa7, 0x68, 0x68, 0xcd, 0x7a, 0xbe, 0xf9, 0xd6, 0x3f,
    0xb8, 0xde, 0x31, 0x8a, 0xa1, 0x57, 0x76, 0x9d, 0xb1, 0x60, 0x2a, 0x68,
    0xa3, 0xab, 0x50, 0xc4, 0x14, 0x29, 0x5c, 0x26, 0x15, 0xa2, 0x0e, 0x38,
    0xee, 0xc0, 0xf4, 0xda, 0x7a, 0xf0, 0xfd, 0x09, 0xa5, 0x64, 0x8d, 0x00,
    0x29, 0xb0, 0xd7, 0xee, 0x52, 0x55, 0x95, 0xbc, 0x2d, 0x06, 0x5c, 0xe0,
    0xf1, 0x9c, 0x41, 0x4c, 0x29, 0xbc, 0xe5, 0x6f, 0xeb, 0x28, 0xab, 0xf7,
    0x57, 0xd8, 0x63, 0x21, 0xd4, 0x22, 0x96, 0x05, 0x30, 0xd1, 0x4e, 0x46,
    0x4f, 0x42, 0x0e, 0xc2, 0xc8, 0xc0, 0x69, 0xd7, 0x62, 0x90, 0xcc, 0x3b,
    0xfa, 0x4c, 0x63, 0x12, 0xbe, 0x0f, 0x14, 0x82, 0xe8, 0x25, 0x17, 0x06,
    0x26, 0x03, 0x5c, 0xb3, 0x8d, 0xa8, 0x84, 0x2c, 0x1f, 0xe5, 0x3e, 0x80,
    0xd0, 0x61, 0x9f, 0xe4, 0x9c, 0x1b, 0xd0, 0x13, 0x36, 0x5d, 0x35, 0x43,
    0x4a, 0x40, 0xfa, 0x76, 0x02, 0x26, 0x25, 0x94, 0xa5, 0xb3, 0x5b, 0xf8,
    0x3d, 0x54, 0x12, 0x87, 0xbc, 0x1b, 0x1d, 0x96, 0x9f, 0x69, 0x07, 0x2c,
    0xfc, 0x59, 0x22, 0xc3, 0x6a, 0x23, 0x34, 0xef, 0x4f, 0xfc, 0x65, 0x5c,
    0x38, 0x95, 0x33, 0xe1, 0x1d, 0x72, 0x5f, 0xe4, 0x52, 0x1f, 0x11, 0x87,
    0x7c, 0x3c, 0xca, 0xcf, 0xe6, 0xdc, 0xa7, 0xba, 0x72, 0x60, 0xd5, 0x16,
    0xbe, 0x9b, 0x49, 0xee, 0xf9, 0x61, 0x73, 0xc5, 0x1f, 0x42, 0xa4, 0x68,
    0x08, 0xd1, 0x79, 0x7c, 0x14, 0xc2, 0x67, 0x94, 0xf1, 0xfd, 0xb2, 0x41,
    0x96, 0x6e, 0x3e, 0x65, 0x51, 0xc2, 0xac, 0x7e, 0xf8, 0x0a, 0xa0, 0x24,
    0x6c, 0x08, 0xb9, 0x63, 0xd4, 0x68, 0x27, 0xe0, 0x54, 0xb1, 0x71, 0x65,
    0x86, 0x3d, 0x1d, 0x25, 0xd4, 0x64, 0x9d, 0xab, 0xe7, 0xb7, 0xfa, 0xd8,
    0x6f, 0x76, 0xd8, 0xef, 0xab, 0xff, 0x03, 0xad, 0x5c, 0xe6, 0x28, 0xdc,
    0x82, 0xa1, 0xce, 0xe5, 0x66, 0x20, 0x89, 0xd1, 0x54, 0xb7, 0xbd, 0xb9,
    0x2d, 0x79, 0x27, 0x03, 0x6a, 0xde, 0xa8, 0x62, 0x4b, 0x1a, 0xa5, 0x86,
    0x45, 0xa6, 0x18, 0x2a, 0x11, 0x2f, 0x7e, 0x18, 0xdb, 0x25, 0x6c, 0x0c,
    0xde, 0x08, 0x91, 0x6a, 0x4b, 0x31, 0x3c, 0xf7, 0xb2, 0x4e, 0xff, 0x5d,
    0xe8, 0xf9, 0xd8, 0x3e, 0xb3, 0x97, 0x0a, 0x45, 0xa4, 0xc0, 0x2f, 0xc2,
    0xc8, 0xc1, 0xf0, 0x64, 0x43, 0xcd, 0x06, 0xa8, 0xdd, 0x3f, 0xb4, 0x1e,
    0x20, 0xfd, 0xb1, 0x51, 0x5d, 0x71, 0x80, 0xee, 0x06, 0xf8, 0xda, 0x6f,
    0x93, 0x9d, 0xf4, 0x80, 0x7d, 0xb5, 0x73, 0xc5, 0x8d, 0x5a, 0x04, 0x3e,
    0xd2, 0x79, 0xed, 0xc2, 0xa1, 0x8b, 0x8f, 0x19, 0x8c, 0x18, 0x6a, 0x92,
    0x54, 0x2d, 0x33, 0x40, 0x7d, 0x80, 0x37, 0xf7, 0xde, 0x70, 0x8c, 0xd8,
    0x44, 0xd3, 0x33, 0x7c, 0x5a, 0x73, 0x7d, 0x06, 0x8c, 0x01, 0xc2, 0x97,
    0xbf, 0xf6, 0xcd, 0x41, 0x86, 0x9d, 0xdf, 0x68, 0x9d, 0x39, 0x79, 0x1c,
    0xd4, 0x75, 0xf1, 0xe5, 0x21, 0x8e, 0x3a, 0x22, 0xd8, 0x88, 0x1b, 0x63,
    0x71, 0x8d, 0xf9, 0x10, 0x29, 0x4f, 0x38, 0xe6, 0xa5, 0xa6, 0x21, 0x35,
    0x83, 0xea, 0xae, 0x5b, 0x5b, 0x75, 0x25, 0x84
};

static char randBytesForItemBytes[] = {
    0x40, 0xbc, 0xb6, 0x68, 0x62, 0x32, 0x9d, 0x74, 0x2f, 0x24, 0x5e, 0xdf,
    0x6f, 0x27, 0x88, 0x24, 0xaf, 0x9a, 0x0b, 0x93, 0x10, 0x63, 0x4f, 0x3d,
    0xaa, 0xf8, 0x89, 0x56, 0xa9, 0xca, 0x43, 0x35, 0x6a, 0xc1, 0x52, 0x6e,
    0xf6, 0xf8, 0xc7, 0x96, 0xf6, 0x09, 0x08, 0xb7, 0x42, 0x2c, 0x4a, 0xe7,
    0x4f, 0x48, 0x62, 0xce, 0x6d, 0xf3, 0x9a, 0x01, 0x1f, 0x3a, 0x94, 0x3a,
    0x7a, 0x5d, 0xff, 0xba, 0xdc, 0x01, 0xcd, 0xf4, 0xa2, 0x8b, 0x08, 0x6a,
    0xa5, 0xdb, 0x97, 0xfb, 0x7a, 0xd9, 0xdd, 0x5e, 0x59, 0xfa, 0x5d, 0xfe,
    0x0e, 0xd1, 0x4e, 0xbb, 0x0e, 0xb5, 0x0e, 0x9f, 0x4c, 0x41, 0x97, 0x21,
    0x0f, 0xd9, 0x7c, 0x34, 0x76, 0xad, 0x74, 0x6e, 0x71, 0x13, 0x6e, 0xc6,
    0x14, 0xff, 0x97, 0x1d, 0xea, 0xd3, 0xc1, 0x7e, 0xa0, 0xe1, 0x74, 0xb1,
    0x60, 0x2d, 0x3a, 0x1c, 0xae, 0xbd, 0x6a, 0xaf, 0x84, 0x3b, 0x8e, 0x5d,
    0x24, 0x12, 0xcd, 0x82, 0x4c, 0x3f, 0xcd, 0xf7, 0x2a, 0x3b, 0xb4, 0x1b,
    0x9b, 0x09, 0xe6, 0xa9, 0x87, 0x4e, 0xaf, 0x77, 0x9e, 0x4c, 0x86, 0x47,
    0x5d, 0x42, 0xab, 0x2d, 0x24, 0xfa, 0xd5, 0x1f, 0x2e, 0xd3, 0xf5, 0x3a,
    0x78, 0x9d, 0x01, 0x24, 0x22, 0x89, 0x4d, 0x4f, 0x9a, 0x24, 0x3e, 0x3c,
    0xba, 0xf1, 0x4d, 0x6b, 0xde, 0xbe, 0x2a, 0x6a, 0x71, 0x95, 0xe8, 0x63,
    0x0e, 0xfa, 0x05, 0x74, 0xae, 0xfb, 0xa9, 0x33, 0x20, 0x50, 0xa7, 0x19,
    0x2e, 0xa6, 0xf5, 0xa8, 0xab, 0x25, 0xe5, 0x27, 0x36, 0x53, 0xa8, 0x2c,
    0x7e, 0xd3, 0x6c, 0xe4, 0xac, 0xd7, 0x57, 0x73, 0x9b, 0xe2, 0xa5, 0x2c,
    0x96, 0xc0, 0x55, 0xb3, 0x7f, 0x7c, 0xf4, 0x8d, 0x57, 0x64, 0x20, 0xdd,
    0x52, 0x42, 0xa3, 0x78, 0xdf, 0xb0, 0x5f, 0x9a, 0x7e, 0x08, 0x87, 0xea,
    0xcc, 0x9c, 0x45, 0x51, 0x22, 0x44, 0xe1, 0x34, 0x83, 0xf4, 0xb6, 0xbd,
    0xc1, 0xb1, 0x25, 0xb9, 0xe2, 0xa7, 0x37, 0xda, 0x88, 0x51, 0x85, 0x92,
    0xd1, 0x1e, 0xe9, 0xb3, 0x2e, 0xb0, 0xf5, 0xe4, 0xec, 0xc1, 0x9b, 0x28,
    0x7c, 0xed, 0x19, 0x79, 0x74, 0xc2, 0x54, 0xdc, 0x0d, 0xb1, 0x28, 0xc3,
    0x65, 0x09, 0x55, 0x96, 0x12, 0x5f, 0xc1, 0xdc, 0x83, 0x3e, 0x8e, 0xad,
    0xa6, 0x30, 0x1b, 0x6b, 0x7d, 0x72, 0x2b, 0xb9, 0xfd, 0xaf, 0x7c, 0xe0,
    0x67, 0x0b, 0x71, 0x69, 0xba, 0xcf, 0x37, 0x13, 0x81, 0x9a, 0x75, 0x15,
    0x18, 0xb7, 0xef, 0xf0, 0x01, 0x73, 0xee, 0x8d, 0xa9, 0xad, 0xa1, 0x22,
    0x5e, 0x5a, 0x34, 0x2f, 0x98, 0x9a, 0x0b, 0xa6, 0xbb, 0x41, 0x78, 0xb5,
    0x0b, 0x56, 0xdb, 0x51, 0xc9, 0xbc, 0x8a, 0x38, 0x00, 0x98, 0xc2, 0xb8,
    0x9b, 0x16, 0xf3, 0x9d, 0x30, 0xfc, 0x8a, 0x3c, 0x1d, 0x50, 0x4c, 0x43,
    0x56, 0xa9, 0x54, 0x8a, 0xb9, 0xfa, 0x1f, 0xee, 0xac, 0x76, 0x0e, 0x1c,
    0x7a, 0x37, 0x24, 0xd2, 0xf4, 0x3c, 0x77, 0x7b, 0x64, 0xfc, 0xb5, 0xba,
    0x09, 0x61, 0x98, 0x10, 0x7e, 0xac, 0x9a, 0xb6, 0x0e, 0x34, 0xb4, 0x91,
    0x3d, 0x24, 0x44, 0xbd, 0xdd, 0xb0, 0x46, 0x62, 0x37, 0x50, 0xa1, 0x43,
    0xb4, 0xab, 0x87, 0x6b, 0xcd, 0xa9, 0x27, 0x43, 0x0f, 0xdb, 0xf1, 0x8c,
    0xdc, 0xf5, 0xe4, 0x6d, 0xd6, 0x83, 0xdb, 0xff, 0xda, 0x4d, 0xcb, 0xc5,
    0x81, 0x43, 0x90, 0x31, 0xac, 0x98, 0x2c, 0x06, 0x55, 0xb1, 0x33, 0xad,
    0x9c, 0xd5, 0x95, 0x00, 0x16, 0x79, 0x1c, 0x0b, 0x9e, 0x45, 0x13, 0x7d,
    0x31, 0x68, 0xd8, 0xc8, 0x37, 0x92, 0x2d, 0x88, 0x5c, 0x6c, 0xc9, 0x2b,
    0x59, 0x3c, 0x24, 0x97, 0x2c, 0x6b, 0x98, 0x6d, 0xfd, 0xc6, 0x34, 0x01,
    0x6d, 0xb6, 0x61, 0x82, 0x84, 0x26, 0x4c, 0xcc
};

static char ownershipSignature_nonceBytes[] = {
    0xd7, 0x31, 0x45, 0x85, 0x09, 0x93, 0x84, 0x5f, 0x5b, 0x10, 0x36, 0x3a,
    0xd2, 0xd4, 0xb3, 0xc5
};

static int64_t ownershipSignature_timestamp = 1426423058651;

static char ownershipSignature_createOp_signatureBytes[] = {
    0x2d, 0x7b, 0xf3, 0xd1, 0x48, 0xba, 0xa3, 0x7a, 0xed, 0x75, 0x91, 0xe4,
    0x55, 0x12, 0x63, 0x17, 0x74, 0x62, 0x88, 0xff, 0x31, 0xac, 0xb8, 0x3b,
    0x9f, 0x0f, 0x74, 0x94, 0x13, 0x7f, 0x44, 0xaa, 0xfb, 0x21, 0xb0, 0x20,
    0x6d, 0xf0, 0x5d, 0xc1, 0xde, 0x4f, 0x40, 0x22, 0xf2, 0x96, 0x62, 0x08,
    0xdd, 0x64, 0x18, 0x39, 0xa4, 0x48, 0x19, 0x82, 0x99, 0x63, 0x57, 0x76,
    0x1f, 0x64, 0xa3, 0x06
};

static char ownershipSignature_listOp_signatureBytes[] = {
};

static char ownershipSignature_deleteOp_signatureBytes[] = {
};




// =============================================================================================================
#pragma mark - Utilities -
// =============================================================================================================


#define dataWithBytes(bytes) [NSData dataWithBytes:bytes length:sizeof(bytes)]
#define quidWithBytes(bytes) [[QredoQUID alloc] initWithQUIDData:[NSData dataWithBytes:bytes length:sizeof(bytes)]]



// =============================================================================================================
#pragma mark - Test case -
// =============================================================================================================


@interface OwnershipSignatureTests : XCTestCase

@property (nonatomic) QredoED25519SigningKey *key;

@property (nonatomic) NSData *nonce;
@property (nonatomic) int64_t timestamp;

@property (nonatomic) NSData *expectedSignature;

@property (nonatomic) QLFOwnershipSignature *ownershipSignatureUnderTest;
@property (nonatomic) NSError *error;

@end

@implementation OwnershipSignatureTests

// -------------------------------------------------------------------------------------------------------------
#pragma mark - Setup

- (void)setUp
{
    [super setUp];
    
    self.key = [[CryptoImplV1 sharedInstance] qredoED25519SigningKeyWithSeed:dataWithBytes(privateKeyBytes)];
    NSAssert([self.key.verifyKey.data isEqual:dataWithBytes(publicKeyBytes)], @"The created key is malformed.");
    
    self.nonce = dataWithBytes(ownershipSignature_nonceBytes);
    self.timestamp = ownershipSignature_timestamp;
    
    self.ownershipSignatureUnderTest = nil;
    self.error = nil;
}

- (void)tearDown
{
    self.ownershipSignatureUnderTest = nil;
    self.error = nil;
    [super tearDown];
}

// -------------------------------------------------------------------------------------------------------------
#pragma mark - Tests

- (void)testCreateOperation
{
    QLFOperationType *operationType = [QLFOperationType operationCreate];
    
    QLFEncryptedVaultItemMetaData *metadata
    = [QLFEncryptedVaultItemMetaData encryptedVaultItemMetaDataWithVaultId:quidWithBytes(vaultIdBytes)
                                                                sequenceId:quidWithBytes(sequenceIdBytes)
                                                             sequenceValue:1
                                                                    itemId:quidWithBytes(itemIdvalBytes)
                                                          encryptedHeaders:dataWithBytes(randBytesForMetaBytes)];
    
    QLFEncryptedVaultItem *vaultItem
    = [QLFEncryptedVaultItem encryptedVaultItemWithMeta:metadata
                                         encryptedValue:dataWithBytes(randBytesForItemBytes)];

    NSData *expectedSignature = dataWithBytes(ownershipSignature_createOp_signatureBytes);
    [self assertOwnershipSignatureWithOperationType:operationType data:vaultItem exectedSiganture:expectedSignature];
}

- (void)testListOperation
{
    QLFOperationType *operationType = [QLFOperationType operationList];
    NSData *expectedSignature = dataWithBytes(ownershipSignature_listOp_signatureBytes);
//    [self assertOwnershipSignatureWithOperationType:operationType data:<#data#> exectedSiganture:expectedSignature];
}

- (void)testDeleteOperation
{
    QLFOperationType *operationType = [QLFOperationType operationDelete];
    NSData *expectedSignature = dataWithBytes(ownershipSignature_deleteOp_signatureBytes);
    
    //    [self assertOwnershipSignatureWithOperationType:operationType data:<#data#> exectedSiganture:expectedSignature];
}


// -------------------------------------------------------------------------------------------------------------
#pragma mark - Utils

- (void)createOwnershipSignatureWithOperationType:(QLFOperationType *)operationType data:(id<QredoMarshallable>)data
{
    NSError *error = nil;
    self.ownershipSignatureUnderTest = [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoED25519Singer alloc] initWithSigningKey:self.key]
                                                                             operationType:operationType
                                                                                      data:data
                                                                                     nonce:self.nonce
                                                                                 timestamp:self.timestamp
                                                                                     error:&error];
    self.error = error;
}

- (void)assertOwnershipSignatureWithOperationType:(QLFOperationType *)operationType
                                             data:(id<QredoMarshallable>)data
                                 exectedSiganture:(NSData *)expectedSiganture
{
    [self createOwnershipSignatureWithOperationType:operationType data:data];
    
    XCTAssertNotNil(self.ownershipSignatureUnderTest.signature);
    XCTAssertNil(self.error);
    
    XCTAssertEqualObjects(operationType, self.ownershipSignatureUnderTest.op);
    XCTAssertEqualObjects(self.nonce, self.ownershipSignatureUnderTest.nonce);
    XCTAssertEqual(self.timestamp, self.ownershipSignatureUnderTest.timestamp);
    
    XCTAssertEqualObjects(expectedSiganture, self.ownershipSignatureUnderTest.signature);
    
}

- (QredoED25519SigningKey *)signingKeyWithSigningKeyData:(NSData *)signingKeyData publicKeyData:(NSData *)publicKeyData
{
    QredoED25519VerifyKey *veryfyKey = [[QredoED25519VerifyKey alloc] initWithKeyData:publicKeyData];
    
    return [[QredoED25519SigningKey alloc] initWithSeed:nil
                                                keyData:signingKeyData
                                              verifyKey:veryfyKey];
}


@end




