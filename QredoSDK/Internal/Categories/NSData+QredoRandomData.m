/* HEADER GOES HERE */
#import "NSData+QredoRandomData.h"
#import <Security/Security.h>

@implementation NSData (QredoRandomData)

+(NSData *)dataWithRandomBytesOfLength:(NSUInteger)length {
    uint8_t *randomBytes = malloc(length);
    
    int error = SecRandomCopyBytes(kSecRandomDefault,length,randomBytes);
    NSAssert(error==0, @"Error generating random number");
    
    NSData *randomData = [NSData dataWithBytesNoCopy:randomBytes
                                              length:length
                                        freeWhenDone:YES];
    return randomData;
}


@end
