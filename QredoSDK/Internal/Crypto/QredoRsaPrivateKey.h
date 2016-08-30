/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoPrivateKey.h"

@interface QredoRsaPrivateKey : QredoPrivateKey

@property (nonatomic, strong, readonly) NSData *version;
@property (nonatomic, strong, readonly) NSData *modulus;
@property (nonatomic, strong, readonly) NSData *publicExponent;
@property (nonatomic, strong, readonly) NSData *privateExponent;
@property (nonatomic, strong, readonly) NSData *crtPrime1;
@property (nonatomic, strong, readonly) NSData *crtPrime2;
@property (nonatomic, strong, readonly) NSData *crtExponent1;
@property (nonatomic, strong, readonly) NSData *crtExponent2;
@property (nonatomic, strong, readonly) NSData *crtCoefficient;

- (instancetype)initWithModulus:(NSData*)modulus publicExponent:(NSData*)publicExponent privateExponent:(NSData*)privateExponent crtPrime1:(NSData*)crtPrime1 crtPrime2:(NSData*)crtPrime2 crtExponent1:(NSData*)crtExponent1  crtExponent2:(NSData*)crtExponent2 crtCoefficient:(NSData*)crtCoefficient;
- (instancetype)initWithPkcs1KeyData:(NSData*)keyData;
- (instancetype)initWithPkcs8KeyData:(NSData*)keyData;
- (NSData*)convertToPkcs1Format;
- (NSData*)convertToPkcs8Format;

@end
