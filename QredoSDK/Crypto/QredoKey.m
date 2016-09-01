/* HEADER GOES HERE */
#import "QredoKey.h"

@interface QredoKey ()

@end

@implementation QredoKey

-(NSData *)convertKeyToNSData {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass",NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
