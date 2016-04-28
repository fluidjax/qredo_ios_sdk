//
//  QredoNetworkTime
//
//  Created by Christopher Morris on 19/04/2016.
//  Copyright © 2016 Qredo. All rights reserved.
//

// Uses three sources of time
// 1 NTP
// 2 TLS requests to google.com
// 3 Local Time
// Date returned depends on which values are available, and whether or not NTP has been sanity checked against TLS
// See +(NSDate*)date
// For logic to determine which value is returned


#import "QredoNetworkTime.h"
#import "SSLTimeSyncWorker.h"
#import "ios-ntp.h"
#import "QredoLogger.h"

static int MAX_ACCEPTABLE_NTP_TLS_DIFF = 5;

@interface QredoNetworkTime ()
@property (strong) NSMutableArray *serversList;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NetworkClock *netClock;
@property (assign) int activeCounter;
@end

@implementation QredoNetworkTime


+(id)start{
    static QredoNetworkTime *tlsDate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tlsDate = [[self alloc] init];
        tlsDate.queue = dispatch_queue_create("dateRetrieveQueue",NULL);
        tlsDate.netClock = [NetworkClock sharedNetworkClock];
        [tlsDate loadServerList];
    });
    return tlsDate;
}


+(NSDate*)dateTEST{
    //this returns the guessed date + 33 seconds for testing
    QredoNetworkTime *server = [QredoNetworkTime start];
    return [server dateGuessForFirstServeTEST];
}


-(NSDate*)dateGuessForFirstServeTEST{
    SSLTimeSyncWorker *swds =  [self.serversList firstObject];
    NSDate *guessTime = [swds guessTime];
    if (!guessTime)return [NSDate date];
    NSTimeInterval interval = [guessTime timeIntervalSince1970]+33;
    NSDate *calculatedDate = [NSDate dateWithTimeIntervalSince1970:interval];
    return calculatedDate;
}


-(NSDate*)ntpDate{
    return [self.netClock networkTime];
}


+(NSDate*)dateTime{
    return [NSDate date];
//    QredoNetworkTime *server = [QredoNetworkTime start];
//    NSDate *tlsDate = [server dateGuessForFirstServer];
//    NSDate *ntpDate = [server ntpDate];
//    NSDate *localDate =  [NSDate date];
//
//    
//    //best case return ntpdate santinty checked with tlsdate
//    if (tlsDate && ntpDate){
//        //do sanity check
//        if ([server sanityCheck:ntpDate with:tlsDate]){
//            QredoLogDebug(@"DATE: Using sanity checked NTP Date %@", ntpDate);
//            return ntpDate;
//        }else{
//            //ntpDate is more than X seconds off - this shouldnt be happening
//            QredoLogWarning(@"DATE: NTP fails sanity - Using local %@", localDate);
//            return localDate;
//        }
//    }
//    
//    //return tlsdate its better than the local date
//    if (tlsDate && !ntpDate){
//        QredoLogWarning(@"DATE: Using TLS Date (no NTP) %@", tlsDate);
//        return tlsDate;
//    }
//    
//    QredoLogWarning(@"DATE: Fallback to Local date %@", localDate);
//    //return the local date
//    return localDate;
}


-(BOOL)sanityCheck:(NSDate*)dateOne with:(NSDate*)dateTwo{
    NSTimeInterval d1 = [dateOne timeIntervalSince1970];
    NSTimeInterval d2 = [dateTwo timeIntervalSince1970];
    NSTimeInterval difference = d1-d2;
    if (fabs(difference)>MAX_ACCEPTABLE_NTP_TLS_DIFF)return false;
    return true;
}


-(NSDate*)dateGuessForFirstServer{
    SSLTimeSyncWorker *swds =  [self.serversList firstObject];
    return [swds guessTime];
}


-(void)report{
    for (SSLTimeSyncWorker *swds in self.serversList){
        NSLog(@"Server:%@    url:%@",[swds guessTime],swds.urlString);
    }
}


-(double)getDifference{
    double total=0;
    int count=0;
    for (SSLTimeSyncWorker *swds in self.serversList){
        if (swds.averageDifference){
            total+=swds.averageDifference;
            count++;
        }
    }
    if (count>0){
        return total/(double)count;
    }
    return 0;
}


-(void)loadServerList{
    self.serversList = [[NSMutableArray alloc] init];
    [self addServer:@"https://www.google.com"];
//    [self addServer:@"https://www.youtube.com"];
//    [self addServer:@"https://www.facebook.com"];
//    [self addServer:@"https://www.amazon.com"];
//    [self addServer:@"https://twitter.com"];
}


-(void)addServer:(NSString*)urlString{
    SSLTimeSyncWorker *server = [[SSLTimeSyncWorker alloc] initWithURLString:urlString];
    [self.serversList addObject:server];
    dispatch_async(self.queue,^{
        [server retrieveDate];
    });
}


-(void)reportFromDelegate {
    //this is called when the NetworkClock has a time to report (I didnt invent the method name, but can't change it otherwise we cant uses PODs)
    NSLog(@"LocalTime:%@    NetworkTime:%@     Offset:%f", [QredoNetworkTime dateTime], self.netClock.networkTime, self.netClock.networkOffset);
}


@end
