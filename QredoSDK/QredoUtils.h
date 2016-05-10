//
//  QredoUtils.h
//  QredoSDK
//
//  Created by Christopher Morris on 10/05/2016.
//
//

#import <Foundation/Foundation.h>

@interface QredoUtils : NSObject




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
