/* HEADER GOES HERE */
//
//Created by Christopher Morris on 19/04/2016.
//Copyright © 2016 Qredo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSLTimeSyncWorker :NSObject
@property (assign) double averageDifference;
@property (strong) NSString *urlString;
@property (nonatomic,strong) dispatch_queue_t queue;

-(instancetype)initWithURLString:(NSString *)urlString;
-(void)retrieveDate;
-(NSDate *)guessTime;
@end
