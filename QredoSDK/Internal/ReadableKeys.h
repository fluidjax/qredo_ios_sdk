//
//  ReadableKeys.h
//  KeyWordConverter
//
//  Created by Christopher Morris on 03/05/2016.
//  Based on RFC1751 -  D. McDonald Dec 94


#import <Foundation/Foundation.h>

@interface ReadableKeys : NSObject

+(NSString *)rfc1751Key2Eng:(NSData *)key;
+(NSData *)rfc1751Eng2Key:(NSString *)english;


//Non RFC1751 compliant
//Allow generate of words without parity check
//without any key length restrictions

+(NSData *)eng2Key:(NSString *)english;
+(NSString *)key2Eng:(NSData *)key;


+(NSData *)randomKey:(NSUInteger)size;
+(NSString*)dataToHexString:(NSData*)data;

@end
