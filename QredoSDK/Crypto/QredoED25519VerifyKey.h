/* HEADER GOES HERE */
#import "QredoPublicKey.h"

@interface QredoED25519VerifyKey :QredoPublicKey
@property (nonatomic,readonly,copy) NSData *data;
-(instancetype)initWithKeyData:(NSData *)data;
@end
