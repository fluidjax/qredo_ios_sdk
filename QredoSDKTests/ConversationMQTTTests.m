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
