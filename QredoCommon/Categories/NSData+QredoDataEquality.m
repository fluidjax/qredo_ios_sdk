#import "NSData+QredoDataEquality.h"

static int signum(long n);

@implementation NSData (QredoDataEquality)

- (NSComparisonResult)compare:(NSData *)other {

    long ourlen   = [self length];
    long theirlen = [other length];
    int cmp = signum(ourlen - theirlen);
    if (cmp != 0) {
        return (NSComparisonResult)cmp;
    }

    const uint8_t *ours   = [self bytes];
    const uint8_t *theirs = [other bytes];
    for (int i = 0; i < ourlen; i++) {
        cmp = signum(ours[i] - theirs[i]);
        if (cmp != 0) {
            return (NSComparisonResult)cmp;
        }
    }

    return NSOrderedSame;

}

@end

static int signum(long n) {
    return (n>0)-(n<0);
}