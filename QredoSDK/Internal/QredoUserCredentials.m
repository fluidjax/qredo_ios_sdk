//
//  QredoUserCredentials.m
//  QredoSDK
//
//  Created by Christopher Morris on 10/11/2015.
//
//

#import "QredoUserCredentials.h"
#import <CommonCrypto/CommonCrypto.h>
#import "QredoCrypto.h"
#import "QredoLoggerPrivate.h"

#define SALT_USER_UNLOCK [@"3aK3VkzxClECvyFW" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_USER_MASTER [@"wjB9zA2l1Z4eiW5t" dataUsingEncoding:NSUTF8StringEncoding]
#define INFO_USER_MASTER [@"QREDO_INFO_USER_MASTER" dataUsingEncoding:NSUTF8StringEncoding]
#define PBKDF2_USERUNLOCK_KEY_ITERATIONS 1000
#define PBKDF2_DERIVED_KEY_LENGTH_BYTES 32
#define CHECK_ARG(expr, msg) if (expr){@throw [NSException exceptionWithName:NSInvalidArgumentException\
                                                                reason:[NSString stringWithFormat:msg]\
                                                                userInfo:nil];\
                                                                }\

@interface QredoUserCredentials ()
@property (strong) NSString *appId;
@property (strong) NSString *userId;
@property (strong) NSString *userSecure;
@end


@implementation QredoUserCredentials


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
    
    CHECK_ARG(!self.appId,      @"appId cannot be nil");
    CHECK_ARG(!self.userId,     @"userId cannot be nil");
    CHECK_ARG(!self.userSecure, @"userSecure cannot be nil");
    
    
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


-(NSString*)dataToHexString:(NSData*)data{
    NSUInteger capacity = data.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = data.bytes;
    for (int i=0; i<data.length; i++) {
        [sbuf appendFormat:@"%02X", (unsigned int)buf[i]];
    }
    return [sbuf copy];
}


-(NSString*)createSystemVaultIdentifier{
    NSString *userCredentials = [NSString stringWithFormat:@"%@-%@-%@",self.appId,self.userId, self.userSecure];
    NSData *sha1UserCredentials = [self sha1WithString:userCredentials];
    NSString *sha1UserCredentialsString =  [self dataToHexString:sha1UserCredentials];
    return [NSString stringWithFormat:@"com.qredo.system.vault.key-%@",sha1UserCredentialsString];
}


@end
