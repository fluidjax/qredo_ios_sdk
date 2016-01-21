//
//  QredoLogger.h
//  QredoSDK
//
//  Created by Christopher Morris on 21/01/2016.
//
//

#import <Foundation/Foundation.h>

#define QredoLog(_level, _message)   [QredoLogger logMessage:(_message) level:(_level) file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]

#define QredoLogError(format, ...)   QredoLog(QredoLogLevelError,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define QredoLogWarning(format, ...) QredoLog(QredoLogLevelWarning, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define QredoLogInfo(format, ...)    QredoLog(QredoLogLevelInfo,    (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define QredoLogDebug(format, ...)   QredoLog(QredoLogLevelDebug,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define QredoLogVerbose(format, ...) QredoLog(QredoLogLevelVerbose, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))


typedef NS_ENUM(NSUInteger, QredoLogLevel) {
    QredoLogLevelNone    = 0,
    QredoLogLevelError   = 1,
    QredoLogLevelWarning = 2,
    QredoLogLevelInfo    = 3,
    QredoLogLevelDebug   = 4,
    QredoLogLevelVerbose = 5,
};

@interface QredoLogger : NSObject

+ (void)setLogHandler:(void (^)(NSString * (^message)(void), QredoLogLevel level, const char *file, const char *function, NSUInteger line))logHandler;
+ (void)logMessage:(NSString * (^)(void))message level:(QredoLogLevel)level file:(const char *)file function:(const char *)function line:(NSUInteger)line;
+ (void)setLogLevel:(int)logLevel;
@end
