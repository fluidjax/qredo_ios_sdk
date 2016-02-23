/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface NSDictionary (IndexableSet)

- (NSSet*) indexableSet;

@end


@interface NSSet (IndexableSet)

- (NSDictionary*)dictionaryFromIndexableSet;

@end