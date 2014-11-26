/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoTestUtils.h"
#import "QredoTestConfiguration.h"

NSTimeInterval qtu_defaultTimeout = 10.0;

@implementation NSData (QredoTestUtils)

+ (NSData*)qtu_dataWithRandomBytesOfLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: length];
    for (unsigned int i = 0; i < length; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    } return mutableData;
}

@end

