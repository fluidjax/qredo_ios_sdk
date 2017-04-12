/* HEADER GOES HERE */
#import <Foundation/Foundation.h>


@interface QredoUserCredentials :NSObject



@property (strong, atomic) NSString *appId;
@property (strong, atomic) NSString *userId;
@property (strong, atomic) NSString *userSecure;


-(instancetype)initWithAppId:(NSString *)appId
                      userId:(NSString *)userId
                  userSecure:(NSString *)userSecure;

-(NSData *)userUnlockKey;
-(NSData *)masterKey:(NSData *)userUnlockKey;
-(NSData *)masterKey;
-(NSString *)createSystemVaultIdentifier;
-(NSString *)dataToHexString:(NSData *)data;
-(NSString *)buildIndexName;
-(NSString *)buildIndexKey;
-(NSData *)sha1WithString:(NSString *)str;
-(NSData *)sha256WithString:(NSString *)str;
@end
