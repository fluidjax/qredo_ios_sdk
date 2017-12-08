/* HEADER GOES HERE */


#import <Foundation/Foundation.h>

@interface NSData (HexTools)

+(instancetype)dataWithHexString:(NSString *)hexString;
-(NSString *)hexadecimalString;

@end
