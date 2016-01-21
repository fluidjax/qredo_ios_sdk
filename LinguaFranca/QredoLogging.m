#import "QredoLogger.h"

@implementation QredoLogger

// TODO: DH - write unit test for NSDataFromHexString
// TODO: DH - confirm works with odd length input string

+ (NSData *)NSDataFromHexString:(NSString*)string{
    // Originated http://stackoverflow.com/questions/7317860/converting-hex-nsstring-to-nsdata?rq=1
    NSString *noWhitespaceString = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *convertedData = [[NSMutableData alloc] init];
    
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'}; // 2 byte string with null terminator
    
    for (int i = 0; i < [noWhitespaceString length] / 2; i++)
    {
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
