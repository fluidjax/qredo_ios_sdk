/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoPublicKey.h"
#import "QredoPrivateKey.h"

@interface QredoKeyPair : NSObject

@property (nonatomic, strong, readonly) QredoPublicKey *publicKey;
@property (nonatomic, strong, readonly) QredoPrivateKey *privateKey;

- (instancetype)initWithPublicKey:(QredoPublicKey*)publicKey privateKey:(QredoPrivateKey*)privateKey;

@end
