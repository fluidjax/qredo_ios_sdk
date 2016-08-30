//
//  QredoUserCredentials.h
//  QredoSDK
//
//  Created by Christopher Morris on 10/11/2015.
//
//

#import <Foundation/Foundation.h>


@interface QredoUserCredentials : NSObject


-(instancetype)initWithAppId:(NSString*)appId
                      userId:(NSString*)userId
                  userSecure:(NSString*)userSecure;

-(NSData*)userUnlockKey;
-(NSData *)masterKey:(NSData *)userUnlockKey;
-(NSData*)masterKey;
-(NSString*)createSystemVaultIdentifier;
-(NSString*)dataToHexString:(NSData*)data;
-(NSString*)buildIndexName;
-(NSString*)buildIndexKey;
@end
