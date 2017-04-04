/* HEADER GOES HERE */
#import "QredoUserCredentials.h"
#import <CommonCrypto/CommonCrypto.h>
#import "QredoCrypto.h"
#import "QredoLoggerPrivate.h"

#define SALT_USER_UNLOCK                 [@"3aK3VkzxClECvyFW" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_USER_MASTER                 [@"wjB9zA2l1Z4eiW5t" dataUsingEncoding:NSUTF8StringEncoding]
#define INFO_USER_MASTER                 [@"QREDO_INFO_USER_MASTER" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_VAULT_IDENTIFIER            [@"65gDFtgikmbUYjho" dataUsingEncoding:NSUTF8StringEncoding]

#define INDEX_KEY_SALT                   [@"6GdwobGnGj85rD2Z" dataUsingEncoding:NSUTF8StringEncoding]
#define INDEX_NAME_SALT                  [@"48JGdrpomHvzO9ng" dataUsingEncoding:NSUTF8StringEncoding]
#define INFO_INDEX                       [@"QREDO_COREDATA_INDEX_KEY" dataUsingEncoding:NSUTF8StringEncoding]

#define PBKDF2_USERUNLOCK_KEY_ITERATIONS 1000
#define PBKDF2_DERIVED_KEY_LENGTH_BYTES  32
#define CHECK_ARG(expr,msg) \
if (expr){ @throw [NSException exceptionWithName:NSInvalidArgumentException \
reason:[NSString stringWithFormat:msg] \
userInfo:nil]; \
} \




@implementation QredoUserCredentials


-(instancetype)initWithAppId:(NSString *)appId userId:(NSString *)userId userSecure:(NSString *)userSecure {
    self = [super init];
    
    if (self){
        _appId = appId;
        _userId = userId;
        _userSecure = userSecure;
    }
    
    return self;
}


-(NSData *)userUnlockKey {
    CHECK_ARG(!self.appId,@"appId cannot be nil");
    CHECK_ARG(!self.userId,@"userId cannot be nil");
    CHECK_ARG(!self.userSecure,@"userSecure cannot be nil");
    
    NSMutableData *concatenatedBytes = [[NSMutableData alloc] init];
    [concatenatedBytes appendData:[self sha1WithString:self.appId]];
    [concatenatedBytes appendData:[self sha1WithString:self.userId]];
    [concatenatedBytes appendData:[self sha1WithString:self.userSecure]];
    
    NSData *key = [QredoCrypto pbkdf2Sha256WithSalt:SALT_USER_UNLOCK
                                       passwordData:concatenatedBytes
                             requiredKeyLengthBytes:PBKDF2_DERIVED_KEY_LENGTH_BYTES
                                         iterations:PBKDF2_USERUNLOCK_KEY_ITERATIONS];
    return key;
}


-(NSData *)sha1WithString:(NSString *)str {
    NSMutableData *outputBytes = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    NSData *inputBytes = [str dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA1(inputBytes.bytes,(CC_LONG)inputBytes.length,outputBytes.mutableBytes);
    return outputBytes;
}


-(NSData *)sha256WithString:(NSString *)str {
    NSMutableData *outputBytes = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    NSData *inputBytes = [str dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(inputBytes.bytes,(CC_LONG)inputBytes.length,outputBytes.mutableBytes);
    return outputBytes;
}



-(NSData *)masterKey {
    NSData *userUnlockKey = [self userUnlockKey];
    
    return [self masterKey:userUnlockKey];
}


-(NSData *)masterKey:(NSData *)userUnlockKey {
    NSData *masterKey = [QredoCrypto hkdfSha256WithSalt:SALT_USER_MASTER initialKeyMaterial:userUnlockKey info:INFO_USER_MASTER outputLength:256];
    
    return masterKey;
}


-(NSString *)dataToHexString:(NSData *)data {
    NSUInteger capacity = data.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = data.bytes;
    
    for (int i = 0; i < data.length; i++){
        [sbuf appendFormat:@"%02X",(unsigned int)buf[i]];
    }
    
    return [sbuf copy];
}




-(NSString*)shaAsHex:(NSString*)string{
    NSData *shaData = [self sha1WithString:string];
    return [self dataToHexString:shaData];
}

-(NSString *)buildIndexName {
    NSString *userCredentials = [NSString stringWithFormat:@"%@-%@-%@-%@",self.appId,self.userId,self.userSecure,INDEX_NAME_SALT];
    return [self shaAsHex:userCredentials];
}


-(NSString *)buildIndexKey {
    NSString *userCredentials = [NSString stringWithFormat:@"%@-%@-%@-%@",self.appId,self.userId,self.userSecure, INDEX_KEY_SALT];
    return [self shaAsHex:userCredentials];
}


-(NSString *)createSystemVaultIdentifier {
    NSString *userCredentials = [NSString stringWithFormat:@"%@-%@",self.appId,self.userId];
    NSString *sha1UserCredentialsString =  [self shaAsHex:userCredentials];
    return [NSString stringWithFormat:@"com.qredo.system.vault.key-%@",sha1UserCredentialsString];
}




-(NSString*)description{
    NSMutableString *ret = [[NSMutableString alloc] init];
    [ret appendString:[NSString stringWithFormat:@"AppID     : %@", _appId]];
    [ret appendString:[NSString stringWithFormat:@"UserID    : %@", _userId]];
    [ret appendString:[NSString stringWithFormat:@"UserSecret: %@", _userSecure]];
    return  [ret copy];
}


@end
