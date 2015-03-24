/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface NSDictionary (Contains)

- (BOOL)containsDictionary:(NSDictionary*)subdictionary comparison:(BOOL(^)(id a, id b))comparison;

@end
