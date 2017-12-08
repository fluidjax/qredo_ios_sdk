/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"


@interface QredoED25519SigningKey ()
@property (nonatomic) QredoED25519VerifyKey *verifyKey;
@end

@implementation QredoED25519SigningKey


+(instancetype)signingKeyWithData:(NSData *)data verifyKey:(QredoED25519VerifyKey *)verifyKey {
    return [[self alloc] initWithSignKeyData:data verifyKey:verifyKey];
}


-(instancetype)initWithSignKeyData:(NSData *)data verifyKey:(QredoED25519VerifyKey *)verifyKey {
    self = [self init];
    
    if (self){
        self.data = data;
        _verifyKey = verifyKey;
    }
    
    return self;
}


@end
