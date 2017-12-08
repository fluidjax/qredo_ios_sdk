/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/



#import "QredoUserCredentials.h"
#import <CommonCrypto/CommonCrypto.h>
#import "QredoCryptoRaw.h"
#import "QredoLoggerPrivate.h"
#import "QredoCryptoKeychain.h"
#import "QredoMacros.h"
#import "QredoKeyRef.h"

#define SALT_USER_UNLOCK                 [@"3aK3VkzxClECvyFW" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_USER_MASTER                 [@"wjB9zA2l1Z4eiW5t" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_INDEX_NAME                  [@"48JGdrpomHvzO9ng" dataUsingEncoding:NSUTF8StringEncoding]
#define INFO_USER_MASTER                 [@"QREDO_INFO_USER_MASTER" dataUsingEncoding:NSUTF8StringEncoding]


#define PBKDF2_USERUNLOCK_KEY_ITERATIONS 1000
#define PBKDF2_DERIVED_KEY_LENGTH_BYTES  32

@interface QredoUserCredentials ()
@property (readwrite, atomic) NSString *appId;
@property (readwrite) NSString *userId;
@property (readwrite) NSString *userSecure;


@end


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




-(NSData *)sha1WithString:(NSString *)str {
    NSMutableData *outputBytes = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    NSData *inputBytes = [str dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA1(inputBytes.bytes,(CC_LONG)inputBytes.length,outputBytes.mutableBytes);
    return outputBytes;
}



#pragma Key Generation


-(QredoKeyRef *)generateMasterKeyRef{
    QredoKeyRef *userUnlockKeyRef = [self userUnlockKeyRef];
    QredoKeyRef *masterKeyRef = [self masterKeyRef:userUnlockKeyRef];
    return masterKeyRef;
}


-(QredoKeyRef *)userUnlockKeyRef {
    GUARD(self.appId,@"appId cannot be nil");
    GUARD(self.userId,@"userId cannot be nil");
    GUARD(self.userSecure,@"userSecure cannot be nil");
    
    NSMutableData *concatenatedBytes = [[NSMutableData alloc] init];
    [concatenatedBytes appendData:[self sha1WithString:self.appId]];
    [concatenatedBytes appendData:[self sha1WithString:self.userId]];
    [concatenatedBytes appendData:[self sha1WithString:self.userSecure]];
    QredoKeyRef *keyRef = [[QredoCryptoKeychain standardQredoCryptoKeychain] deriveUserUnlockKeyRef:concatenatedBytes];
    return keyRef;
}


-(QredoKeyRef *)masterKeyRef:(QredoKeyRef *)userUnlockKeyRef {
    QredoKeyRef *masterKeyRef = [[QredoCryptoKeychain standardQredoCryptoKeychain] deriveMasterKeyRef:userUnlockKeyRef];
    return masterKeyRef;
}


-(NSString *)dataToHexString:(NSData *)data {
    NSUInteger capacity = data.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = data.bytes;
    
    for (uint i = 0; i < data.length; i++){
        [sbuf appendFormat:@"%02X",(unsigned int)buf[i]];
    }
    return [sbuf copy];
}


-(NSString*)shaAsHex:(NSString*)string{
    NSData *shaData = [self sha1WithString:string];
    return [self dataToHexString:shaData];
}


-(NSString *)buildIndexName {
    NSString *indexName = [NSString stringWithFormat:@"%@-%@-%@-%@",self.appId,self.userId,self.userSecure,SALT_INDEX_NAME];
    return [self shaAsHex:indexName];
}


-(NSString *)createSystemVaultIdentifier {
    NSString *userCredentials = [NSString stringWithFormat:@"%@-%@-%@",self.appId,self.userId,self.userSecure];
    NSString *sha1UserCredentialsString =  [self shaAsHex:userCredentials];
    return [NSString stringWithFormat:@"com.qredo.system.vault.key-%@",sha1UserCredentialsString];
}


-(NSString*)description{
    NSMutableString *ret = [[NSMutableString alloc] init];
    [ret appendString:[NSString stringWithFormat:@"AppID     : %@", self.appId]];
    [ret appendString:[NSString stringWithFormat:@"UserID    : %@", self.userId]];
    [ret appendString:[NSString stringWithFormat:@"UserSecret: %@", self.userSecure]];
    return  [ret copy];
}


@end
