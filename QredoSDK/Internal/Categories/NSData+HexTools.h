//
//  NSData+HexTools.h
//  QredoSDK
//
//  Created by Christopher Morris on 21/07/2017.
//
//

#import <Foundation/Foundation.h>

@interface NSData (HexTools)

+(instancetype)dataWithHexString:(NSString *)hexString;
-(NSString *)hexadecimalString;

@end
