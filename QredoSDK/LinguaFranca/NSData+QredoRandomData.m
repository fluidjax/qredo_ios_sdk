/* HEADER GOES HERE */
#import "NSData+QredoRandomData.h"
#import <Security/Security.h>

@implementation NSData (QredoRandomData)

+(NSData *)dataWithRandomBytesOfLength:(NSUInteger)length {
    uint8_t *randomBytes = malloc(length); //this is automatically freed in the dataWithBytesNoCopy call
    
    int err = SecRandomCopyBytes(kSecRandomDefault,length,randomBytes);
    if (err){
        NSAssert(true, @"Critical error creating random number");
    }
    
    NSData *randomData = [NSData dataWithBytesNoCopy:randomBytes
                                              length:length
                                        freeWhenDone:YES];
    return randomData;
}


@end
