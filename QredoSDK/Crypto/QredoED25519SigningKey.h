/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoPrivateKey.h"

@class QredoED25519VerifyKey;

@interface QredoED25519SigningKey :QredoPrivateKey
@property (nonatomic,readonly) QredoED25519VerifyKey *verifyKey;
+(instancetype)signingKeyWithData:(NSData *)data verifyKey:(QredoED25519VerifyKey *)verifyKey;
@end
