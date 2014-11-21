#import "QredoTestConfiguration.h"
#import "ConversationTests.h"

@interface ConversationMQTTTests : ConversationTests

@end

@implementation ConversationMQTTTests

- (void)setUp {
    [super setUp];
    self.serviceURL = [NSURL URLWithString:QREDO_MQTT_SERVICE_URL];
}

@end
