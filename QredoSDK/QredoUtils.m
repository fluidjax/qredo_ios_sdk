//
//  QredoUtils.m
//  QredoSDK
//
//  Created by Christopher Morris on 10/05/2016.
//
//

#import "QredoUtils.h"
#import "ReadableKeys.h"

@implementation QredoUtils


+(NSString *)rfc1751Key2Eng:(NSData *)key{
    return [ReadableKeys rfc1751Key2Eng:key];
}

+(NSData *)rfc1751Eng2Key:(NSString *)english{
    return [ReadableKeys rfc1751Eng2Key:english];
}


+(NSData *)eng2Key:(NSString *)english{
    return [ReadableKeys eng2Key:english];
}

+(NSString *)key2Eng:(NSData *)key{
     return [ReadableKeys key2Eng:key];
}




+(NSData *)randomKey:(NSUInteger)size{
    size_t   randomSize  = size;
    uint8_t *randomBytes = alloca(randomSize);
    int result = SecRandomCopyBytes(kSecRandomDefault, randomSize, randomBytes);
    if (result != 0) {
        @throw [NSException exceptionWithName:@"QredoSecureRandomGenerationException"
                                       reason:[NSString stringWithFormat:@"Failed to generate a secure random byte array of size %lu (result: %d)..", (unsigned long)size, result]
                                     userInfo:nil];
    }
    NSData *ret = [NSData dataWithBytes:randomBytes length:randomSize];
    return ret;
    
}


+(NSString*)dataToHexString:(NSData*)data{
    NSUInteger capacity = data.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = data.bytes;
    for (int i=0; i<data.length; i++) {
        [sbuf appendFormat:@"%02X", (unsigned int)buf[i]];
    }
    return [sbuf copy];
}


@end
