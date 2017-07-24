/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "CryptoImpl.h"

@interface CryptoImplV1 : NSObject <CryptoImpl>
+(instancetype)sharedInstance;
-(instancetype) init __attribute__((unavailable("init not available")));  
@end
