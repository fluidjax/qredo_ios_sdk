#import <XCTest/XCTest.h>

@interface QredoRendezvousTests : XCTestCase

@property BOOL useMQTT;

- (void)authoriseClient;
// TODO: DH - restore modified tests
//- (void)testCreateRendezvous_NoSigningHandler;
//- (void)testCreateRendezvous_NilSigningHandler;
- (void)testCreateAndRespondAnonymousRendezvous;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix;
- (void)testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature;

@end