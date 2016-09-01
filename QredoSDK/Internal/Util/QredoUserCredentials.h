/* HEADER GOES HERE */
#import <Foundation/Foundation.h>


@interface QredoUserCredentials :NSObject


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
@end
