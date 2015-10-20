#import <Foundation/Foundation.h>

#ifdef QREDO_LOG_ERROR
#   define LogError(fmt, ...) NSLog((@"ERROR: **** %s [L:%d] " fmt " ****"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define LogError(...)
#endif

#ifdef QREDO_LOG_DEBUG
#   define LogDebug(fmt, ...) NSLog((fmt), ##__VA_ARGS__);
#else
#   define LogDebug(...)
#endif

#ifdef QREDO_LOG_INFO
#   define LogInfo(fmt, ...) NSLog((fmt), ##__VA_ARGS__);
#else
#   define LogInfo(...)
#endif

#ifdef QREDO_LOG_TRACE
#   define LogTrace() NSLog(@"%s Entered", __PRETTY_FUNCTION__);
#   define LogTraceExit() NSLog(@"%s Exited", __PRETTY_FUNCTION__);
#else
#   define LogTrace(...)
#   define LogTraceExit(...)
#endif

@interface QredoLogging : NSObject

+ (NSData *)NSDataFromHexString:(NSString*)string;
+ (NSString*)hexRepresentationOfNSData:(NSData*)data;
+ (NSString*)printBytesAsHex:(const unsigned char*)bytes numberOfBytes:(const unsigned int)numberOfBytes;
+ (NSString*)stringFromOSStatus:(OSStatus)osStatus;
+ (void)notImplementedYet:(SEL)selector;

@end
