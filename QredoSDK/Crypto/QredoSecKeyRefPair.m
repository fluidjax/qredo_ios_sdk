/* HEADER GOES HERE */

#import "QredoSecKeyRefPair.h"

@interface QredoSecKeyRefPair ()

@property (nonatomic,assign) SecKeyRef publicKeyRef;
@property (nonatomic,assign) SecKeyRef privateKeyRef;

@end


@implementation QredoSecKeyRefPair

-(instancetype)initWithPublicKeyRef:(SecKeyRef)publicKeyRef privateKeyRef:(SecKeyRef)privateKeyRef {
    self = [super init];
    
    if (self){
        if (!publicKeyRef){
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Public key ref argument is nil"]
                                         userInfo:nil];
        }
        
        if (!privateKeyRef){
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Private key ref argument is nil"]
                                         userInfo:nil];
        }
        
        _publicKeyRef = publicKeyRef;
        _privateKeyRef = privateKeyRef;
    }
    
    return self;
}

-(void)dealloc {
    if (_publicKeyRef){
        CFRelease(_publicKeyRef);
        _publicKeyRef = nil;
    }
    
    if (_privateKeyRef){
        CFRelease(_privateKeyRef);
        _publicKeyRef = nil;
    }
}

@end
