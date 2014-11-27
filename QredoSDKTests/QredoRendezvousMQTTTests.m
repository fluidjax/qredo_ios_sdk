#import "QredoTestConfiguration.h"
#import "QredoRendezvousTests.h"

@interface QredoRendezvousMQTTTests : QredoRendezvousTests

@end

@implementation QredoRendezvousMQTTTests

- (void)setUp {
    [super setUp];

    self.serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
}

- (void)testCreateRendezvous {
    [super testCreateRendezvous];
}

@end