/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


//Created by Christopher Morris on 19/04/2016.
//Copyright © 2016 Qredo. All rights reserved.
//



#import "SSLTimeSyncWorker.h"

@interface SSLTimeSyncWorker ()
@property (strong) NSMutableArray *serverHistory;
@end




@interface SecureWebDateServerTimeStamp :NSObject
@property (assign) NSTimeInterval timeToRetrieve;
@property (assign) NSTimeInterval correctTimeInterval;

@end


@implementation SecureWebDateServerTimeStamp
@end


@implementation SSLTimeSyncWorker
static const int HISTORY_SIZE = 5;
static const int MAX_TIME_TO_RETRIEVE = 5;

-(instancetype)initWithURLString:(NSString *)urlString {
    self = [super init];
    
    if (self){
        _urlString = urlString;
        _serverHistory = [[NSMutableArray alloc] init];
    }
    
    return self;
}


-(void)incomingDate:(NSDate *)serverDate timeToRetrieve:(NSTimeInterval)timeToRetrieve {
    if (timeToRetrieve > MAX_TIME_TO_RETRIEVE){
        [self scheduleNextRetrieve];
        return;
    }
    
    NSTimeInterval serverSinceTime = [serverDate timeIntervalSince1970] + 0.5;
    NSTimeInterval localSinceTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeInterval = localSinceTime - serverSinceTime;
    
    if (fabs(timeInterval) > 60 * 65){
        NSLog(@"The time is more than 65 minutes off");
        return;
    }
    
    self.averageDifference = (double)timeInterval;
    [self addNewValue:timeInterval retrieveTime:timeToRetrieve];
    
    
    
    //NSLog(@"Time Guess %@",[self guessTime]);
    
    
    [self scheduleNextRetrieve];
}


-(void)scheduleNextRetrieve {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,10 * NSEC_PER_SEC),self.queue,^{
        [self retrieveDate];
    });
}


-(void)addNewValue:(NSTimeInterval)timeInterval retrieveTime:(NSTimeInterval)retrieveTime {
    SecureWebDateServerTimeStamp *swdsts = [[SecureWebDateServerTimeStamp alloc] init];
    
    swdsts.timeToRetrieve = retrieveTime;
    swdsts.correctTimeInterval = timeInterval;
    
    
    [self.serverHistory addObject:swdsts];
    
    if ([self.serverHistory count] > HISTORY_SIZE){
        [self.serverHistory removeObjectAtIndex:0];
    }
}


-(NSDate *)guessTime {
    //get the
    NSTimeInterval lowestRetrieveTime = DBL_MAX;
    SecureWebDateServerTimeStamp *bestGuess;
    
    for (SecureWebDateServerTimeStamp *timestamp in self.serverHistory){
        NSTimeInterval retrieveTime = timestamp.timeToRetrieve;
        
        if (retrieveTime < lowestRetrieveTime){
            bestGuess = timestamp;
            lowestRetrieveTime = retrieveTime;
        }
    }
    
    if (bestGuess){
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval mod = bestGuess.correctTimeInterval;
        NSTimeInterval correctedTime = currentTime - mod;
        return [NSDate dateWithTimeIntervalSince1970:correctedTime];
    }
    
    return nil;
}


-(void)retrieveDate {
    NSURL *URL = [[NSURL alloc] initWithString:self.urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    //NSLog(@"%@ - Start ",[NSDate date]);
    [request setHTTPMethod:@"HEAD"];
    request.timeoutInterval = 10;
    
    __block NSDate *startDate = [NSDate date];
    __block NSURLSession *session = [NSURLSession sharedSession];
    __block NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                    completionHandler:
                                          ^(NSData *data,NSURLResponse *response,NSError *error) {
                                              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                              
                                              if (error){
                                                  NSLog(@"Error: %@",error.localizedDescription);
                                                  [self scheduleNextRetrieve];
                                              } else if ([httpResponse respondsToSelector:@selector(allHeaderFields)]){
                                                  NSDictionary *headerFields = [httpResponse allHeaderFields];
                                                  NSString *lastModification = [headerFields objectForKey:@"Date"];
                                                  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                                  [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
                                                  NSDate *serverDate = [formatter dateFromString:lastModification];
                                                  NSTimeInterval timeToRetrieve = -[startDate timeIntervalSinceNow];
                                                  //NSLog(@"%@ - Server",serverDate);
                                                  //NSLog(@"%@ - End   ",[NSDate date]);
                                                  [self incomingDate:serverDate
                                                     timeToRetrieve :timeToRetrieve];
                                              }
                                          }];
    [task resume];
}


@end
