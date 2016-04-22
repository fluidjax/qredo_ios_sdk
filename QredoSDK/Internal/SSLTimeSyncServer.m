//
//  secureDate.m
//  IOSTLSDate
//
//  Created by Christopher Morris on 19/04/2016.
//  Copyright © 2016 Qredo. All rights reserved.
//

#import "SSLTimeSyncServer.h"
#import "SSLTimeSyncWorker.h"


@interface SSLTimeSyncServer ()

@property (strong) NSMutableArray *serversList;
@property (nonatomic, strong) dispatch_queue_t queue;


@property (assign) int activeCounter;

@end

@implementation SSLTimeSyncServer


+(id)start{
    static SSLTimeSyncServer *tlsDate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tlsDate = [[self alloc] init];
        tlsDate.queue = dispatch_queue_create("dateRetrieveQueue",NULL);
        [tlsDate loadServerList];
    });
    return tlsDate;
}



+(NSDate*)dateTEST{
    //this returns the guessed date + 33 seconds for testing
    SSLTimeSyncServer *server = [SSLTimeSyncServer start];
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




+(NSDate*)date{
    SSLTimeSyncServer *server = [SSLTimeSyncServer start];
    return [server dateGuessForFirstServer];
}


-(NSDate*)dateGuessForFirstServer{
    SSLTimeSyncWorker *swds =  [self.serversList firstObject];
    NSDate *date = [swds guessTime];
    return date?date:[NSDate date];
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











@end
