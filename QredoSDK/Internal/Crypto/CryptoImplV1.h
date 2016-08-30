/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "CryptoImpl.h"

@interface CryptoImplV1 : NSObject<CryptoImpl>
+ (instancetype)sharedInstance;
@end
