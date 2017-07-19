/* HEADER GOES HERE */

#import "QredoSecKeyRefPair.h"
#import "QredoMacros.h"

@interface QredoSecKeyRefPair ()

@property (nonatomic,assign) SecKeyRef publicKeyRef;
@property (nonatomic,assign) SecKeyRef privateKeyRef;

@end


@implementation QredoSecKeyRefPair

-(instancetype)initWithPublicKeyRef:(SecKeyRef)publicKeyRef privateKeyRef:(SecKeyRef)privateKeyRef {
    self = [super init];
    
    if (self){
        
        GUARD(publicKeyRef,@"Public key ref argument is nil");
        GUARD(privateKeyRef,@"Private key ref argument is nil");
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
