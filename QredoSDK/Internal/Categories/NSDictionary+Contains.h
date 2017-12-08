/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface NSDictionary (Contains)

-(BOOL)containsDictionary:(NSDictionary *)subdictionary comparison:(BOOL (^)(id a,id b))comparison;

@end
