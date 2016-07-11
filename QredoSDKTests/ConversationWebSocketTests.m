#import "ConversationWebSocketTests.h"



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


//
//- (void)testConversationMultiple{
//    //The pauses in this test are required to fix subscribe delay issue.
//    //see "docs/bugs/IOS SDK Rendezvous Subscribe Failure.pdf"
//
//    self.continueAfterFailure = NO;
//    
//    
//    for (int i = 0; i < 5; i++){ //failing
//        NSLog(@"Run %i",i);
//        [self authoriseClient];
//        [self authoriseAnotherClient];
//        [super testConversation];
//        [self closeClientSessions];
//        
//        
//    }
//}

//- (void)testMetadataOfEphemeralConversation {
//    [super testMetadataOfEphemeralConversation];
//}
//
//- (void)testMetadataOfPersistentConversation {
//    [super testMetadataOfPersistentConversation];
//}

@end
