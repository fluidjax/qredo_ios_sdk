/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoLogger.h"



@interface QredoLogger ()


+(NSString *)extractClassName:(NSString *)prettyFunction;
+(BOOL)isClassOfInterest:(NSString *)className;
+(NSData *)NSDataFromHexString:(NSString *)string;
+(NSString *)hexRepresentationOfNSData:(NSData *)data;
+(NSString *)printBytesAsHex:(const unsigned char *)bytes numberOfBytes:(const unsigned int)numberOfBytes;
+(NSString *)stringFromOSStatus:(OSStatus)osStatus;
+(void)notImplementedYet:(SEL)selector;


@end
