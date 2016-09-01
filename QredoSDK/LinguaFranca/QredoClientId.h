/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface QredoClientId :NSObject

+(instancetype)randomClientId;
+(instancetype)clientIdFromData:(NSData *)data;
-(NSData *)getData;

-(NSString *)getSafeString;

@end
