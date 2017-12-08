/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "NSDictionary+Contains.h"

@implementation NSDictionary (Contains)

-(BOOL)containsDictionary:(NSDictionary *)subdictionary comparison:(BOOL (^)(id a,id b))comparison {
    NSArray *allkeys = [subdictionary allKeys];
    
    if (!comparison)return NO;
    
    for (id key in allkeys){
        id value = [self objectForKey:key];
        id otherValue = [subdictionary objectForKey:key];
        
        if (!value || !otherValue)return NO;
        
        if (!comparison(value,otherValue))return NO;
    }
    
    return YES;
}


@end
