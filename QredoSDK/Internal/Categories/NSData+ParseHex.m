/* HEADER GOES HERE */
#import "NSData+ParseHex.h"

@implementation NSData (ParseHex)

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

@end
