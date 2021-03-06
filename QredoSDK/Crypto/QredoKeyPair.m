/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoKeyPair.h"

@interface QredoKeyPair ()

//'Private' setters
@property (nonatomic,strong) QredoPublicKey *publicKey;
@property (nonatomic,strong) QredoPrivateKey *privateKey;

@end

@implementation QredoKeyPair

-(instancetype)init {
    //We do not want to be initialised via the NSObect init method as we require arguments (no public setter properties)
    NSAssert(NO,@"Use -initWithPublicKey:");
    return nil;
}


-(instancetype)initWithPublicKey:(QredoPublicKey *)publicKey privateKey:(QredoPrivateKey *)privateKey {
    if (!publicKey){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Public key argument is nil"]
                                     userInfo:nil];
    }
    
    if (!privateKey){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Private key argument is nil"]
                                     userInfo:nil];
    }
    
    self = [super init];
    
    if (self){
        _publicKey = publicKey;
        _privateKey = privateKey;
    }
    
    return self;
}


@end
