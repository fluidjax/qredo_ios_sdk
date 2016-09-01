/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface NSData (ParseHex)

+ (instancetype)dataWithHexString:(NSString *)hexString;

@end
