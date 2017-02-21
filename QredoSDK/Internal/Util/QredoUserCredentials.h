/* HEADER GOES HERE */
#import <Foundation/Foundation.h>


@interface QredoUserCredentials :NSObject



@property (strong) NSString *appId;
@property (strong) NSString *userId;
@property (strong) NSString *userSecure;


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
