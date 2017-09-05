/* HEADER GOES HERE */
#import <XCTest/XCTest.h>
#import "QredoUserCredentials.h"
#import "NSData+HexTools.h"
#import "QredoXCTestCase.h"
#import "QredoCryptoKeychain.h"

@interface QredoUserCredentialsTests :QredoXCTestCase

@end

@implementation QredoUserCredentialsTests

-(void)setUp {
    [super setUp];
    //Put setup code here. This method is called before the invocation of each test method in the class.
}



-(void)testSha1{
    QredoUserCredentials *creds = [[QredoUserCredentials alloc] init];
    NSData *output = [creds sha1WithString:@"abc"];
    NSData *expected = [NSData dataWithHexString:@"a9993e364706816aba3e25717850c26c9cd0d89d"];
    XCTAssert([expected isEqualToData:output],@"Sha1 incorrect value");
}


-(void)testGetMasterUnlockKey {
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
    QredoKeyRef *masterKeyRef = [userCredentials masterKeyRef:userUnlockKeyRef];
    
    XCTAssertTrue([[userUnlockKeyRef debugValue] isEqualToData:TEST_UNLOCK_KEY],@"User Unlock Key not correctly derived");
    XCTAssertTrue([[masterKeyRef debugValue] isEqualToData:expectedMaster],@"Master Key not correctly derived");
}


-(void)testDataToHexString {
    QredoUserCredentials *userCredentials = [[QredoUserCredentials alloc] init];
    NSData *dataInput = [NSData dataWithHexString:@"cafebabe"];
    NSString *hexOutput = [userCredentials dataToHexString:dataInput];
    
    XCTAssertTrue([hexOutput isEqualToString:@"CAFEBABE"]);
}



-(void)testGetMasterFromUserUnlock {
    QredoUserCredentials *userCredentials = [[QredoUserCredentials alloc] init];
    
    NSData *expectedMaster  = [NSData dataWithHexString:@"874bcf17f8690876a299fa272468f052e743e225bc22c05"
                               "a3bd6041df346ba1d1048c4853bcc52f7032d875a15abd877c9e0ce9c55f5989f0f912234316380914c163f6fcfbf87"
                               "be747134ef3d5744cd8bbbae0f290734b54581a0ddb2c5143bd163a47d7ab697301683b997be8cdc4871c2c6573cb02"
                               "6d9ec3907a8ed3ebd5fc19e77561c91c4ca25b96e6e37e1825f00d262ea261b69a49aaeffe63b74e114fb7d4f0e9a94ef"
                               "86159a7c547ecb42e43d74657b39c56c7457d90c901b9397ead6b4c04dca2500fb9ebb8aa78fcdd54e17b207c062fa2da"
                               "b4ec0fc04cf7a2f6d1b7d266f6d434a1cf27f41f7238711136d0d5d6ba67c7158e0a7a83a9b556a85"];
    
    
    QredoKeyRef *userUnlockKeyRef = [QredoKeyRef keyRefWithKeyHexString:@"d54dce9e8746cb954b529134db880355882c4cc8791550673611d857c5c98184"];
    QredoKeyRef *masterKeyRef = [userCredentials masterKeyRef:userUnlockKeyRef];
    
    
    
    XCTAssertTrue([[masterKeyRef debugValue] isEqualToData:expectedMaster],@"Master Key not correctly derived using HKDF from unlockKey");
}


-(void)tearDown {
    //Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


@end
