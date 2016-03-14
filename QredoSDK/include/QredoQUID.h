#import <Foundation/Foundation.h>

@interface QredoQUID : NSObject<NSCopying, NSSecureCoding>

    /* Create a new autoreleased NSUUID with RFC 4122 version 4 random bytes */
+ (instancetype)QUID;

+ (instancetype)QUIDByHashingData:(NSData*)data;

    /* Create a new NSUUID with RFC 4122 version 4 random bytes */
- (instancetype)init;

    /* Create an QUID from a string of 64 characters. Returns nil for invalid strings. */
- (instancetype)initWithQUIDString:(NSString *)string;

    /* Create an QredoQUID with the given bytes */
- (instancetype)initWithQUIDBytes:(const unsigned char*)bytes;

    /* Create an QredoQUID with the given data */
- (instancetype)initWithQUIDData:(NSData *)data;

    /* Copies QUID bytes to the buffer passed as the argument. The buffer should be at least 32 bytes long */
- (void)getQUIDBytes:(unsigned char *)quid;

    /* returns pointer to internal buffer. The pointer should not be freed or modified by external code */
- (const unsigned char*)bytes;

    /* returns 32. Used to avoid hardcoding this value in the rest of the code */
- (int)bytesCount;

- (NSData*)data;

    /* Return a string description of the QUID with hexadecimal representation of 32-bytes (the string will have 64 characters) */
- (NSString *)QUIDString;

- (NSComparisonResult)compare:(QredoQUID *)object;

@end
