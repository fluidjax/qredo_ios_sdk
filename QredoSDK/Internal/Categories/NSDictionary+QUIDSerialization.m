/* HEADER GOES HERE */
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"
#import "NSDictionary+QUIDSerialization.h"

@implementation NSDictionary (QUIDSerialization)

-(NSDictionary *)quidToStringDictionary {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    NSArray *keys = [self allKeys];
    
    for (id key in keys){
        id newKey = key;
        if ([key isKindOfClass:[QredoQUID class]]){
            newKey = [key QUIDString];
        }
        [result setObject:[self objectForKey:key] forKey:newKey];
    }
    return [result copy];
}


-(NSDictionary *)stringToQuidDictionary {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *keys = [self allKeys];
    
    for (id key in keys){
        QredoQUID *newKey = [QredoQUID QUIDWithString:key];
        
        [result setObject:[self objectForKey:key] forKey:newKey];
    }
    
    return [result copy];
}


@end
