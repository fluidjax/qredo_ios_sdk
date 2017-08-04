/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface QredoKey :NSObject


@property (nonatomic,copy) NSData *data;

-(instancetype)initWithData:(NSData *)keydata;
-(instancetype)initWithHexString:(NSString *)hexString;
-(NSData *)bytes;
-(int)length;
-(BOOL)isEqual:(id)other;

@end
