#import <XCTest/XCTest.h>

@interface QredoRendezvousTests : XCTestCase

@property BOOL useMQTT;

- (void)authoriseClient;
- (void)testCreateRendezvousAndGetResponses;
// TODO: DH - restore modified tests
//- (void)testCreateRendezvous_NoSigningHandler;
//- (void)testCreateRendezvous_NilSigningHandler;
- (void)testCreateAndRespondAnonymousRendezvous;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_WithPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_EmptyPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_ExternalKeys_WithPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_ExternalKeys_WithPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousX509_InternalKeys_WithPrefix_Invalid;
//- (void)testCreateAndRespondAuthenticatedRendezvousX509_InternalKeys_EmptyPrefix_Invalid;
//- (void)testCreateAndRespondAuthenticatedRendezvousX509_ExternalKeys_WithPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousX509_ExternalKeys_EmptyPrefix;
- (void)testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature;

@end