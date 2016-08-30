/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface QredoEllipticCurvePoint : NSObject

@property (nonatomic, strong, readonly) NSData *data;

+ (instancetype)pointWithData:(NSData*)pointData;
- (instancetype)initWithPointData:(NSData*)pointData;
- (QredoEllipticCurvePoint*)multiplyWithPoint:(QredoEllipticCurvePoint*)point;

@end
