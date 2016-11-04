/* HEADER GOES HERE */
#import "NSData+QredoRandomData.h"
#import <Security/Security.h>

@implementation NSData (QredoRandomData)

+(NSData *)dataWithRandomBytesOfLength:(NSUInteger)length {
    uint8_t *randomBytes = malloc(length);
    
    int err = SecRandomCopyBytes(kSecRandomDefault,length,randomBytes);
    
    if(err != noErr)
        @throw [NSException exceptionWithName:@"Critical Error" reason:@".Failed to generate random number." userInfo:nil];
    

    
    NSData *randomData = [NSData dataWithBytesNoCopy:randomBytes
                                              length:length
                                        freeWhenDone:YES];
    return randomData;
}



@end
