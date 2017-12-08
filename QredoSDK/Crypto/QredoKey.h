/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@interface QredoKey :NSObject


@property (nonatomic,copy) NSData *data;

+(instancetype)keyWithData:(NSData *)keydata;
+(instancetype)keyWithHexString:(NSString *)hexString;
-(NSData *)bytes;
-(int)length;
-(BOOL)isEqual:(id)other;

@end
