/* HEADER GOES HERE */
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
