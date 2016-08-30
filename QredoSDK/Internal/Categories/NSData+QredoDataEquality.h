#import <Foundation/Foundation.h>

@interface NSData (QredoDataEquality)

- (NSComparisonResult)compare:(NSData *)other;

@end