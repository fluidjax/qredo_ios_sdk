/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface QredoBase58 : NSObject
+ (NSString *)encodeData:(NSData *)data;
+ (NSData *)decodeData:(NSString *)string;
@end
