/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoPrivateKey.h"

@interface QredoDhPrivateKey : QredoPrivateKey

@property (nonatomic, copy, readonly) NSData *data;

- (instancetype)initWithData:(NSData*)data;

@end
