//
//  QredoLoggerPrivate.h
//  QredoSDK
//
//  Created by Christopher Morris on 21/01/2016.
//
//
#import <Foundation/Foundation.h>
#import "QredoLogger.h"

#define QredoLog(_level, _message)   [QredoLogger logMessage:(_message) level:(_level) file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]
#define QredoLogError(format, ...)   QredoLog(QredoLogLevelError,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define QredoLogWarning(format, ...) QredoLog(QredoLogLevelWarning, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define QredoLogInfo(format, ...)    QredoLog(QredoLogLevelInfo,    (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define QredoLogDebug(format, ...)   QredoLog(QredoLogLevelDebug,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define QredoLogVerbose(format, ...) QredoLog(QredoLogLevelVerbose, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))


@interface QredoLogger()

+ (void)logMessage:(NSString * (^)(void))message level:(QredoLogLevel)level file:(const char *)file function:(const char *)function line:(NSUInteger)line;

+ (NSString *)extractClassName:(NSString *)prettyFunction;
+ (BOOL)isClassOfInterest:(NSString *)className;

+ (NSData *)NSDataFromHexString:(NSString*)string;
+ (NSString*)hexRepresentationOfNSData:(NSData*)data;
+ (NSString*)printBytesAsHex:(const unsigned char*)bytes numberOfBytes:(const unsigned int)numberOfBytes;
+ (NSString*)stringFromOSStatus:(OSStatus)osStatus;
+ (void)notImplementedYet:(SEL)selector;


@end
