/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


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
