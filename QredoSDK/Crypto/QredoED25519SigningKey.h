/* HEADER GOES HERE */
#import "QredoKey.h"

@class QredoED25519VerifyKey;

@interface QredoED25519SigningKey :QredoKey
@property (nonatomic,readonly,copy) NSData *data;
@property (nonatomic,readonly) QredoED25519VerifyKey *verifyKey;
-(instancetype)initWithSeed:(NSData *)seed keyData:(NSData *)data verifyKey:(QredoED25519VerifyKey *)verifyKey;
@end
