#import "ConversationWebSocketTests.h"

@implementation ConversationWebSocketTests

-(void)setUp {
    self.transportType = QredoClientOptionsTransportTypeWebSockets;
    [super setUp];
}


-(void)testConversationCreation {
    [super testConversationCreation];
}


-(void)testRespondingToConversation {
    [super testRespondingToConversation];
}


-(void)testConversation {
    [self buildStack2];
}


@end
