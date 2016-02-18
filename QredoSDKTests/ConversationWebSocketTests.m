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



- (void)testConversationMultiple{
    //The pauses in this test are required to fix subscribe delay issue.
    //see "docs/bugs/IOS SDK Rendezvous Subscribe Failure.pdf"

    self.continueAfterFailure = YES;

    for (int i = 0; i < 100; i++){ //failing
        NSLog(@"Run number: %@", @(i));
        @autoreleasepool {
            [super testConversation];
        }
    }
}

//- (void)testMetadataOfEphemeralConversation {
//    [super testMetadataOfEphemeralConversation];
//}
//
//- (void)testMetadataOfPersistentConversation {
//    [super testMetadataOfPersistentConversation];
//}

@end
