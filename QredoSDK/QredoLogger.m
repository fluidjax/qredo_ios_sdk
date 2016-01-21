//
//  QredoLogger.m
//  QredoSDK
//
//  Created by Christopher Morris on 21/01/2016.
//
//

#import "QredoLogger.h"


@implementation QredoLogger



static int currentLoggingLevel = 0;


static void (^LogHandler)(NSString * (^)(void), QredoLogLevel, const char *, const char *, NSUInteger) = ^(NSString *(^message)(void),
                        QredoLogLevel level, const char *file, const char *function, NSUInteger line)   {
 
    if (currentLoggingLevel<level)return;  //no logging at this currentLogginLevel
    
    
    if (level==QredoLogLevelNone){
        return;
    }else if (level==QredoLogLevelError){
        NSLog(@"**[QredoSDK ERROR]   %@", message());
    }else if (level==QredoLogLevelWarning){
        NSLog(@"**[QredoSDK WARNING] %@", message());
    }else if (level==QredoLogLevelInfo){
        NSLog(@"**[QredoSDK INFO]    %@", message());
    }else if (level==QredoLogLevelDebug){
        NSLog(@"**[QredoSDK DEBUG]   %@", message());
    }else if (level==QredoLogLevelVerbose){
        NSLog(@"**[QredoSDK VERBOSE] %@", message());
    }
    
};

+ (void)setLogLevel:(int)logLevel{
    currentLoggingLevel = logLevel;
}


+ (void) setLogHandler:(void (^)(NSString * (^message)(void), QredoLogLevel level, const char *file, const char *function, NSUInteger line))logHandler{
    LogHandler = logHandler;
}

+ (void) logMessage:(NSString * (^)(void))message level:(QredoLogLevel)level file:(const char *)file function:(const char *)function line:(NSUInteger)line{
    if (LogHandler){
        LogHandler(message, level, file, function, line);
    }
}


@end
