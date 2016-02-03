#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoXCTestCase.h"

@interface QredoVaultUpdateTests : QredoXCTestCase

@property (nonatomic) QredoClientOptionsTransportType transportType;

- (void)authoriseClient;
- (void)testGettingItems;
- (void)testPutItems;
- (void)testDeleteItems;

@end
