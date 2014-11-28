#import "QredoVaultTests.h"
#import "QredoTestConfiguration.h"

@interface QredoVaultMQTTTests : QredoVaultTests

@end

@implementation QredoVaultMQTTTests

- (void)setUp {
    [super setUp];
    self.serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
    [self authoriseClient];
}

- (void)testPersistanceVaultId {
    [super testPersistanceVaultId];
}

- (void)testPutItem {
    [super testPutItem];
}

- (void)testPutItemMultiple {
    [super testPutItemMultiple];
}

- (void)testGettingItems {
    [super testGettingItems];
}

- (void)testEnumeration {
    [super testEnumeration];
}

- (void)testEnumerationReturnsCreatedItem {
    [super testEnumerationReturnsCreatedItem];
}

- (void)testEnumerationAbortsOnStop {
    [super testEnumerationAbortsOnStop];
}

- (void)testListener {
    [super testListener];
}

- (void)testVaultItemMetadataAndMutableMetadata {
    [super testVaultItemMetadataAndMutableMetadata];
}
@end
