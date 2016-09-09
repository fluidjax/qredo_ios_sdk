/* HEADER GOES HERE */
#import "QredoED25519VerifyKey.h"


@interface QredoED25519VerifyKey ()
@property (nonatomic,copy) NSData *data;
@end

@implementation QredoED25519VerifyKey

-(instancetype)initWithKeyData:(NSData *)data {
    self = [self init];
    
    if (self){
        _data = data;
    }
    
    return self;
}


-(NSData *)convertKeyToNSData {
    return _data;
}


@end
