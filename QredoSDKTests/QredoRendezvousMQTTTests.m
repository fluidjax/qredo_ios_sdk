#import "QredoTestConfiguration.h"
#import "QredoRendezvousTests.h"

@interface QredoRendezvousMQTTTests : QredoRendezvousTests

@end

@implementation QredoRendezvousMQTTTests

- (void)setUp {
    [super setUp];
    self.serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    [self authoriseClient];
}

- (void)testCreateRendezvous {
    [super testCreateRendezvous];
}

- (void)testCreateAndRespondRendezvous {
    [super testCreateAndRespondRendezvous];
}

// This test has frequently helped in triggering intermittent bugs
- (void)testCreateRendezvousMultiple {
    
    for (int i = 0; i < 10; i++)
    {
        NSLog(@"Test %d", i);
        [super testCreateAndRespondRendezvous];
    }
}

@end