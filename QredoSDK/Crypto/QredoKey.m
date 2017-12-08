/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoKey.h"
#import "NSData+HexTools.h"
#import "QredoMacros.h"

@implementation QredoKey



+(instancetype)keyWithData:(NSData *)keydata{
    return [[self alloc] initWithData:keydata];
}

+(instancetype)keyWithHexString:(NSString *)hexString{
    return [[self alloc] initWithHexString:hexString];
}



-(instancetype)initWithData:(NSData *)data {
    GUARD(data,@"Data argument is nil");
    GUARD(data.length>0,@"Key is 0 bytes");
    self = [self init];
    
    if (self){
        _data = data;
    }
    return self;
}


-(instancetype)initWithHexString:(NSString *)hexString{
    self = [self init];
    if (self){
        _data = [NSData dataWithHexString:hexString];
    }
    return self;
}


-(NSData *)bytes {
    return _data;
}


-(int)length{
    return (int)self.bytes.length;
}



-(BOOL)isEqual:(id)other{
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
     return [self isEqualToKey:other];
}

- (BOOL)isEqualToKey:(QredoKey *)otherKey {
    if (self == otherKey)
        return YES;
    if (![self.bytes isEqualToData:otherKey.bytes])
        return NO;
    return YES;
}


@end
