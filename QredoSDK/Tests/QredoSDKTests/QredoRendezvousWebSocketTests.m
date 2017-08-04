/* HEADER GOES HERE */
#import "QredoRendezvousTests.h"

@interface QredoRendezvousWebSocketTests :QredoRendezvousTests

@end

@implementation QredoRendezvousWebSocketTests

-(void)setUp {
    self.transportType = QredoClientOptionsTransportTypeWebSockets;
    [super setUp];
}


-(void)testCreateRendezvousAndGetResponses {
    [super testCreateRendezvousAndGetResponses];
}

-(void)testCreateAndFetchAnonymousRendezvous {
    [super testCreateAndFetchAnonymousRendezvous];
}

-(void)testCreateDuplicateAndFetchAnonymousRendezvous {
    [super testCreateDuplicateAndFetchAnonymousRendezvous];
}


@end
