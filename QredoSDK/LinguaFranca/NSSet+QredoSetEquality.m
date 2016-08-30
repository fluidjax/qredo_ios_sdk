#import "NSSet+QredoSetEquality.h"

static int signum(long n);

@implementation NSSet (QredoSetEquality)

- (NSComparisonResult)compare:(NSSet *)other {

    long ourlen   = [self count];
    long theirlen = [other count];
    int cmp = signum(ourlen - theirlen);
    if (cmp != 0) {
        return (NSComparisonResult)cmp;
    }

    NSArray *ours   = [[self   allObjects] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *theirs = [[other allObjects] sortedArrayUsingSelector:@selector(compare:)];
    for (NSUInteger i = 0; i < ourlen; i++) {
        id ourObject   = ours[i];
        id theirObject = theirs[i];
        cmp = [ourObject compare:theirObject];
        if (cmp != NSOrderedSame) {
            return (NSComparisonResult)cmp;
        }
    }

    return NSOrderedSame;

}

@end

static int signum(long n) {
    return (n>0)-(n<0);
}