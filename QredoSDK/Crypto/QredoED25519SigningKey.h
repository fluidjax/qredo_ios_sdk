/* HEADER GOES HERE */
#import "QredoPrivateKey.h"

@class QredoED25519VerifyKey;

@interface QredoED25519SigningKey :QredoPrivateKey
@property (nonatomic,readonly) QredoED25519VerifyKey *verifyKey;
-(instancetype)initWithSignKeyData:(NSData *)data verifyKey:(QredoED25519VerifyKey *)verifyKey;
@end
