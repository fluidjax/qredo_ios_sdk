/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

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

// This test has frequently helped in triggering intermittent bugs
- (void)testConversationMultiple {
    
    for (int i = 0; i < 10; i++)
    {
        NSLog(@"Test %d", i);
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
