/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "NSData+HexTools.h"

@implementation NSData (HexTools)



+(instancetype)dataWithHexString:(NSString *)hexString {
    //Taken from http://stackoverflow.com/questions/7317860/converting-hex-nsstring-to-nsdata
    NSString *command = [[hexString stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    NSMutableData *commandToSend = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = { '\0','\0','\0' };
    int i;
    for (i = 0; i < [command length] / 2; i++){
        byte_chars[0] = [command characterAtIndex:i * 2];
        byte_chars[1] = [command characterAtIndex:i * 2 + 1];
        whole_byte = strtol(byte_chars,NULL,16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    return [self dataWithData:commandToSend];
}


-(NSString *)hexadecimalString {
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    const unsigned char *dataBuffer = (const unsigned char *)self.bytes;
    if (!dataBuffer)return [NSString string];
    NSUInteger dataLength  = [self length];
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i){
        [hexString appendString:[NSString stringWithFormat:@"%02lx",(unsigned long)dataBuffer[i]]];
    }
    return [NSString stringWithString:hexString];
}


@end
