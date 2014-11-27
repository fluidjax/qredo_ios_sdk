#import "QredoTestConfiguration.h"
#import "ConversationTests.h"

@interface ConversationMQTTTests : ConversationTests

@end

@implementation ConversationMQTTTests

- (void)setUp {
    [super setUp];
    self.serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
}

- (void)testConversation
{
    [super testConversation];
}

- (void)testMetadataOfEphemeralConversation {
    [super testMetadataOfEphemeralConversation];
}

- (void)testMetadataOfPersistentConversation {
    [super testMetadataOfPersistentConversation];
}


@end
