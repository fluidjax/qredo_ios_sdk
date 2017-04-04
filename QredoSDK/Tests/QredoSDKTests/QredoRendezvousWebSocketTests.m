/* HEADER GOES HERE */
#import "QredoRendezvousTests.h"

@interface QredoRendezvousWebSocketTests :QredoRendezvousTests

@end

@implementation QredoRendezvousWebSocketTests

-(void)setUp {
    self.transportType = QredoClientOptionsTransportTypeWebSockets;
    [super setUp];
}


//TODO: DH - restore modified tests
-(void)testCreateRendezvous_NoSigningHandler {
    //[super testCreateRendezvous_NoSigningHandler];
    //XCTFail(@"Restore modified tests");
}


-(void)testCreateRendezvousAndGetResponses {
    [super testCreateRendezvousAndGetResponses];
}


//TODO: DH - restore modified tests
-(void)testCreateRendezvous_NilSigningHandler {
    //[super testCreateRendezvous_NilSigningHandler];
    //XCTFail(@"Restore modified tests");
}



-(void)testCreateAndFetchAnonymousRendezvous {
    [super testCreateAndFetchAnonymousRendezvous];
}


-(void)testCreateDuplicateAndFetchAnonymousRendezvous {
    [super testCreateDuplicateAndFetchAnonymousRendezvous];
}


//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_WithPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_EmptyPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_WithPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_WithPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_EmptyPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousED25519_ExternalKeys_EmptyPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_WithPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousRsa2048_InternalKeys_EmptyPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa2048_ExternalKeys_WithPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousRsa2048_ExternalKeys_WithPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_WithPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousRsa4096_InternalKeys_EmptyPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousRsa4096_ExternalKeys_WithPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousRsa4096_ExternalKeys_WithPrefix];
//}
//
//-(void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_EmptyPrefix_Invalid
//{
//[super testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_EmptyPrefix_Invalid];
//}
//
//-(void)testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_WithPrefix_Invalid
//{
//[super testCreateAndRespondAuthenticatedRendezvousX509Pem_InternalKeys_WithPrefix_Invalid];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousX509Pem_ExternalKeys_WithPrefix
//{
//[super testCreateAndRespondAuthenticatedRendezvousX509Pem_ExternalKeys_WithPrefix];
//}
//
//- (void)testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix
//{
//[super testCreateAuthenticatedRendezvousED25519_InternalKeys_NilPrefix];
//}
//
//- (void)testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature
//{
//[super testCreateAndRespondAuthenticatedRendezvousED25519_InternalKeys_ForgedSignature];
//}

@end
