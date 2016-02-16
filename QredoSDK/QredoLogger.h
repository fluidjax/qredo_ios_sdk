/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


/**
 
 The logger is set to "Error" level by default
 
 To change loglevel use
 [QredoLogger setLogLevel:int];
 
 Where the int parameter is one of the following, message are displayed for the chosed level and above.
 QredoLogLevelNone
 QredoLogLevelError
 QredoLogLevelWarning
 QredoLogLevelInfo
 QredoLogLevelDebug
 QredoLogLevelVerbose
 
 e.g.
 When the log level is set to Info using:
 [QredoLogger setLogLevel:QredoLogLevelInfo];
 Log messages for specified level and above are shown, in this case Error, Warning & Info.
 
 ------------------------------------------------------------------------------------------------
 
 By default logging will be reported for all objects, however if you add classnames  to the loggers list of permitted objects using :-
 
 [QredoLogger addLoggingForClassName:@"QredoLocalIndexDataStore"];
 or     [QredoLogger addLoggingForObject:self];
 
 Only these specified classes will produce log output, this allows verbose levels of logging targetted at just the code under review.
 
 ------------------------------------------------------------------------------------------------
 
 There are two main ways to use the logger in code
 
 1)     QredoLogError(@"My car is %@",car.colour]);
 
 Similar to NSLog - here the car.colour is calculated each time the line is encountered, whether or not the message is displayed
 Use 1) If the parameters are simple properties
 
 
 2)     QredoLogVerbose(@"Some information : %@", ^{ return @"generated error message from block"; }());
 QredoLogDebug(@"Index item count : %i", ^{ return [self count];}());
 
 The block is only executed if the message is actually going to be displayed.  This is essential if the block will take a significant time to run, such as a method call
 to count the records in a coredata table.
 
 */

#import <Foundation/Foundation.h>

#define QredoLog(_level, _message)   [QredoLogger logMessage: (_message) level: (_level) file: __FILE__ function: __PRETTY_FUNCTION__ line: __LINE__]
#define QredoLogError(format, ...)   QredoLog(QredoLogLevelError,   (^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))
#define QredoLogWarning(format, ...) QredoLog(QredoLogLevelWarning, (^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))
#define QredoLogInfo(format, ...)    QredoLog(QredoLogLevelInfo,    (^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))
#define QredoLogDebug(format, ...)   QredoLog(QredoLogLevelDebug,   (^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))
#define QredoLogVerbose(format, ...) QredoLog(QredoLogLevelVerbose, (^{ return [NSString stringWithFormat:(format), ## __VA_ARGS__]; }))


typedef NS_ENUM (NSInteger, QredoLogLevel) {
    QredoLogLevelNone,
    QredoLogLevelError,
    QredoLogLevelWarning,
    QredoLogLevelInfo,
    QredoLogLevelDebug,
    QredoLogLevelVerbose
};


@interface QredoLogger :NSObject

+(void)logMessage:(NSString * (^)(void))message level:(QredoLogLevel)level file:(const char *)file function:(const char *)function line:(NSUInteger)line;
+(void)setLogHandler:(void (^)(NSString * (^message)(void), QredoLogLevel level, const char *file, const char *function, NSUInteger line))logHandler;
+(void)setLogLevel:(QredoLogLevel)logLevel;
+(QredoLogLevel)logLevel;


/* Specify a whitelist of Objects/classNames to restrict logging messages produce by specified Objects/classes
 */
+(void)addLoggingForObject:(NSObject*)ob;
+(void)addLoggingForClassName:(NSString*)className;

/** Clear whitelist and return to producing logging for everything
 */
+(void)resetLoggingObjects;

/** If colour is enabled, the debug output in xcode will produced coloured messages
 Installed XcodeColours - https://github.com/robbiehanson/XcodeColors
 Or (better method) install using Alcatraz package manage - http://alcatraz.io
 */
+(void)colour:(BOOL)colour;


@end
