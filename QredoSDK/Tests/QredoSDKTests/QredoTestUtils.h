/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoPrivate.h"

extern NSTimeInterval qtu_defaultTimeout;

extern NSString *k_APPID;
extern NSString *k_APPSECRET;
extern NSString *k_USERID;


@interface NSData (QredoTestUtils)

+ (NSData*)qtu_dataWithRandomBytesOfLength:(int)length;

@end




