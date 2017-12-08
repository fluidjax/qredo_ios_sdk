/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@interface QredoEllipticCurvePoint :NSObject

@property (nonatomic,strong,readonly) NSData *data;

+(instancetype)pointWithData:(NSData *)pointData;
-(instancetype)initWithPointData:(NSData *)pointData;
-(QredoEllipticCurvePoint *)multiplyWithPoint:(QredoEllipticCurvePoint *)point;

@end
