//
//  QredoUserInitialization.m
//  QredoSDK
//
//  Created by Christopher Morris on 10/11/2015.
//
//

#import "QredoUserInitialization.h"
#import <CommonCrypto/CommonCrypto.h>
#import "QredoCrypto.h"


#define SALT_USER_UNLOCK [@"3aK3VkzxClECvyFW" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_USER_MASTER [@"wjB9zA2l1Z4eiW5t" dataUsingEncoding:NSUTF8StringEncoding]
#define INFO_USER_MASTER [@"QREDO_INFO_USER_MASTER" dataUsingEncoding:NSUTF8StringEncoding]
#define PBKDF2_USERUNLOCK_KEY_ITERATIONS 1000
#define PBKDF2_DERIVED_KEY_LENGTH_BYTES 32


@interface QredoUserInitialization ()
@property (strong) NSString *appId;
@property (strong) NSString *userId;
@property (strong) NSString *userSecure;
@end


@implementation QredoUserInitialization


-(instancetype)initWithAppId:(NSString*)appId userId:(NSString*)userId userSecure:(NSString*)userSecure{
    self = [super init];
    if (self) {
        _appId = appId;
        _userId = userId;
        _userSecure = userSecure;
    }
    return self;
}


-(NSData *)userUnlockKey{
    
    if (!self.appId){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"appId cannot be nil"]
                                     userInfo:nil];
    }
    if (!self.userId){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"userId cannot be nil"]
                                     userInfo:nil];
    }
    if (!self.userSecure){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"userSecure cannot be nil"]
                                     userInfo:nil];
    }
    
    NSMutableData *concatenatedBytes = [[NSMutableData alloc] init];
    [concatenatedBytes appendData:[self sha1WithString:self.appId]];
    [concatenatedBytes appendData:[self sha1WithString:self.userId]];
    [concatenatedBytes appendData:[self sha1WithString:self.userSecure]];
    
    NSData *key = [QredoCrypto pbkdf2Sha256WithSalt:SALT_USER_UNLOCK
                              bypassSaltLengthCheck:NO
                                       passwordData:concatenatedBytes
                             requiredKeyLengthBytes:PBKDF2_DERIVED_KEY_LENGTH_BYTES
                                         iterations:PBKDF2_USERUNLOCK_KEY_ITERATIONS];
    return key;
}


-(NSData *)sha1WithString:(NSString *)str{
    NSMutableData *outputBytes = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    NSData *inputBytes = [str dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA1(inputBytes.bytes, (CC_LONG)inputBytes.length, outputBytes.mutableBytes);
    return outputBytes;
}


-(NSData *)masterKey{
    NSData *userUnlockKey = [self userUnlockKey];
    return [self masterKey:userUnlockKey];
}

-(NSData *)masterKey:(NSData *)userUnlockKey{
    NSData *masterKey = [QredoCrypto hkdfSha256WithSalt:SALT_USER_MASTER initialKeyMaterial:userUnlockKey info:INFO_USER_MASTER outputLength:256];
    return masterKey;
}


@end
