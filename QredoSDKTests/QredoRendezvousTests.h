#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoRendezvous.h"
#import "QredoRendezvousPrivate.h"
#import "QredoPrivate.h"


@interface QredoRendezvousTests : QredoXCTestCase

@property (nonatomic) QredoClientOptionsTransportType transportType;

- (void)authoriseClient;



- (void)testCreateRendezvousAndGetResponses;

- (void)testCreateAndFetchAnonymousRendezvous;
- (void)testCreateDuplicateAndFetchAnonymousRendezvous;
- (void)testCreateAndRespondAnonymousRendezvous;
//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_WithPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_EmptyPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_ExternalKeys_WithPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_ExternalKeys_WithPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_WithPrefix_Invalid;
//- (void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_EmptyPrefix_Invalid;
//- (void)testCreateAndRespondAuthenticatedRendezvousX509Pem_ExternalKeys_WithPrefix;
//- (void)testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix;
//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature;
- (void)testActivateExpiredRendezvous;
- (void)testActivateExpiredRendezvousAndFetchFromNewRef;


@end