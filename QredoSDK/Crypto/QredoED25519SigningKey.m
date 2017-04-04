/* HEADER GOES HERE */
#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"


@interface QredoED25519SigningKey ()
@property (nonatomic,copy) NSData *seed;
@property (nonatomic,copy) NSData *data;
@property (nonatomic) QredoED25519VerifyKey *verifyKey;
@end

@implementation QredoED25519SigningKey

-(instancetype)initWithSeed:(NSData *)seed keyData:(NSData *)data verifyKey:(QredoED25519VerifyKey *)verifyKey {
    self = [self init];
    
    if (self){
        _seed = seed;
        _data = data;
        _verifyKey = verifyKey;
    }
    
    return self;
}


-(NSData *)convertKeyToNSData {
    return _data;
}


@end
