/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface QredoClientId : NSObject

+ (instancetype)randomClientId;
+ (instancetype)clientIdFromData:(NSData *)data;
- (NSData *)getData;
- (NSString *)getSafeString;

@end
