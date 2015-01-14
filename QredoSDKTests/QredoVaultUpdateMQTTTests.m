#import "QredoVaultUpdateTests.h"

@interface QredoVaultUpdateMQTTTests : QredoVaultUpdateTests

@end

@implementation QredoVaultUpdateMQTTTests

- (void)setUp {
    self.useMQTT = YES;
    [super setUp];
}

- (void)testGettingItems {
    [super testGettingItems];
}

- (void)testPutItems {
    [super testPutItems];
}

- (void)testDeleteItems {
    [super testDeleteItems];
}


@end
