#import "NSData+QredoRandomData.h"
#import <Security/Security.h>

@implementation NSData (QredoRandomData)

+ (NSData *)dataWithRandomBytesOfLength:(NSUInteger)length
{
    uint8_t *randomBytes = malloc(length);

    SecRandomCopyBytes(kSecRandomDefault, length, randomBytes);

    NSData *randomData = [NSData dataWithBytesNoCopy:randomBytes
                                              length:length
                                        freeWhenDone:YES];
    return randomData;
}

@end