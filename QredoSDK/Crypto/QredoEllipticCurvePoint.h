/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface QredoEllipticCurvePoint :NSObject

@property (nonatomic,strong,readonly) NSData *data;

+(instancetype)pointWithData:(NSData *)pointData;
-(instancetype)initWithPointData:(NSData *)pointData;
-(QredoEllipticCurvePoint *)multiplyWithPoint:(QredoEllipticCurvePoint *)point;

@end
