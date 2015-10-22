#import <Foundation/Foundation.h>

@interface NSSet (QredoSetEquality)

- (NSComparisonResult)compare:(NSSet *)other;

@end