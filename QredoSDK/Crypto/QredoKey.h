/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface QredoKey :NSObject


@property (nonatomic,copy) NSData *data;

+(instancetype)keyWithData:(NSData *)keydata;
+(instancetype)keyWithHexString:(NSString *)hexString;
-(NSData *)bytes;
-(int)length;
-(BOOL)isEqual:(id)other;

@end
