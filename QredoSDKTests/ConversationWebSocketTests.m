#import "ConversationTests.h"

@interface ConversationWebSocketTests : ConversationTests

@end

@implementation ConversationWebSocketTests

- (void)setUp {
    self.transportType = QredoClientOptionsTransportTypeWebSockets;
    [super setUp];
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

// This test has frequently helped in triggering intermittent bugs
- (void)testConversationMultiple
{
    // TODO: DH - Sometimes an iteration of this test fails, so don't abort everything on this failing
    self.continueAfterFailure = YES;
    
    for (int i = 0; i < 20; i++)
    {
        NSLog(@"\n\n\n\n******** Start Test %d ********\n", i);
        [super testConversation];
        NSLog(@"\n******** End Test %d ********\n\n\n\n", i);
    }
}

- (void)testMetadataOfEphemeralConversation {
    [super testMetadataOfEphemeralConversation];
}

- (void)testMetadataOfPersistentConversation {
    [super testMetadataOfPersistentConversation];
}

@end
