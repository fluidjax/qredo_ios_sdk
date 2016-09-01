/* HEADER GOES HERE */
#import "QredoKey.h"

@interface QredoED25519VerifyKey :QredoKey
@property (nonatomic,readonly,copy) NSData *data;
-(instancetype)initWithKeyData:(NSData *)data;
@end
