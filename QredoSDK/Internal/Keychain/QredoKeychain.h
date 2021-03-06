/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoVaultCrypto.h"

@class QredoUserCredentials;

extern NS_ENUM (NSInteger,QredoCredentialType) {
    QredoCredentialTypeNoCredential = 0,
    QredoCredentialTypePIN = 1,
    QredoCredentialTypePattern = 2,
    QredoCredentialTypeFingerprint = 3,
    QredoCredentialTypePassword = 4,
    QredoCredentialTypePassphrase = 5,
    QredoCredentialTypeRandomBytes = 6
};

@interface QredoKeychain :NSObject

@property QLFOperatorInfo *operatorInfo;
@property QredoVaultKeys *systemVaultKeys;
@property QredoVaultKeys *defaultVaultKeys;

-(instancetype)initWithOperatorInfo:(QLFOperatorInfo *)operatorInfo;
-(NSData *)masterKeyData;
-(void)generateNewKeys:(QredoUserCredentials *)userCredentials;

//used in tests only
-(instancetype)initWithData:(NSData *)serializedData;

@end
