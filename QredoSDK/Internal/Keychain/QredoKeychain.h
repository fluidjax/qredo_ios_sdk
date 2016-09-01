/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "CryptoImpl.h"
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

//used in tests only
-(instancetype)initWithData:(NSData *)serializedData;

-(NSData *)data;
-(void)generateNewKeys:(QredoUserCredentials *)userCredentials;



@end
