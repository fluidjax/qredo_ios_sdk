/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoPublicKey.h"

@interface QredoRsaPublicKey :QredoPublicKey

@property (nonatomic,strong,readonly) NSData *modulus;
@property (nonatomic,strong,readonly) NSData *publicExponent;

-(instancetype)initWithModulus:(NSData *)modulus publicExponent:(NSData *)publicExponent;
-(instancetype)initWithPkcs1KeyData:(NSData *)keyData;
-(instancetype)initWithX509KeyData:(NSData *)keyData;
-(NSData *)convertToPkcs1Format;
-(NSData *)convertToX509Format;

@end
