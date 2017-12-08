/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@class QredoKeyRef;


@interface QredoUserCredentials :NSObject


@property (readonly) NSString *appId;
@property (readonly) NSString *userId;
@property (readonly) NSString *userSecure;

-(instancetype)initWithAppId:(NSString *)appId
                      userId:(NSString *)userId
                  userSecure:(NSString *)userSecure;

-(QredoKeyRef *)userUnlockKeyRef;
-(QredoKeyRef *)generateMasterKeyRef;
-(QredoKeyRef *)masterKeyRef:(QredoKeyRef *)userUnlockKeyRef;

-(NSString *)createSystemVaultIdentifier;
-(NSString *)dataToHexString:(NSData *)data;
-(NSString *)buildIndexName;
-(NSData *)sha1WithString:(NSString *)str;
@end
