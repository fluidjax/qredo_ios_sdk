#import <Foundation/Foundation.h>

@interface QredoQUID : NSObject <NSCopying, NSSecureCoding>

- (NSData*)data;    /* Return a string description of the QUID with hexadecimal representation of 32-bytes (the string will have 64 characters) */
- (NSString *)QUIDString;
- (NSComparisonResult)compare:(QredoQUID *)object;

@end
