/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/




#import <Foundation/Foundation.h>

@interface QredoKeyRef : NSObject

+(instancetype)keyRefWithKeyData:(NSData*)keyData;
+(instancetype)keyRefWithKeyHexString:(NSString*)keyHexString;

-(NSData*)ref;
-(BOOL)isEqual:(id)other;

@end
