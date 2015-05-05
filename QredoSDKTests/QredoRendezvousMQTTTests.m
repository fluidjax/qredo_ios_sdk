#import "QredoRendezvousTests.h"

@interface QredoRendezvousMQTTTests : QredoRendezvousTests

@end

@implementation QredoRendezvousMQTTTests

- (void)setUp {
    self.transportType = QredoClientOptionsTransportTypeMQTT;
    [super setUp];
}

// TODO: DH - restore modified tests
- (void)testCreateRendezvous_NoSigningHandler {
//    [super testCreateRendezvous_NoSigningHandler];
    XCTFail(@"Restore modified tests");
}

- (void)testCreateRendezvousAndGetResponses
{
    [super testCreateRendezvousAndGetResponses];
}
// TODO: DH - restore modified tests
- (void)testCreateRendezvous_NilSigningHandler {
//    [super testCreateRendezvous_NilSigningHandler];
    XCTFail(@"Restore modified tests");
}

- (void)testCreateAndRespondAnonymousRendezvous {
    [super testCreateAndRespondAnonymousRendezvous];
}

// This test has frequently helped in triggering intermittent bugs
- (void)testCreateRendezvousMultiple
{
    // TODO: DH - Sometimes an iteration of this test fails, so don't abort everything on this failing
    self.continueAfterFailure = YES;

    for (int i = 0; i < 10; i++)
    {
        NSLog(@"Test %d", i);
        [super testCreateAndRespondAnonymousRendezvous];
    }
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_WithPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_WithPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_EmptyPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_EmptyPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_ExternalKeys_WithPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousRsa2048_ExternalKeys_WithPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_ExternalKeys_WithPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousRsa4096_ExternalKeys_WithPrefix];
}

-(void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_EmptyPrefix_Invalid
{
    [super testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_EmptyPrefix_Invalid];
}

-(void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_WithPrefix_Invalid
{
    [super testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_WithPrefix_Invalid];
}

- (void)testCreateAndRespondAuthenticatedRendezvousX509Pem_ExternalKeys_WithPrefix
{
    [super testCreateAndRespondAuthenticatedRendezvousX509Pem_ExternalKeys_WithPrefix];
}

- (void)testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix
{
    [super testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix];
}

- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature
{
    [super testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature];
}

@end