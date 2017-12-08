/* HEADER GOES HERE */


#import <Foundation/Foundation.h>

@interface QredoKeyRef : NSObject

+(instancetype)keyRefWithKeyData:(NSData*)keyData;
+(instancetype)keyRefWithKeyHexString:(NSString*)keyHexString;

-(NSData*)ref;
-(BOOL)isEqual:(id)other;

@end
