/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@interface NSDictionary (Contains)

-(BOOL)containsDictionary:(NSDictionary *)subdictionary comparison:(BOOL (^)(id a,id b))comparison;

@end
