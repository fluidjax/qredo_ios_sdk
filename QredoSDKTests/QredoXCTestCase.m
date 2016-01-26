//
//  QredoXCTestCase.m
//  QredoSDK
//
//  Created by Christopher Morris on 22/01/2016.
//
//

#import "QredoXCTestCase.h"

@implementation QredoXCTestCase



- (void)setUp {
    [super setUp];
    [self setLogLevel];
}

-(void)setLogLevel{
/*  Available debug levels
        [QredoLogger setLogLevel:QredoLogLevelNone];
        [QredoLogger setLogLevel:QredoLogLevelError];
        [QredoLogger setLogLevel:QredoLogLevelWarning];
        [QredoLogger setLogLevel:QredoLogLevelInfo];
        [QredoLogger setLogLevel:QredoLogLevelDebug];
        [QredoLogger setLogLevel:QredoLogLevelVerbose];
        [QredoLogger setLogLevel:QredoLogLevelInfo];
 */

    
    [QredoLogger setLogLevel:QredoLogLevelWarning];
}



-(void)loggingOff{
    [QredoLogger setLogLevel:QredoLogLevelNone];
}


-(void)loggingOn{
    [self setLogLevel];
}


@end
