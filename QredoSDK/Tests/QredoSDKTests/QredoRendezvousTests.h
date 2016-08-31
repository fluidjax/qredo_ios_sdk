#import <XCTest/XCTest.h>
#import "QredoXCTestCase.h"
#import "QredoRendezvous.h"
#import "QredoRendezvousPrivate.h"
#import "QredoPrivate.h"


@interface QredoRendezvousTests : QredoXCTestCase


- (void)authoriseClient;
- (void)testCreateRendezvousAndGetResponses;
- (void)testCreateAndFetchAnonymousRendezvous;
- (void)testCreateDuplicateAndFetchAnonymousRendezvous;
- (void)testCreateAndRespondAnonymousRendezvous;
- (void)testActivateExpiredRendezvous;
- (void)testActivateExpiredRendezvousAndFetchFromNewRef;


@end