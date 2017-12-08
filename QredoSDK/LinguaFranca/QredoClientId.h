/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@interface QredoClientId :NSObject

+(instancetype)randomClientId;
+(instancetype)clientIdFromData:(NSData *)data;
-(NSData *)getData;

-(NSString *)getSafeString;

@end
