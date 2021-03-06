/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "NSDictionary+IndexableSet.h"
#import "QredoClient.h"

@implementation NSDictionary (IndexableSet)

-(NSSet *)indexableSet {
    NSArray *sortedKeys = [[self allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableSet *resultSet = [NSMutableSet set];
    
    for (NSString *key in sortedKeys){
        id object = [self objectForKey:key];
        
        id value = nil;
        
        if ([object isKindOfClass:[QredoQUID class]]){
            value = [QLFSV sQUIDWithV:(QredoQUID *)object];
        } else if ([object isKindOfClass:[NSNumber class]]){
            NSNumber *number = (NSNumber *)object;
            
            if (strcmp([number objCType],@encode(BOOL)) == 0 ||
                strcmp([number objCType],@encode(char)) == 0
                ){
                value = [QLFSV sBoolWithV:[number boolValue]];
            } else {
                value = [QLFSV sInt64WithV:[number longLongValue]];
            }
        } else if ([object isKindOfClass:[NSDate class]]){
            value = [QLFSV sDTWithV:[QredoUTCDateTime dateTimeWithDate:object isUTC:true]];
        } else {
            value = [QLFSV sStringWithV:object];
        }
        
        [resultSet addObject:[QLFIndexable indexableWithKey:key value:value]];
    }
    
    return [resultSet copy]; //unmutable copy
}


@end


@implementation NSSet (IndexableSet)

-(NSDictionary *)dictionaryFromIndexableSet {
    NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];
    
    for (QLFIndexable *indexable in self){
        QLFSV *valueSV = indexable.value;
        __block id v = nil;
        
        [valueSV ifSBool:^(BOOL value) {
            v = @(value);
        }
                ifSInt64:^(int64_t value) {
                    v = @(value);
                }
                   ifSDT:^(QredoUTCDateTime *value) {
                       QredoUTCDateTime *qdate = (QredoUTCDateTime *)value;
                       v = qdate.asDate;
                   }
                 ifSQUID:^(QredoQUID *value) {
                     v = value;
                 }
               ifSString:^(NSString *value) {
                   v = value;
               }
                ifSBytes:^(NSData *value) {
                    v = value;
                }];
        
        if (v){
            [resultDictionary setObject:v forKey:indexable.key];
        }
    }
    
    return [resultDictionary copy]; //unmutable copy
}


@end
