#import "QredoRendezvousTests.h"

@interface QredoRendezvousMQTTTests : QredoRendezvousTests

@end

@implementation QredoRendezvousMQTTTests

- (void)setUp {
    self.useMQTT = YES;
    [super setUp];
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

- (void)testCreateAndRespondAuthenticatedRendezvousED25519 {
    [super testCreateAndRespondAuthenticatedRendezvousED25519];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519NoTag {
    [super testCreateAndRespondAuthenticatedRendezvousED25519NoTag];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519ForgedSignature {
    [super testCreateAndRespondAuthenticatedRendezvousED25519ForgedSignature];
}

@end