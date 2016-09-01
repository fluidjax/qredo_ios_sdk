/* HEADER GOES HERE */
#import "QredoEllipticCurvePoint.h"
#import "sodium.h"

#define SCALAR_MULT_RESULT_LENGTH 32

@interface QredoEllipticCurvePoint ()

@property (nonatomic,strong) NSData *data;

@end

@implementation QredoEllipticCurvePoint

+(instancetype)pointWithData:(NSData *)pointData {
    return [[self alloc] initWithPointData:pointData];
}

-(instancetype)initWithPointData:(NSData *)pointData {
    if (!pointData){
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Point data argument is nil"
                                     userInfo:nil];
    }
    
    self = [super init];
    
    if (self){
        _data = pointData;
    }
    
    return self;
}

-(QredoEllipticCurvePoint *)multiplyWithPoint:(QredoEllipticCurvePoint *)point {
    NSMutableData *result = [[NSMutableData alloc] initWithLength:SCALAR_MULT_RESULT_LENGTH];
    
    crypto_scalarmult_curve25519(result.mutableBytes,point.data.bytes,self.data.bytes);
    
    QredoEllipticCurvePoint *newPoint = [[QredoEllipticCurvePoint alloc] initWithPointData:result];
    
    return newPoint;
}

@end
