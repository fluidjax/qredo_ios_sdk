//
//  NSDictionary+Contains.m
//  QredoSDK_nopods
//
//  Created by Dmitry Matyukhin on 20/11/2014.
//
//

#import "NSDictionary+Contains.h"

@implementation NSDictionary (Contains)

- (BOOL)containsDictionary:(NSDictionary*)subdictionary comparison:(BOOL(^)(id a, id b))comparison
{
    NSArray *allkeys = [subdictionary allKeys];
    for (id key in allkeys) {
        id value = [self objectForKey:key];
        id otherValue = [subdictionary objectForKey:key];

        if (!value || !otherValue) return NO;

        if (!comparison(value, otherValue)) return NO;
    }

    return YES;
}

@end
