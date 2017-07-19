/* HEADER GOES HERE */
#import "QredoDhPublicKey.h"
#import "QredoMacros.h"

@interface QredoDhPublicKey ()

@property (nonatomic,copy) NSData *data;

@end

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
        _data = data;
    }
    return self;
}


@end
