#import <XCTest/XCTest.h>
#import "Qredo.h"
#import "QredoXCTestCase.h"

@interface QredoVaultUpdateTests : QredoXCTestCase


- (void)authoriseClient;
- (void)testGettingItems;
- (void)testPutItems;
- (void)testDeleteItems;

@end
