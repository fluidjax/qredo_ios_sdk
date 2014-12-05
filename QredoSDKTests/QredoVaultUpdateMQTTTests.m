#import "QredoVaultUpdateTests.h"

@interface QredoVaultUpdateMQTTTests : QredoVaultUpdateTests

@end

@implementation QredoVaultUpdateMQTTTests

- (void)setUp {
    [super setUp];

    self.useMQTT = YES;
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
