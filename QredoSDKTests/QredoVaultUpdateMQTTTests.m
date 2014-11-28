#import "QredoVaultUpdateTests.h"
#import "QredoTestConfiguration.h"

@interface QredoVaultUpdateMQTTTests : QredoVaultUpdateTests

@end

@implementation QredoVaultUpdateMQTTTests

- (void)setUp {
    [super setUp];
    self.serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    [self authoriseClient];
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
