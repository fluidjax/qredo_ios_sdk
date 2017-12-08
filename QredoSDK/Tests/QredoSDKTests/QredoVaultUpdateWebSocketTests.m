/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoVaultUpdateTests.h"

@interface QredoVaultUpdateWebSocketTests :QredoVaultUpdateTests

@end

@implementation QredoVaultUpdateWebSocketTests

-(void)setUp {
    self.transportType = QredoClientOptionsTransportTypeWebSockets;
    [super setUp];
}


-(void)testGettingItems {
    [super testGettingItems];
}


-(void)testPutItems {
    [super testPutItems];
}


-(void)testDeleteItems {
    [super testDeleteItems];
}


@end
