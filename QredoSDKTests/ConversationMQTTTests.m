/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "ConversationTests.h"

@interface ConversationMQTTTests : ConversationTests

@end

@implementation ConversationMQTTTests

- (void)setUp {
    self.transportType = QredoClientOptionsTransportTypeMQTT;
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
        [super testConversation];
    }
}

- (void)testMetadataOfEphemeralConversation {
    [super testMetadataOfEphemeralConversation];
}

- (void)testMetadataOfPersistentConversation {
    [super testMetadataOfPersistentConversation];
}


@end
