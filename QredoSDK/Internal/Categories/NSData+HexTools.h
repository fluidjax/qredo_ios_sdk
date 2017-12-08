/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/




#import <Foundation/Foundation.h>

@interface NSData (HexTools)

+(instancetype)dataWithHexString:(NSString *)hexString;
-(NSString *)hexadecimalString;

@end
