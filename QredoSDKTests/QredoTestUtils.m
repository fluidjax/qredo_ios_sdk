/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoTestUtils.h"

// Note: do not reduce this as some tests may rely on this value to complete processing before timeout
NSTimeInterval qtu_defaultTimeout = 30.0;

// Beacuse of slow QMac... (perhaps)
// TODO: DH - Investigating whether increasing timeout improves test reliability. Orig 10s, RSA 4096 key gen can take 10+ seconds, so upping to 30 seconds for safety


NSString *k_APPID         = @"test";
NSString *k_APPSECRET     = @"cafebabe";
NSString *k_USERID        = @"testUserId";



@implementation QredoTestUtils

+(NSString*)randomPassword{
    return [QredoTestUtils randomStringWithLength:32];
}

+(NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}

@end


@implementation NSData (QredoTestUtils)






+ (NSData*)qtu_dataWithRandomBytesOfLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: length];
    for (unsigned int i = 0; i < length; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    } return mutableData;
}

@end


@implementation QredoClientOptions(QredoTestUtils)

+ (instancetype)qtu_clientOptionsWithResetData:(BOOL)resetData
{
    QredoClientOptions* clientOptions = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    return clientOptions;
}

+ (instancetype)qtu_clientOptionsWithTransportType:(QredoClientOptionsTransportType)transportType
                                         resetData:(BOOL)resetData
{
    QredoClientOptions* clientOptions = [QredoClientOptions qtu_clientOptionsWithResetData:resetData];
    clientOptions.transportType = transportType;
    return clientOptions;
}

@end

