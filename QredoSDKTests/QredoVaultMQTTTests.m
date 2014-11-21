#import "QredoVaultTests.h"
#import "QredoTestConfiguration.h"

@interface QredoVaultMQTTTests : QredoVaultTests

@end

@implementation QredoVaultMQTTTests

- (void)setUp {
    [super setUp];

    self.serviceURL = QREDO_MQTT_SERVICE_URL;
}

@end
