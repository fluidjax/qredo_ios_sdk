/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@interface QredoNetworkTime :NSObject

+(id)start;
+(NSDate *)dateTime;
+(NSDate *)dateTEST;  //the calculated date from SSL has 33 seconds added

@end
