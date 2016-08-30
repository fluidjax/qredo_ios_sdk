/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface NSData (ParseHex)

+ (instancetype)dataWithHexString:(NSString *)hexString;

@end
