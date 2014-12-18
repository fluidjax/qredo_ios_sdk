#import "ConversationTests.h"

@interface ConversationMQTTTests : ConversationTests

@end

@implementation ConversationMQTTTests

- (void)setUp {
    [super setUp];
    self.useMQTT = YES;
    [self authoriseClient];
}

- (void)testConversationCreation
{
    [super testConversationCreation];
}

- (void)testRespondingToConversation
{
    [super testRespondingToConversation];
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
