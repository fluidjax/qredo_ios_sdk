//
//  QredoMemoizationTests.m
//  QredoSDK
//
//  Created by Christopher Morris on 05/09/2017.
//
//

#import <XCTest/XCTest.h>
#import "QredoCryptoKeychain.h"
#import "QredoXCTestCase.h"
#import "QredoUserCredentials.h"
#import "NSData+HexTools.h"
#import "QredoRendezvousCrypto.h"

@interface QredoMemoizationTests : QredoXCTestCase
@property (strong) QredoCryptoKeychain *keychain;
@end

@implementation QredoMemoizationTests

- (void)setUp {
    
    [super setUp];
    self.keychain = [QredoCryptoKeychain standardQredoCryptoKeychain];
    [self.keychain purgeMemoizationCache];

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



-(void)testUserUnlock{
    [self memoCheckHits:0 trys:0];
    QredoKeyRef *userUnlockKeyRef = [self generateUnlockKeyRef];
    [self memoCheckHits:0 trys:1];
    QredoKeyRef *userUnlockKeyRef2 = [self generateUnlockKeyRef];
    [self memoCheckHits:1 trys:2];
    QredoKeyRef *userUnlockKeyRef3 = [self generateUnlockKeyRef];
    [self memoCheckHits:2 trys:3];
}


-(void)testMasterUnlock{
    [self memoCheckHits:0 trys:0];
    QredoKeyRef *masterKeyRef = [self generateMasterKeyRef];
    [self memoCheckHits:0 trys:2];
    QredoKeyRef *masterKeyRef2 = [self generateMasterKeyRef];
    [self memoCheckHits:2 trys:4];
    QredoKeyRef *masterKeyRef3 = [self generateMasterKeyRef];
    [self memoCheckHits:4 trys:6];
}



-(void)testGenerateMasterKeyWithTagAndAppId {
    [self memoCheckHits:0 trys:0];
    [self masterKeyWithTagAndAppID];
    [self memoCheckHits:0 trys:1];
    [self masterKeyWithTagAndAppID];
    [self memoCheckHits:1 trys:2];
    [self masterKeyWithTagAndAppID];
    [self memoCheckHits:2 trys:3];
    
}



-(void)masterKeyWithTagAndAppID{
    QredoRendezvousCrypto *rendCrypto = [QredoRendezvousCrypto instance];
    NSString *tag   = @"ABC";
    NSString *appId = @"123";
    QredoKeyRef *res = [rendCrypto masterKeyRefWithTag:tag appId:appId];
    NSData *correct = [NSData dataWithHexString:@"b7dd94ba 22f5eba2 a1010144 00e65c11 0d3e69b7 098a5b88 9d44cea0 e96c944f"];
    XCTAssertTrue([self.keychain keyRef:res isEqualToData:correct],@"Master Key derived from Tag is incorrect");
}



-(QredoKeyRef*)generateUnlockKeyRef{
    NSString *TEST_USER_SECRET      = @"This is a secret";
    NSString *APPLICATION_ID         = @"test";
    NSString *TEST_USER_ID          = @"TEST-USER-ID";
    QredoUserCredentials *userCredentials = [[QredoUserCredentials alloc] initWithAppId:APPLICATION_ID
                                                                                 userId:TEST_USER_ID
                                                                             userSecure:TEST_USER_SECRET];
    NSData *TEST_UNLOCK_KEY = [NSData dataWithHexString:@"d54dce9e8746cb954b529134db880355882c4cc8791550673611d857c5c98184"];
    NSData *expectedMaster  = [NSData dataWithHexString:@"874bcf17f8690876a299fa272468f052e743e225bc22c05"
                               "a3bd6041df346ba1d1048c4853bcc52f7032d875a15abd877c9e0ce9c55f5989f0f912234316380914c163f6fcfbf87"
                               "be747134ef3d5744cd8bbbae0f290734b54581a0ddb2c5143bd163a47d7ab697301683b997be8cdc4871c2c6573cb02"
                               "6d9ec3907a8ed3ebd5fc19e77561c91c4ca25b96e6e37e1825f00d262ea261b69a49aaeffe63b74e114fb7d4f0e9a94ef"
                               "86159a7c547ecb42e43d74657b39c56c7457d90c901b9397ead6b4c04dca2500fb9ebb8aa78fcdd54e17b207c062fa2da"
                               "b4ec0fc04cf7a2f6d1b7d266f6d434a1cf27f41f7238711136d0d5d6ba67c7158e0a7a83a9b556a85"];
    QredoKeyRef *userUnlockKeyRef = [userCredentials userUnlockKeyRef];
    XCTAssertNotNil(userUnlockKeyRef);
    XCTAssertTrue([[userUnlockKeyRef debugValue] isEqualToData:[userUnlockKeyRef debugValue]],@"Memoization didnt return correct value");
    return userUnlockKeyRef;
}




-(QredoKeyRef*)generateMasterKeyRef{
    NSString *TEST_USER_SECRET      = @"This is a secret";
    NSString *APPLICATION_ID         = @"test";
    NSString *TEST_USER_ID          = @"TEST-USER-ID";
    QredoUserCredentials *userCredentials = [[QredoUserCredentials alloc] initWithAppId:APPLICATION_ID
                                                                                 userId:TEST_USER_ID
                                                                             userSecure:TEST_USER_SECRET];
    NSData *TEST_UNLOCK_KEY = [NSData dataWithHexString:@"d54dce9e8746cb954b529134db880355882c4cc8791550673611d857c5c98184"];
    NSData *expectedMaster  = [NSData dataWithHexString:@"874bcf17f8690876a299fa272468f052e743e225bc22c05"
                               "a3bd6041df346ba1d1048c4853bcc52f7032d875a15abd877c9e0ce9c55f5989f0f912234316380914c163f6fcfbf87"
                               "be747134ef3d5744cd8bbbae0f290734b54581a0ddb2c5143bd163a47d7ab697301683b997be8cdc4871c2c6573cb02"
                               "6d9ec3907a8ed3ebd5fc19e77561c91c4ca25b96e6e37e1825f00d262ea261b69a49aaeffe63b74e114fb7d4f0e9a94ef"
                               "86159a7c547ecb42e43d74657b39c56c7457d90c901b9397ead6b4c04dca2500fb9ebb8aa78fcdd54e17b207c062fa2da"
                               "b4ec0fc04cf7a2f6d1b7d266f6d434a1cf27f41f7238711136d0d5d6ba67c7158e0a7a83a9b556a85"];
    QredoKeyRef *userUnlockKeyRef = [userCredentials userUnlockKeyRef];
    XCTAssertNotNil(userUnlockKeyRef);
    XCTAssertTrue([[userUnlockKeyRef debugValue] isEqualToData:[userUnlockKeyRef debugValue]],@"Memoization didnt return correct value");
    
    
    QredoKeyRef *masterKeyRef = [userCredentials masterKeyRef:userUnlockKeyRef];
    XCTAssertTrue([[userUnlockKeyRef debugValue] isEqualToData:TEST_UNLOCK_KEY],@"User Unlock Key not correctly derived");
    XCTAssertTrue([[masterKeyRef debugValue] isEqualToData:expectedMaster],@"Master Key not correctly derived");
    
    return masterKeyRef;
}

-(void)memoCheckHits:(int)hits trys:(int)trys{
    int actualHits = self.keychain.memoizationHits;
    int actualTrys = self.keychain.memoizationTrys;
    
    XCTAssertTrue(actualTrys == trys,@"Memoization trys is %i should be %i", actualTrys, trys);
    XCTAssertTrue(actualHits == hits,@"Memoization hits is %i should be %i", actualHits, hits);
}


@end
