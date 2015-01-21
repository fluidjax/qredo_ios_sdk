#import <XCTest/XCTest.h>

@interface QredoRendezvousTests : XCTestCase

@property BOOL useMQTT;

- (void)authoriseClient;
- (void)testCreateRendezvous;
- (void)testCreateAndRespondRendezvous;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519NoTag;
- (void)testCreateAndRespondAuthenticatedRendezvousED25519ForgedSignature;

@end