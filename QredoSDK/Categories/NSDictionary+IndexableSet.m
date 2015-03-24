/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "NSDictionary+IndexableSet.h"
#import "QredoClient.h"

@implementation NSDictionary (IndexableSet)

- (NSSet*)indexableSet
{
    NSArray *sortedKeys = [[self allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableSet *resultSet = [NSMutableSet set];
    
    for (NSString *key in sortedKeys) {
        id object = [self objectForKey:key];

        id value = nil;

        if ([object isKindOfClass:[QredoQUID class]]) {
            value = [QredoSV sQUIDWithV:(QredoQUID *)object];
        } else if ([object isKindOfClass:[NSNumber class]]) {
            NSNumber *number = (NSNumber *)object;

            if (strcmp([number objCType], @encode(BOOL)) == 0 ||
                strcmp([number objCType], @encode(char)) == 0
                ) {
                value = [QredoSV sBoolWithV:number];
            } else {
                value = [QredoSV sInt64WithV:number];
            }
        } else if ([object isKindOfClass:[NSDate class]]) {
            value = [QredoSV sDTWithV:[QredoUTCDateTime dateTimeWithDate:object isUTC:true]];
        } else {
            value = [QredoSV sStringWithV:object];
        }
        
        [resultSet addObject:[QredoIndexable indexableWithKey:key value:value]];
    }
    
    return [resultSet copy]; // unmutable copy
}

@end


@implementation NSSet (IndexableSet)

- (NSDictionary*)dictionaryFromIndexableSet
{
    NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];
    
    for (QredoIndexable *indexable in self) {
        QredoSV *valueSV = indexable.value;
        id value = [valueSV performSelector:@selector(v)];

        if ([value isKindOfClass:[QredoUTCDateTime class]]) {
            QredoUTCDateTime *qdate = (QredoUTCDateTime*)value;
            value = qdate.asDate;
        }

        [resultDictionary setObject:value forKey:indexable.key];
    }
    
    return [resultDictionary copy]; // unmutable copy
}

@end