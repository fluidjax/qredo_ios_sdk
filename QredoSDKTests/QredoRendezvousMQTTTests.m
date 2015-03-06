#import "QredoRendezvousTests.h"

@interface QredoRendezvousMQTTTests : QredoRendezvousTests

@end

@implementation QredoRendezvousMQTTTests

- (void)setUp {
    self.useMQTT = YES;
    [super setUp];
}

- (void)testCreateRendezvous_NoSigningHandler {
    [super testCreateRendezvous_NoSigningHandler];
}

- (void)testCreateRendezvous_NilSigningHandler {
    [super testCreateRendezvous_NilSigningHandler];
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

- (void)testCreateAndRespondAuthenticatedRendezvousED25519NoPrefixTag {
    [super testCreateAndRespondAuthenticatedRendezvousED25519NoPrefixTag];
}

- (void)testCreateAuthenticatedRendezvousED25519EmptyTag {
    [super testCreateAuthenticatedRendezvousED25519EmptyTag];
}

- (void)testCreateAuthenticatedRendezvousED25519NilTag {
    [super testCreateAuthenticatedRendezvousED25519NilTag];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519ForgedSignature {
    [super testCreateAndRespondAuthenticatedRendezvousED25519ForgedSignature];
}

@end