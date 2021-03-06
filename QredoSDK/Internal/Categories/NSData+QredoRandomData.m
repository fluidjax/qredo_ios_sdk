/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "NSData+QredoRandomData.h"
#import <Security/Security.h>

@implementation NSData (QredoRandomData)

+(NSData *)dataWithRandomBytesOfLength:(NSUInteger)length {
    uint8_t *randomBytes = malloc(length); //this is automatically freed in the dataWithBytesNoCopy call
    
    int err = SecRandomCopyBytes(kSecRandomDefault,length,randomBytes);
    
    if(err != noErr)
        @throw [NSException exceptionWithName:@"Critical Error" reason:@".Failed to generate random number." userInfo:nil];
    

    //this doesn't leak - its a false positive
    NSData *randomData = [NSData dataWithBytesNoCopy:randomBytes
                                              length:length
                                        freeWhenDone:YES];
   
    return randomData;
}



@end
