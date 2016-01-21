//
//  QredoLogger.m
//  QredoSDK
//
//  Created by Christopher Morris on 21/01/2016.
//
//

#import "QredoLogger.h"


@implementation QredoLogger


/**
 The default logging value
 */
static const int DEFAULT_LOG_LEVEL = QredoLogLevelError;


static int currentLoggingLevel = DEFAULT_LOG_LEVEL;
static NSMutableArray *classRestrictionArray;

static void (^LogHandler)(NSString * (^)(void), QredoLogLevel, const char *, const char *, NSUInteger) = ^(NSString *(^message)(void),
                        QredoLogLevel level, const char *file, const char *functionChar, NSUInteger line)   {

    if (level==QredoLogLevelNone)return;
    if (currentLoggingLevel<level)return;  //no logging at this currentLogginLevel

    
    NSString *filename = [[[NSString alloc] initWithUTF8String:file] lastPathComponent];
    NSString *function = [[NSString alloc] initWithUTF8String:functionChar];
    NSString *locationMessage = [NSString stringWithFormat:@"%@:%i ",function,(int)line];
    NSString *className = [QredoLogger extractClassName:function];
    NSString *prefix = @"**";
    NSString *postfix= @" ";
    
    if ([classRestrictionArray count]>0 && ![QredoLogger isClassOfInterest:className]){
        return;
    }
    
    if (level==QredoLogLevelError){
        NSLog(@"%@%@%@%@%@",prefix,@"ERROR  ",postfix, locationMessage,  message());
    }else if (level==QredoLogLevelWarning){
        NSLog(@"%@%@%@%@%@",prefix,@"WARNING",postfix, locationMessage,  message());
    }else if (level==QredoLogLevelInfo){
        NSLog(@"%@%@%@%@%@",prefix,@"INFO   ",postfix, locationMessage,  message());
    }else if (level==QredoLogLevelDebug){
        NSLog(@"%@%@%@%@%@",prefix,@"DEBUG  ",postfix, locationMessage,  message());
    }else if (level==QredoLogLevelVerbose){
        NSLog(@"%@%@%@%@%@",prefix,@"VERBOSE",postfix, locationMessage,  message());

    }
};


+ (void)load{
    //called once when class is first accessed
    [self resetLoggingObjects];
}


+ (void)setLogLevel:(QredoLogLevel)logLevel{
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


#pragma mark - Class/Object restriction


+ (BOOL)isClassOfInterest:(NSString *)className {
    for (NSString *searchClass in classRestrictionArray){
        if ([searchClass isEqualToString:className])return YES;
    }
    return NO;
}


+ (void)addLoggingForObject:(NSObject*)ob{
    NSString *classType = NSStringFromClass([ob class]);
    [classRestrictionArray addObject:classType];
}


+ (void)addLoggingForClassName:(NSString*)className{
    [classRestrictionArray addObject:className];
}


+(void)resetLoggingObjects{
    classRestrictionArray = [[NSMutableArray alloc] init];
}


+ (NSString *)extractClassName:(NSString *)prettyFunction{
    NSRange firstSquareBracket  = [prettyFunction rangeOfString:@"["];
    if (firstSquareBracket.location == NSNotFound)return nil;
    
    NSRange firstSpace  = [prettyFunction rangeOfString:@" "];
    if (firstSpace.location == NSNotFound)return nil;
    
    
    NSRange classPos = NSMakeRange(firstSquareBracket.location+1, firstSpace.location-firstSquareBracket.location-1);
    NSString *className = [prettyFunction substringWithRange:classPos];
    return className;
}



#pragma mark - Helper Logging Methods


+ (NSData *)NSDataFromHexString:(NSString*)string{
    // Originated http://stackoverflow.com/questions/7317860/converting-hex-nsstring-to-nsdata?rq=1
    NSString *noWhitespaceString = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *convertedData = [[NSMutableData alloc] init];
    
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'}; // 2 byte string with null terminator
    
    for (int i = 0; i < [noWhitespaceString length] / 2; i++){
        byte_chars[0] = [noWhitespaceString characterAtIndex:i * 2];
        byte_chars[1] = [noWhitespaceString characterAtIndex:i * 2 + 1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [convertedData appendBytes:&whole_byte length:1];
    }
    
    return convertedData;
}


+ (NSString*)hexRepresentationOfNSData:(NSData*)data{
    //    LogTrace();
    NSString *hexString;
    if (data == nil){
        // If data is nil, just return string containing 'nil'
        hexString = @"nil";
    }else{
        hexString = [QredoLogger printBytesAsHex:data.bytes numberOfBytes:(unsigned int)data.length];
    }
    return hexString;
}


+ (NSString*)printBytesAsHex:(const unsigned char*)bytes numberOfBytes:(const unsigned int)numberOfBytes{
    NSMutableString *hexString;
    if (!bytes){
        // If bytes is nil, just return string containing 'nil'
        hexString = [NSMutableString stringWithString:@"nil"];
    }else{
        hexString = [[NSMutableString alloc] initWithCapacity:numberOfBytes * 2];
        for (int i = 0; i < numberOfBytes; i++){
            [hexString appendFormat:@"%02X", bytes[i]];
        }
    }
    return hexString;
}

+ (NSString*)stringFromOSStatus:(OSStatus)osStatus{
    NSString *messageString = nil;
    // OSX supports converting OSStatus to strings through SecErrorMessages.string, but iOS doesn't include that.
    // Values/strings taken from SecBase.h comments
    switch (osStatus) {
            
        case errSecSuccess:
            messageString = [NSString stringWithFormat:@"No error (%d)", (int)osStatus];
            break;
            
        case errSecUnimplemented:
            messageString = [NSString stringWithFormat:@"Function or operation not implemented (%d)", (int)osStatus];
            break;
            
        case errSecIO:
            messageString = [NSString stringWithFormat:@"I/O error (%d)", (int)osStatus];
            break;
            
        case errSecOpWr:
            messageString = [NSString stringWithFormat:@"File already open with with write permission (%d)", (int)osStatus];
            break;
            
        case errSecParam:
            messageString = [NSString stringWithFormat:@"One or more parameters passed to a function where not valid (%d)", (int)osStatus];
            break;
            
        case errSecAllocate:
            messageString = [NSString stringWithFormat:@"Failed to allocate memory (%d)", (int)osStatus];
            break;
            
        case errSecUserCanceled:
            messageString = [NSString stringWithFormat:@"User canceled the operation (%d)", (int)osStatus];
            break;
            
        case errSecBadReq:
            messageString = [NSString stringWithFormat:@"Bad parameter or invalid state for operation (%d)", (int)osStatus];
            break;
            
        case errSecInternalComponent:
            // No helpful description provided by Apple
            messageString = [NSString stringWithFormat:@"errSecInternalComponent (%d)", (int)osStatus];
            break;
            
        case errSecNotAvailable:
            messageString = [NSString stringWithFormat:@"No keychain is available. You may need to restart your computer (%d)", (int)osStatus];
            break;
            
        case errSecDuplicateItem:
            messageString = [NSString stringWithFormat:@"The specified item already exists in the keychain (%d)", (int)osStatus];
            break;
            
        case errSecItemNotFound:
            messageString = [NSString stringWithFormat:@"The specified item could not be found in the keychain (%d)", (int)osStatus];
            break;
            
        case errSecInteractionNotAllowed:
            messageString = [NSString stringWithFormat:@"User interaction is not allowed (%d)", (int)osStatus];
            break;
            
        case errSecDecode:
            messageString = [NSString stringWithFormat:@"Unable to decode the provided data (%d)", (int)osStatus];
            break;
            
        case errSecAuthFailed:
            messageString = [NSString stringWithFormat:@"The user name or passphrase you entered is not correct (%d)", (int)osStatus];
            break;
            
        default:
            messageString = [NSString stringWithFormat:@"Unknown value (%d)", (int)osStatus];
            break;
    }
    
    return messageString;
}

// TODO: Remove before release
+ (void)notImplementedYet:(SEL)selector{
    NSString *message = [NSString stringWithFormat:@"Method %@ not yet complete/implemented!", NSStringFromSelector(selector)];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:message
                                 userInfo:nil];
}


@end
