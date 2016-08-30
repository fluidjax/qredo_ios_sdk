//
//  QredoNetworkTime.h
//
//  Created by Christopher Morris on 19/04/2016.
//  Copyright © 2016 Qredo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QredoNetworkTime : NSObject

+(id)start;
+(NSDate*)dateTime;
+(NSDate*)dateTEST; //the calculated date from SSL has 33 seconds added

@end
