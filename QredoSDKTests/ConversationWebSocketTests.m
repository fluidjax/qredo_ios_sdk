#import "ConversationWebSocketTests.h"

@implementation ConversationWebSocketTests

- (void)setUp {
    self.transportType = QredoClientOptionsTransportTypeWebSockets;
    [super setUp];
}

- (void)testConversationCreation{
    [super testConversationCreation];
}

- (void)testRespondingToConversation{
    [super testRespondingToConversation];
}

- (void)testConversation{
    [super testConversation];
}

// This test has frequently helped in triggering intermittent bugs
- (void)testConversationMultiple{
    // TODO: DH - Sometimes an iteration of this test fails, so don't abort everything on this failing
    self.continueAfterFailure = YES;
    
//    NSStreamEventNone = 0,
//    NSStreamEventOpenCompleted = 1,
//    NSStreamEventHasBytesAvailable = 2,
//    NSStreamEventHasSpaceAvailable = 4,
//    NSStreamEventErrorOccurred = 8,
//    NSStreamEventEndEncountered = 16
    

    
    for (int i = 0; i < 100000; i++){ //failing
        NSLog(@"Run number: %@", @(i));
        @autoreleasepool {
            [super testConversation];
        }

        
    }
}

- (void)testMetadataOfEphemeralConversation {
    [super testMetadataOfEphemeralConversation];
}

- (void)testMetadataOfPersistentConversation {
    [super testMetadataOfPersistentConversation];
}

@end
