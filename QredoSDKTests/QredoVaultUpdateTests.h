#import <XCTest/XCTest.h>
#import "Qredo.h"

@interface QredoVaultUpdateTests : XCTestCase

@property (nonatomic) QredoClientOptionsTransportType transportType;

- (void)authoriseClient;
- (void)testGettingItems;
- (void)testPutItems;
- (void)testDeleteItems;

@end
