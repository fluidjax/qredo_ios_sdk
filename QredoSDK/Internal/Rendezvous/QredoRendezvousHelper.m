/* HEADER GOES HERE */
#import "QredoRendezvousHelper_Private.h"
#import "QredoLoggerPrivate.h"

@implementation QredoAbstractRendezvousHelper

-(instancetype)initWithCrypto:(id<QredoCryptoImpl>)crypto {
    self = [super init];
    
    if (self){
        NSAssert(crypto,@"A crypto implementation has not been provided.");
        _qredoCryptoImpl = crypto;
    }
    
    return self;
}


@end

void updateErrorWithQredoRendezvousHelperError(NSError                    **error,
                                               QredoRendezvousHelperError errorCode,
                                               NSDictionary               *userInfo) {
    if (error){
        *error = [NSError errorWithDomain:QredoRendezvousHelperErrorDomain code:errorCode userInfo:userInfo];
    }
}
