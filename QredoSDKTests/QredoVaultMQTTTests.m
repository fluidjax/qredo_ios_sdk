#import "QredoVaultTests.h"
#import "QredoTestConfiguration.h"

@interface QredoVaultMQTTTests : QredoVaultTests

@end

@implementation QredoVaultMQTTTests

- (void)setUp {
    [super setUp];

    self.serviceURL = QREDO_MQTT_SERVICE_URL;
}

- (void)testPersistanceVaultId {
    [super testPersistanceVaultId];
}

- (void)testGettingItems {
    [super testGettingItems];
}

- (void)testEnumeration {
    [super testEnumeration];
}

- (void)testEnumerationReturnsCreatedItem {
    [super testEnumerationReturnsCreatedItem];
}

- (void)testListener {
    [super testListener];
}

@end
