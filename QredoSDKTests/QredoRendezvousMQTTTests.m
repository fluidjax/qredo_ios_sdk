#import "QredoRendezvousTests.h"

@interface QredoRendezvousMQTTTests : QredoRendezvousTests

@end

@implementation QredoRendezvousMQTTTests

- (void)setUp {
    [super setUp];

    self.useMQTT = YES;
}

- (void)testCreateRendezvous {
    [super testCreateRendezvous];
}

@end