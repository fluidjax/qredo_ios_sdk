/* HEADER GOES HERE */
#import "QredoUtils.h"
#import "ReadableKeys.h"
#import "sodium.h"


@implementation QredoUtils


+(NSString *)rfc1751Key2Eng:(NSData *)key {
    return [ReadableKeys rfc1751Key2Eng:key];
}


+(NSData *)rfc1751Eng2Key:(NSString *)english {
    return [ReadableKeys rfc1751Eng2Key:english];
}


+(NSData *)eng2Key:(NSString *)english {
    return [ReadableKeys eng2Key:english];
}


+(NSString *)key2Eng:(NSData *)key {
    return [ReadableKeys key2Eng:key];
}


+(NSData *)randomKey:(NSUInteger)size {
    size_t randomSize  = size;
    uint8_t *randomBytes = alloca(randomSize);
    int result = SecRandomCopyBytes(kSecRandomDefault,randomSize,randomBytes);
    
    if (result != 0){
        @throw [NSException exceptionWithName:@"QredoSecureRandomGenerationException"
                                       reason:[NSString stringWithFormat:@"Failed to generate a secure random byte array of size %lu (result: %d)..",(unsigned long)size,result]
                                     userInfo:nil];
    }
    
    NSData *ret = [NSData dataWithBytes:randomBytes length:randomSize];
    return ret;
}


+(NSString *)dataToHexString:(NSData *)data {
    if (!data)return nil;
    
    NSUInteger capacity = data.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = data.bytes;
    
    for (int i = 0; i < data.length; i++){
        [sbuf appendFormat:@"%02X",(unsigned int)buf[i]];
    }
    
    return [sbuf copy];
}


+(NSData *)hexStringToData:(NSString *)hexString {
    //Taken from http://stackoverflow.com/questions/7317860/converting-hex-nsstring-to-nsdata
    NSString *command = [[hexString stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    
    if (command.length % 2 != 0){
        NSLog(@"invalid hex string length");
        return nil;
    }
    
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
    
    return [NSData dataWithData:commandToSend];
}


+(NSData *)randomBytesOfLength:(NSUInteger)size {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity:size];
    
    for (unsigned int i = 0; i < size; i++){
        NSInteger randomBits = arc4random();
        [mutableData appendBytes:(void *)&randomBits length:1];
    }
    
    return mutableData;
}


@end
