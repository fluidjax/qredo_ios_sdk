//
//  QredoXCTestCase.m
//  QredoSDK
//
//  Created by Christopher Morris on 22/01/2016.
//  This is the superclass of all Qredo Tests
//

#import "QredoXCTestCase.h"

@implementation QredoXCTestCase



- (void)setUp {
    [super setUp];
    [self setLogLevel];
}

-(void)setLogLevel{
/*  Available debug levels
        [QredoLogger setLogLevel:QredoLogLevelNone];
        [QredoLogger setLogLevel:QredoLogLevelError];
        [QredoLogger setLogLevel:QredoLogLevelWarning];
        [QredoLogger setLogLevel:QredoLogLevelInfo];
        [QredoLogger setLogLevel:QredoLogLevelDebug];
        [QredoLogger setLogLevel:QredoLogLevelVerbose];
        [QredoLogger setLogLevel:QredoLogLevelInfo];
 */

    
    [QredoLogger setLogLevel:QredoLogLevelWarning];
}



-(void)loggingOff{
    [QredoLogger setLogLevel:QredoLogLevelNone];
}


-(void)loggingOn{
    [self setLogLevel];
}



-(void)resetKeychain {
    [self deleteAllKeysForSecClass:kSecClassGenericPassword];
    [self deleteAllKeysForSecClass:kSecClassInternetPassword];
    [self deleteAllKeysForSecClass:kSecClassCertificate];
    [self deleteAllKeysForSecClass:kSecClassKey];
    [self deleteAllKeysForSecClass:kSecClassIdentity];
}

-(void)deleteAllKeysForSecClass:(CFTypeRef)secClass {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:(__bridge id)secClass forKey:(__bridge id)kSecClass];
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef) dict);
    NSAssert(result == noErr || result == errSecItemNotFound, @"Error deleting keychain data (%ld)", (long)result);
}

- (NSData*)randomDataWithLength:(int)length {
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: length];
    for (unsigned int i = 0; i < length; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    } return mutableData;
}

-(NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}


@end
