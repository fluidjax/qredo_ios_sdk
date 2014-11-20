//
//  NSDictionary+Contains.h
//  QredoSDK_nopods
//
//  Created by Dmitry Matyukhin on 20/11/2014.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Contains)

- (BOOL)containsDictionary:(NSDictionary*)subdictionary comparison:(BOOL(^)(id a, id b))comparison;

@end
