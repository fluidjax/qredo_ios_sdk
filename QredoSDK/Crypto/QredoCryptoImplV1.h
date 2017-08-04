/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoCryptoImpl.h"

@interface QredoCryptoImplV1 : NSObject <QredoCryptoImpl>
+(instancetype)sharedInstance;
-(instancetype) init __attribute__((unavailable("init not available")));  
@end
