//
//  QredoUserCredentials.m
//  QredoSDK
//
//  Created by Christopher Morris on 13/11/2015.
//
//

#import <XCTest/XCTest.h>
#import "QredoUserCredentials.h"
#import "NSData+ParseHex.h"

@interface QredoUserCredentialsTests : XCTestCase

@end

@implementation QredoUserCredentialsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}



-(void)testGetMasterUnlockKey{
    
    NSString *TEST_USER_SECRET      = @"This is a secret";
    NSString *applicationId         = @"test";
    NSString *TEST_USER_ID          = @"TEST-USER-ID";

    
    QredoUserCredentials *userCredentials = [[QredoUserCredentials alloc] initWithAppId:applicationId
                                                                                          userId:TEST_USER_ID
                                                                                      userSecure:TEST_USER_SECRET];

    
    NSData *TEST_UNLOCK_KEY = [NSData dataWithHexString:@"d54dce9e8746cb954b529134db880355882c4cc8791550673611d857c5c98184"];
    
    NSData *expectedMaster  = [NSData dataWithHexString:@"874bcf17f8690876a299fa272468f052e743e225bc22c05"
                               "a3bd6041df346ba1d1048c4853bcc52f7032d875a15abd877c9e0ce9c55f5989f0f912234316380914c163f6fcfbf87"
                               "be747134ef3d5744cd8bbbae0f290734b54581a0ddb2c5143bd163a47d7ab697301683b997be8cdc4871c2c6573cb02"
                               "6d9ec3907a8ed3ebd5fc19e77561c91c4ca25b96e6e37e1825f00d262ea261b69a49aaeffe63b74e114fb7d4f0e9a94ef"
                               "86159a7c547ecb42e43d74657b39c56c7457d90c901b9397ead6b4c04dca2500fb9ebb8aa78fcdd54e17b207c062fa2da"
                               "b4ec0fc04cf7a2f6d1b7d266f6d434a1cf27f41f7238711136d0d5d6ba67c7158e0a7a83a9b556a85"];
    

    NSData *userUnlockKey = [userCredentials userUnlockKey];
    NSData *masterKey = [userCredentials masterKey:userUnlockKey];
    
    XCTAssertTrue([userUnlockKey isEqualToData:TEST_UNLOCK_KEY], @"User Unlock Key not correctly derived");
    XCTAssertTrue([masterKey isEqualToData:expectedMaster], @"Master Key not correctly derived");
    
    
}


-(void)testGetMasterFromUserUnlock{
    QredoUserCredentials *userCredentials = [[QredoUserCredentials alloc] init];
    
    
    NSData *userUnlockKey = [NSData dataWithHexString:@"d54dce9e8746cb954b529134db880355882c4cc8791550673611d857c5c98184"];
    
    NSData *expectedMaster  = [NSData dataWithHexString:@"874bcf17f8690876a299fa272468f052e743e225bc22c05"
                               "a3bd6041df346ba1d1048c4853bcc52f7032d875a15abd877c9e0ce9c55f5989f0f912234316380914c163f6fcfbf87"
                               "be747134ef3d5744cd8bbbae0f290734b54581a0ddb2c5143bd163a47d7ab697301683b997be8cdc4871c2c6573cb02"
                               "6d9ec3907a8ed3ebd5fc19e77561c91c4ca25b96e6e37e1825f00d262ea261b69a49aaeffe63b74e114fb7d4f0e9a94ef"
                               "86159a7c547ecb42e43d74657b39c56c7457d90c901b9397ead6b4c04dca2500fb9ebb8aa78fcdd54e17b207c062fa2da"
                               "b4ec0fc04cf7a2f6d1b7d266f6d434a1cf27f41f7238711136d0d5d6ba67c7158e0a7a83a9b556a85"];
    
    NSData *masterKey = [userCredentials masterKey:userUnlockKey];
    XCTAssertTrue([masterKey isEqualToData:expectedMaster], @"Master Key not correctly derived using HKDF from unlockKey");
    
}


- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



@end
