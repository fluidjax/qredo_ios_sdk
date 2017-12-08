/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoCryptoImpl.h"


#define SHA256_DIGEST_SIZE              32
#define HMAC_SIZE                       SHA256_DIGEST_SIZE
#define BULK_KEY_SIZE                   kCCKeySizeAES256
#define PBKDF2_ITERATION_COUNT          10000
#define PBKDF2_DERIVED_KEY_SIZE         32
#define PASSWORD_ENCODING_FOR_PBKDF2    NSUTF8StringEncoding
#define ED25519_VERIFY_KEY_SIZE         32
#define ED25519_SIGNING_KEY_SIZE        64
#define ED25519_SIGNATURE_SIZE          64
#define ED25519_SEED_SIZE               32
#define MASTER_KEY_SIZE                 256


#define SALT_USER_UNLOCK                 [@"3aK3VkzxClECvyFW" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_USER_MASTER                 [@"wjB9zA2l1Z4eiW5t" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_INDEX_NAME                  [@"48JGdrpomHvzO9ng" dataUsingEncoding:NSUTF8StringEncoding]
#define INFO_USER_MASTER                 [@"QREDO_INFO_USER_MASTER" dataUsingEncoding:NSUTF8StringEncoding]
#define PBKDF2_USERUNLOCK_KEY_ITERATIONS 1000


@interface QredoCryptoImplV1 : NSObject <QredoCryptoImpl>
+(instancetype)sharedInstance;
-(instancetype) init __attribute__((unavailable("init not available")));  
@end
