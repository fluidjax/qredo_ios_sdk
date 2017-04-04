//
//  QredoNetworkClock.m
//  QredoSDK
//
//  Created by Christopher Morris on 30/03/2017.
//
//

#import "QredoNetworkClock.h"


@interface QredoNetworkClock () {
    
    NSMutableArray *        timeAssociations;
    NSArray *               sortDescriptors;
    
    NSSortDescriptor *      dispersionSortDescriptor;
    dispatch_queue_t        associationDelegateQueue;
    
}

@end



@implementation QredoNetworkClock


/*┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
 ┃ Return the offset to network-derived UTC.                                                        ┃
 ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛*/
- (NSTimeInterval) networkOffset {
    
    if ([timeAssociations count] == 0) return 0.0;
    
    NSArray *       sortedArray = [timeAssociations sortedArrayUsingDescriptors:sortDescriptors];
    
    double          timeInterval = 0.0;
    short           usefulCount = 0;
    
    for (NetAssociation * timeAssociation in sortedArray) {
        if (timeAssociation.active) {
            if (timeAssociation.trusty) {
                usefulCount++;
                timeInterval = timeInterval + timeAssociation.offset;
                //              NSLog(@"[%@]: %f (%d)", timeAssociation.server, timeAssociation.offset*1000.0, usefulCount);
            }
            else {
                NSLog(@"AAA Clock•Drop: [%@]", timeAssociation.server);
                if ([timeAssociations count] > 8) {
                    [timeAssociations removeObject:timeAssociation];
                    [timeAssociation finish];
                }
            }
            
            if (usefulCount == 8) break;                // use 8 best dispersions
        }
    }
    
    if (usefulCount > 0) {
        timeInterval = timeInterval / usefulCount;
        //      NSLog(@"timeIntervalSinceDeviceTime: %f (%d)", timeInterval*1000.0, usefulCount);
    }
    
    return timeInterval;
}



@end
