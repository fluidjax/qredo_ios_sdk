/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoTestUtils.h"

//Note: do not reduce this as some tests may rely on this value to complete processing before timeout
NSTimeInterval qtu_defaultTimeout = 30.0;

//Beacuse of slow QMac... (perhaps)
//TODO: DH - Investigating whether increasing timeout improves test reliability. Orig 10s, RSA 4096 key gen can take 10+ seconds, so upping to 30 seconds for safety


@implementation NSData (QredoTestUtils)


+(NSData *)qtu_dataWithRandomBytesOfLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity:length];
    
    for (unsigned int i = 0; i < length; i++){
        NSInteger randomBits = arc4random();
        [mutableData appendBytes:(void *)&randomBits length:1];
    }
    
    return mutableData;
}


@end
