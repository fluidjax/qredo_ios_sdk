#import <XCTest/XCTest.h>

@interface QredoRendezvousTests : XCTestCase

@property BOOL useMQTT;

- (void)authoriseClient;
- (void)testCreateRendezvous_NoSigningHandler;
- (void)testCreateRendezvous_NilSigningHandler;
- (void)testCreateAndRespondRendezvous;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519NoPrefixTag;
- (void)testCreateAuthenticatedRendezvousED25519EmptyTag;
- (void)testCreateAuthenticatedRendezvousED25519NilTag;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519ForgedSignature;

@end