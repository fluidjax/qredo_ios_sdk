#import "QredoVaultUpdateTests.h"
#import "QredoTestConfiguration.h"

@interface QredoVaultUpdateMQTTTests : QredoVaultUpdateTests

@end

@implementation QredoVaultUpdateMQTTTests

- (void)setUp {
    [super setUp];

    self.serviceURL = QREDO_MQTT_SERVICE_URL;
}

@end
