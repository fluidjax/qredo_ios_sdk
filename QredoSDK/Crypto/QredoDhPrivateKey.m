/* HEADER GOES HERE */

#import "QredoDhPrivateKey.h"

@interface QredoDhPrivateKey ()

@property (nonatomic,copy) NSData *data;

@end

@implementation QredoDhPrivateKey

-(instancetype)init {
    //We do not want to be initialised via the NSObect init method as we require arguments (no public setter properties)
    NSAssert(NO,@"Use -initWithData:");
    return nil;
}

-(instancetype)initWithData:(NSData *)data {
    if (!data){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Data argument is nil"]
                                     userInfo:nil];
    }
    
    self = [super init];
    
    if (self){
        _data = data;
    }
    
    return self;
}

@end