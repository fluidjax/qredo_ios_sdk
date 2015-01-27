/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface NSDictionary (QUIDSerialization)
- (NSDictionary*)quidToStringDictionary;
- (NSDictionary*)stringToQuidDictionary;
@end
