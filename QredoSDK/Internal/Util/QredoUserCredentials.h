/* HEADER GOES HERE */
#import <Foundation/Foundation.h>


@interface QredoUserCredentials :NSObject


@property (readonly) NSString *appId;
@property (readonly) NSString *userId;
@property (readonly) NSString *userSecure;


-(instancetype)initWithAppId:(NSString *)appId
                      userId:(NSString *)userId
                  userSecure:(NSString *)userSecure;

-(NSData *)userUnlockKey;
-(NSData *)masterKey:(NSData *)userUnlockKey;
-(NSData *)masterKey;
-(NSString *)createSystemVaultIdentifier;
-(NSString *)dataToHexString:(NSData *)data;
-(NSString *)buildIndexName;
-(NSData *)sha1WithString:(NSString *)str;
-(NSData *)sha256WithString:(NSString *)str;
@end
