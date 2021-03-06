/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoDhPublicKey.h"
#import "QredoMacros.h"


@implementation QredoDhPublicKey

-(instancetype)init {
    //We do not want to be initialised via the NSObect init method as we require arguments (no public setter properties)
    NSAssert(NO,@"Use -initWithData:");
    return nil;
}


-(instancetype)initWithData:(NSData *)data {
    GUARD(data,@"Data argument is nil");
    self = [super init];
    if (self){
        self.data = data;
    }
    return self;
}


@end
