/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

#define QredoLog(_level,_message)   [QredoLogger logMessage: (_message)currentLevel:[QredoLogger logLevel] level: (_level)file: __FILE__ function: __PRETTY_FUNCTION__ line: __LINE__]
#define QredoLogError(format,...)   QredoLog(QredoLogLevelError,(^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))
#define QredoLogWarning(format,...) QredoLog(QredoLogLevelWarning,(^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))
#define QredoLogInfo(format,...)    QredoLog(QredoLogLevelInfo,(^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))
#define QredoLogDebug(format,...)   QredoLog(QredoLogLevelDebug,(^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))
#define QredoLogVerbose(format,...) QredoLog(QredoLogLevelVerbose,(^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))


/**
 The current logging level.
 
 Set this with [setLogLevel](../Classes/QredoLogger.html#/c:objc(cs)QredoLogger(cm)setLogLevel:)
 
 Use this to control what level of logging is written
 
 */
typedef NS_ENUM (NSInteger,QredoLogLevel) {
    /** no logging */
    QredoLogLevelNone,
    /** Log messages with `QredoLogError` */
    QredoLogLevelError,
    /** Log messages with `QredoLogWarning` */
    QredoLogLevelWarning,
    /** Log messages with `QredoLogInfo`. This will report each Qredo API call */
    QredoLogLevelInfo,
    /** Log messages with `QredoLogDebug` */
    QredoLogLevelDebug,
    /** Log messages with `QredoLogVerbose` */
    QredoLogLevelVerbose
};


/**
 
 Logs diagnostic output to the console.
 
 By default logging will be reported for all objects, however you can restrict logging to a list of permitted classes using [addLoggingForObject](#/c:objc(cs)QredoLogger(cm)addLoggingForObject:) or [addLoggingForClassName](#/c:objc(cs)QredoLogger(cm)addLoggingForClassName:)
 
 You can use logging in two ways:
 
 - `QredoLogError(@"My car is %@",car.colour]);`
 
 This is similar to NSLog - here the car.colour is calculated each time the line is encountered, whether or not the message is displayed.
 
 In this case the logging will only be output if the logging level is `QredoLogLevelError` or above.
 
 For other logging levels, use `QredoLogWarning`, `QredoLogInfo`, `QredoLogDebug` or `QredoLogVerbose`
 
 - For a more flexible version of logging, you can specify a code block that will be executed only when the current logging level requires it.
 
 For example, the following code takes a code block that will only be executed when the logging level is QredoLogLevelDebug or above. The block will return a value that is displayed in the log.
 
 `QredoLogDebug(@"Index item count : %i", ^{ return [self count];}());`
 
 Use this method of logging if calculating the required logging output will take a long time to process.
 
 */

@interface QredoLogger :NSObject

/** Log a message to the console. You do not normally need to use this method.
 Use `QredoLogError`, `QredoLogWarning`, `QredoLogInfo`, `QredoLogDebug` or `QredoLogVerbose` instead.
 See the notes at the top of this file for examples
 
 */



+(void)logMessage:(NSString * (^)(void))message currentLevel:(QredoLogLevel)currentLevel level:(QredoLogLevel)level file:(const char *)file function:(const char *)function line:(NSUInteger)line;


//+(void)setLogHandler:(void (^)(NSString * (^message)(void), QredoLogLevel level, const char *file, const char *function, NSUInteger line))logHandler;


/**
 Set the logging level. Set to `QredoLogLevelError` by default.
 
 Messsages are displayed for the specified level and above. For example, if `QredoLogLevelInfo` is chosen, errors and warnings will also be displayed.
 @param logLevel The [QredoLogLevel](../Enums/QredoLogLevel.html) to be written to the console
 
 @warning Always set the logging level to `QredoLogLevelNone` in your production code.
 
 */
+(void)setLogLevel:(QredoLogLevel)logLevel;

/** Returns the current logging level
 
 @return logLevel The current `QredoLogLevel`
 */

+(QredoLogLevel)logLevel;




/** Add the class of the specified object to the 'white list' of classes to be used for logging.
 
 @note If no classes have been added to the white list, a new white list is setup and from that point, only logging output from methods of the classes on the white list will be shown.
 
 @param ob An object of the class to add to the logging white list
 
 
 */
+(void)addLoggingForObject:(NSObject *)ob;

/** Add the class to the 'white list' of classes to be used for logging.
 
 @note If no classes have been added to the white list, a new white list is setup and from that point, only logging output from methods of the classes on the white list will be shown.
 
 @param className The name of the class to add to the logging white list
 
 */

+(void)addLoggingForClassName:(NSString *)className;

/** Clear whitelist and return to producing logging for all classes according to the logging level
 */

+(void)resetLoggingObjects;

/** If colour is enabled, the debug output in Xcode will produce coloured messages
 [Installed XcodeColours](https://github.com/robbiehanson/XcodeColors)
 Alternatively (better method) install using [Alcatraz package manager](http://alcatraz.io)
 
 @param colour Set to YES to use colour in logging output
 */
+(void)colour:(BOOL)colour;


@end
