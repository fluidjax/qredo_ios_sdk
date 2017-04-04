/* HEADER GOES HERE */
#import "NSArray+QredoArrayEquality.h"

static int signum(long n);

@implementation NSArray (QredoArrayEquality)

-(NSComparisonResult)compare:(NSArray *)object {
    long ourlen   = [self count];
    long theirlen = [object count];
    int cmp = signum(ourlen - theirlen);
    
    if (cmp != 0){
        return (NSComparisonResult)cmp;
    }
    
    for (NSUInteger i = 0; i < ourlen; i++){
        id ourObject   = self[i];
        id theirObject = object[i];
        cmp = [ourObject compare:theirObject];
        
        if (cmp != NSOrderedSame){
            return (NSComparisonResult)cmp;
        }
    }
    
    return NSOrderedSame;
}


@end

static int signum(long n) {
    return (n > 0) - (n < 0);
}