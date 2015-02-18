/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "Qredo.h"
#import "QredoClaimantAttestationProtocol.h"
#import "QredoAuthenticatoinClaimsProtocol.h"

#import "QredoPrimitiveMarshallers.h"
#import "QredoClientMarshallers.h"

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


static NSString *kAttestationPresentationMessageType = @"com.qredo.attestation.presentation";

static NSString *kBobAcceptedString = @"ACCEPTED";
static NSString *kBobRejectedString = @"REJECTED";

static NSTimeInterval kDefaultExpectationTimeout = 5.0;


//===============================================================================================================
#pragma mark - Alice device mock -
//===============================================================================================================


@interface ClaimantAttestationProtocolTest_AliceDevice : NSObject<QredoConversationDelegate>

@property (nonatomic, copy) void(^onPresentationRequest)(QredoConversationMessage *message, QredoPresentationRequest *presentationRequest, NSException *unmarshalException);
@property (nonatomic, copy) void(^onBobsChoice)(QredoConversationMessage *message, NSString *choice, NSException *unmarshalException);
@property (nonatomic, copy) void(^onBobsCancel)(QredoConversationMessage *message);

@property (nonatomic) QredoConversation *conversation;

- (void)respondToRendezvousWithTag:(NSString *)rendezvousTag completionHandler:(void(^)(NSError *error))completionHandler;

- (void)sendPresentationWithBlock:(QredoPresentation *(^)())presentationBlock
                completionHandler:(void(^)(NSError *error))completionHandler;

@end

@implementation ClaimantAttestationProtocolTest_AliceDevice
{
    QredoClient *_qredoClient;
}

- (void)respondToRendezvousWithTag:(NSString *)rendezvousTag completionHandler:(void (^)(NSError *))completionHandler
{
    [self obtainQredoClientWithCompletionHandler:^(QredoClient *qredoClient) {
        [qredoClient respondWithTag:rendezvousTag completionHandler:^(QredoConversation *conversation, NSError *error) {
            if (completionHandler) {
                _conversation = conversation;
                conversation.delegate = self;
                [conversation startListening];
                completionHandler(error);
            }
        }];
    }];
}

- (void)sendPresentationWithBlock:(QredoPresentation *(^)())presentationBlock
       completionHandler:(void(^)(NSError *error))completionHandler
{
    
    QredoPresentation *presentation = !presentationBlock ? nil : presentationBlock();
    
    NSData *messageValue
    = [QredoPrimitiveMarshallers marshalObject:presentation
                                    marshaller:[QredoClientMarshallers presentationMarshaller]];
    
    QredoConversationMessage *message
    = [[QredoConversationMessage alloc] initWithValue:messageValue
                                             dataType:kAttestationPresentationMessageType
                                        summaryValues:nil];
    [self.conversation publishMessage:message
                    completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error)
    {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

/**
 * Not thread safe. This needs to be used instead of reading _qredoClient.
 */
- (void)obtainQredoClientWithCompletionHandler:(void(^)(QredoClient *qredoClient))completionHandler
{
    
    if (!_qredoClient) {
        [QredoClient authorizeWithConversationTypes:@[@"test.chat"]
                                     vaultDataTypes:nil
                                            options:[[QredoClientOptions alloc] initWithMQTT:NO resetData:YES]
                                  completionHandler:^(QredoClient *newClient, NSError *error)
         {
             _qredoClient = newClient;
             if (completionHandler) {
                 completionHandler(_qredoClient);
             };
         }];
        return;
    }
    
    if (completionHandler) {
        completionHandler(_qredoClient);
    }
    
}

- (void)didRecivePresentationRequestMessage:(QredoConversationMessage *)message
{
    if ([message.value length] < 1) {
        if (self.onPresentationRequest) {
            self.onPresentationRequest(message, nil, nil);
        }
        return;
    }
    
    QredoPresentationRequest *presentationRequest = nil;
    NSException *unmarshalException = nil;
    @try {
        presentationRequest
        = [QredoPrimitiveMarshallers unmarshalObject:message.value
                                        unmarshaller:[QredoClientMarshallers presentationRequestUnmarshaller]];
    }
    @catch (NSException *exception) {
        unmarshalException = exception;
    }
    @finally {
        if (self.onPresentationRequest) {
            self.onPresentationRequest(message, presentationRequest, unmarshalException);
        }
    }
}

- (void)didReciveRelyingPartyDecisionMessage:(QredoConversationMessage *)message
{
    static NSString *const kDecodingExeptionName = @"ClaimantAttestationProtocolTest_AliceDevice_MessageDecodingError";
    if (self.onBobsChoice) {
        
        NSData *choiceData = message.value;
        if ([choiceData length] < 1) {
            self.onBobsChoice(message, nil, [NSException exceptionWithName:kDecodingExeptionName
                                                                    reason:@"MissingData" userInfo:nil]);
        }
        
        NSString *choiceString = [[NSString alloc] initWithData:choiceData encoding:NSUTF8StringEncoding];
        
        if ([choiceString isEqualToString:kBobAcceptedString]) {
            self.onBobsChoice(message, choiceString, nil);
        } else if ([choiceString isEqualToString:kBobRejectedString]) {
            self.onBobsChoice(message, choiceString, nil);
        } else {
            self.onBobsChoice(message, nil, [NSException exceptionWithName:kDecodingExeptionName
                                                                    reason:@"MalformedData" userInfo:nil]);
        }
    }
}

- (void)didReciveCancelMessage:(QredoConversationMessage *)message
{
    if (self.onBobsCancel) {
        self.onBobsCancel(nil);
    }
}

#pragma mark  QredoConversationDelegate
- (void)qredoConversation:(QredoConversation *)conversation
     didReceiveNewMessage:(QredoConversationMessage *)message
{
    NSString *messageType = message.dataType;
    if ([messageType isEqualToString:@"com.qredo.attestation.presentation.request"]) {
        [self didRecivePresentationRequestMessage:message];
    } else if ([messageType isEqualToString:@"com.qredo.attestation.relyingparty.decision"]) {
        [self didReciveRelyingPartyDecisionMessage:message];
    } else if ([messageType isEqualToString:@"com.qredo.attestation.cancel"]) {
        [self didReciveCancelMessage:message];
    } else {
        // TODO [GR]: Implement this.
    }
}


@end

typedef ClaimantAttestationProtocolTest_AliceDevice AlicesDevice;



//===============================================================================================================
#pragma mark - Delegate and datasource -
//===============================================================================================================


@interface ClaimantAttestationProtocolTest_ProtocolDelegate: NSObject<QredoClaimantAttestationProtocolDelegate, QredoClaimantAttestationProtocolDataSource>

@property (nonatomic, copy) void(^didStartBlock)(QredoClaimantAttestationProtocol *protocol);
@property (nonatomic, copy) void(^didRecivePresentations)(QredoClaimantAttestationProtocol *protocol, QredoPresentation *presentation);
@property (nonatomic, copy) void(^didReciveAuthentications)(QredoClaimantAttestationProtocol *protocol, QredoAuthenticationResponse *authentications);
@property (nonatomic, copy) void(^didFinishAuthenticationWithError)(QredoClaimantAttestationProtocol *protocol, NSError *error);
@property (nonatomic, copy) void(^didStartSendingRelyingPartyChoice)(QredoClaimantAttestationProtocol *protocol, BOOL claimsAccepted);
@property (nonatomic, copy) void(^didFinishSendingRelyingPartyChoice)(QredoClaimantAttestationProtocol *protocol);
@property (nonatomic, copy) void(^didFinishWithError)(QredoClaimantAttestationProtocol *protocol, NSError *error);

@property (nonatomic, copy) void(^authenticateRequest)(QredoClaimantAttestationProtocol *protocol,QredoAuthenticationRequest *authenticationRequest, NSString *authenticator, QredoClaimantAttestationProtocolAuthenticationCompletionHandler completionHandler);

@end

@implementation ClaimantAttestationProtocolTest_ProtocolDelegate


- (void)didStartClaimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
{
    if (self.didStartBlock) {
        self.didStartBlock(protocol);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
             didRecivePresentations:(QredoPresentation *)presentation
{
    if (self.didRecivePresentations) {
        self.didRecivePresentations(protocol, presentation);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
           didReciveAuthentications:(QredoAuthenticationResponse *)authentications
{
    if (self.didReciveAuthentications) {
        self.didReciveAuthentications(claimantAttestationProtocol, authentications);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
   didFinishAuthenticationWithError:(NSError *)error
{
    if (self.didFinishAuthenticationWithError) {
        self.didFinishAuthenticationWithError(claimantAttestationProtocol, error);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
  didStartSendingRelyingPartyChoice:(BOOL)claimsAccepted
{
    if (self.didStartSendingRelyingPartyChoice) {
        self.didStartSendingRelyingPartyChoice(claimantAttestationProtocol, claimsAccepted);
    }
}

- (void)claimantAttestationProtocolDidFinishSendingRelyingPartyChoice:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
{
    if (self.didFinishSendingRelyingPartyChoice) {
        self.didFinishSendingRelyingPartyChoice(claimantAttestationProtocol);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
                 didFinishWithError:(NSError *)error
{
    if (self.didFinishWithError) {
        self.didFinishWithError(claimantAttestationProtocol, error);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
                authenticateRequest:(QredoAuthenticationRequest *)authenticationRequest
                      authenticator:(NSString *)authenticator
                  completionHandler:(QredoClaimantAttestationProtocolAuthenticationCompletionHandler)completionHandler
{
    if (self.authenticateRequest) {
        self.authenticateRequest(protocol, authenticationRequest, authenticator, completionHandler);
    }
}

@end

typedef ClaimantAttestationProtocolTest_ProtocolDelegate ProtocolDelegate;



//===============================================================================================================
#pragma mark - Bob helper -
//===============================================================================================================


@interface ClaimantAttestationProtocolTest_BobHelper : NSObject<QredoRendezvousDelegate>

@property (nonatomic) QredoRendezvous *rendezvous;
@property (nonatomic) QredoConversation *conversation;

@property (nonatomic, copy) void (^rendezvousResponseHandler)(QredoConversation *conversation);

- (void)finishAuthenticationWithCompletionHandler:(QredoClaimantAttestationProtocolAuthenticationCompletionHandler)complitionHandler
                                            block:(QredoAuthenticationResponse *(^)())authenticationResponseBlock
                                       errorBlock:(NSError *(^)())errorBlock;

@end

@implementation ClaimantAttestationProtocolTest_BobHelper
{
    QredoClient *_qredoClient;
}


- (void)createRendezvousWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self obtainQredoClientWithCompletionHandler:^(QredoClient *qredoClient) {
        
        NSString *tag = [[QredoQUID QUID] QUIDString];
        
        QredoRendezvousConfiguration *configuration
        = [[QredoRendezvousConfiguration alloc] initWithConversationType:@"com.qredo.attesation.relyingparty"
                                                         durationSeconds:@(600)
                                                        maxResponseCount:@(1)];
        
        [qredoClient createRendezvousWithTag:tag
                               configuration:configuration
                           completionHandler:^(QredoRendezvous *rendezvous, NSError *error)
         {
             rendezvous.delegate = self;
             [rendezvous startListening];
             
             self.rendezvous = rendezvous;
             if (completionHandler) {
                 completionHandler(error);
             }
         }];
        
    }];
}


/**
 * Not thread safe. This needs to be used instead of reading _qredoClient.
 */
- (void)obtainQredoClientWithCompletionHandler:(void(^)(QredoClient *qredoClient))completionHandler
{
    
    if (!_qredoClient) {
        [QredoClient authorizeWithConversationTypes:@[@"test.chat"]
                                     vaultDataTypes:nil
                                            options:[[QredoClientOptions alloc] initWithMQTT:NO resetData:YES]
                                  completionHandler:^(QredoClient *newClient, NSError *error)
         {
             _qredoClient = newClient;
             if (completionHandler) {
                 completionHandler(_qredoClient);
             };
         }];
        return;
    }
    
    if (completionHandler) {
        completionHandler(_qredoClient);
    }
    
}

- (void)setRendezvousResponseHandler:(void (^)(QredoConversation *))rendezvousResponseHandler
{
    @synchronized(self) {
        if (_rendezvousResponseHandler == rendezvousResponseHandler) return;
        _rendezvousResponseHandler = rendezvousResponseHandler;
        if (_conversation && _rendezvousResponseHandler) {
            _rendezvousResponseHandler(_conversation);
            [self.rendezvous stopListening];
        }
    }
}


- (void)finishAuthenticationWithCompletionHandler:(QredoClaimantAttestationProtocolAuthenticationCompletionHandler)complitionHandler
                                            block:(QredoAuthenticationResponse *(^)())authenticationResponseBlock
                                       errorBlock:(NSError *(^)())errorBlock
{
    QredoAuthenticationResponse *response = authenticationResponseBlock ? authenticationResponseBlock() : nil;
    NSError *error = errorBlock ? errorBlock() : nil;
    complitionHandler(response, error);
    
}

#pragma mark QredoRendezvousDelegate

- (void)qredoRendezvous:(QredoRendezvous*)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    @synchronized(self) {
        self.conversation = conversation;
        if (self.rendezvousResponseHandler) {
            self.rendezvousResponseHandler(conversation);
            [self.rendezvous stopListening];
        }
    }
}


@end

typedef ClaimantAttestationProtocolTest_BobHelper BobHelper;



//===============================================================================================================
#pragma mark - Test class -
//===============================================================================================================


@interface ClaimantAttestationProtocolTest : XCTestCase
@property (nonatomic) BobHelper *bobHelper;
@property (nonatomic) AlicesDevice *alicesDevice;
@end

@implementation ClaimantAttestationProtocolTest

- (void)setUp
{
    [super setUp];
    
    self.bobHelper = [[BobHelper alloc] init];
    self.alicesDevice = [[AlicesDevice alloc] init];
    
    __block XCTestExpectation *bobCreatesRendezvousExpectation = [self expectationWithDescription:@"Bob creates rendezvous"];
    [self.bobHelper createRendezvousWithCompletionHandler:^(NSError *error) {
        XCTAssertNil(error);
        [bobCreatesRendezvousExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        bobCreatesRendezvousExpectation = nil;
    }];
    
    __block XCTestExpectation *bobsConversationIsCreatedExpectation = [self expectationWithDescription:@"Bob conversation is created"];
    [self.bobHelper setRendezvousResponseHandler:^(QredoConversation *conversation) {
        [bobsConversationIsCreatedExpectation fulfill];
    }];
    
    __block XCTestExpectation *aliceRespondsToRendezvousExpectation = [self expectationWithDescription:@"Alice responds to Bob's rendezvous"];
    [self.alicesDevice respondToRendezvousWithTag:self.bobHelper.rendezvous.tag
                                completionHandler:^(NSError *error)
     {
         XCTAssertNil(error);
         [aliceRespondsToRendezvousExpectation fulfill];
     }];

    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        aliceRespondsToRendezvousExpectation = nil;
        bobsConversationIsCreatedExpectation = nil;
    }];

    XCTAssertNotNil(self.bobHelper.conversation);
}

- (void)tearDown
{
    self.bobHelper = nil;
    self.alicesDevice = nil;
    [super tearDown];
}


#pragma mark Tests

- (void)testNormalFlow
{
    ProtocolDelegate *protocolDelegate = [[ProtocolDelegate alloc] init];
    
    QredoClaimantAttestationProtocol *protocol
    = [[QredoClaimantAttestationProtocol alloc] initWithConversation:self.bobHelper.conversation
                                                    attestationTypes:[NSSet setWithArray:@[@"picture", @"dob"]]
                                                       authenticator:nil];
    
    protocol.delegate = protocolDelegate;
    protocol.dataSource = protocolDelegate;
    
    
    // Starting the protocol and send presentation request
    // ---------------------------------------------------
    
    __block QredoConversationMessage *message = nil;
    __block QredoPresentationRequest *presentationRequest = nil;
    __block NSException *exception = nil;
    
    __block XCTestExpectation *protocolStartsExpectation = [self expectationWithDescription:@"Protocol starts"];
    
    [protocolDelegate setDidStartBlock:^(QredoClaimantAttestationProtocol *p) {
        XCTAssertEqual(protocol, p);
        [protocolStartsExpectation fulfill];
    }];
    
    __block XCTestExpectation *aliceReceivesPresentationRequestExepctation = [self expectationWithDescription:@"Alice recieves a presentation request"];
    [self.alicesDevice setOnPresentationRequest:^(QredoConversationMessage *m, QredoPresentationRequest *pr, NSException *e)
     {
         message = m;
         presentationRequest = pr;
         exception = e;
         [aliceReceivesPresentationRequestExepctation fulfill];
     }];
    
    [protocol start];
    
    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        protocolStartsExpectation = nil;
        aliceReceivesPresentationRequestExepctation = nil;
    }];
    
    XCTAssert([protocol canCancel]);
    XCTAssertFalse([protocol canAcceptOrRejct]);

    
    XCTAssertNotNil(message);
    XCTAssertNotNil(presentationRequest);
    XCTAssertEqual([presentationRequest.requestedAttestationTypes count], 2);
    XCTAssert([presentationRequest.requestedAttestationTypes containsObject:@"picture"]);
    XCTAssert([presentationRequest.requestedAttestationTypes containsObject:@"dob"]);
    XCTAssertNil(exception);
    
    
    // Recive presentation and send authenticaion request
    // --------------------------------------------------
    
    __block QredoPresentation *alicePresentation = nil;
    __block QredoPresentation *receivedPresentation = nil;
    __block QredoAuthenticationRequest *authenticationRequest = nil;
    
    __block QredoClaimantAttestationProtocolAuthenticationCompletionHandler authenticationCompletionHandler = nil;
    
    
    __block XCTestExpectation *protocolReceivesPresentationExpectation = [self expectationWithDescription:@"Protocol receives presentation"];
    [protocolDelegate setDidRecivePresentations:^(QredoClaimantAttestationProtocol *p, QredoPresentation *pres) {
        XCTAssertEqual(protocol, p);
        receivedPresentation = pres;
        [protocolReceivesPresentationExpectation fulfill];
    }];
    
    __block XCTestExpectation *authenticationRequestExpectation = [self expectationWithDescription:@"Has send authentication request"];
    [protocolDelegate setAuthenticateRequest:^(QredoClaimantAttestationProtocol *p, QredoAuthenticationRequest *ar, NSString *authenticator, QredoClaimantAttestationProtocolAuthenticationCompletionHandler compHandler) {
        authenticationRequest = ar;
        authenticationCompletionHandler = compHandler;
        [authenticationRequestExpectation fulfill];
    }];

    __block XCTestExpectation *aliceHasSentPresentationExpectation = [self expectationWithDescription:@"Alice has sent presentation"];
    [self.alicesDevice sendPresentationWithBlock:^QredoPresentation *{
        
        NSMutableSet *attestations = [NSMutableSet new];
        for (NSString *attestationType in presentationRequest.requestedAttestationTypes) {
            
            QredoLFClaim *lfClaim
            = [[QredoLFClaim alloc] initWithName:[NSSet new]
                                        datatype:attestationType
                                           value:[NSData new]];
            
            QredoCredential *credential
            = [[QredoCredential alloc] initWithSerialNumber:[NSString stringWithFormat:@"123%@", attestationType]
                                                   claimant:[NSData new]
                                                hashedClaim:[NSData new]
                                                  notBefore:@""
                                                   notAfter:@""
                                          revocationLocator:@""
                                               attesterInfo:@""
                                                  signature:[NSData new]];
            
            
            QredoAttestation *attestation = [[QredoAttestation alloc] initWithClaim:lfClaim
                                                                         credential:credential];
            
            [attestations addObject:attestation];
            
        }
        
        
        alicePresentation = [[QredoPresentation alloc] initWithAttestations:attestations];
        
        return alicePresentation;
        
    } completionHandler:^(NSError *error) {
        
        XCTAssertNil(error);
        [aliceHasSentPresentationExpectation fulfill];
        
    }];
    
    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        protocolReceivesPresentationExpectation = nil;
        authenticationRequestExpectation = nil;
        aliceHasSentPresentationExpectation = nil;
    }];
    
    XCTAssertNotNil(receivedPresentation);
    XCTAssertEqual([receivedPresentation.attestations count], [alicePresentation.attestations count]);
    // TODO [GR]: Add more tests here.
    
    XCTAssertNotNil(authenticationRequest);
    // TODO [GR]: Add more tests here.

    
    XCTAssert([protocol canCancel]);
    XCTAssert([protocol canAcceptOrRejct]);
    
    
    // Recive presentation request and wait for Bob's choice
    // -----------------------------------------------------
    
    __block QredoAuthenticationResponse *authenticationResponse = nil;
    
    __block XCTestExpectation *protocolReceivsAuthenticationsExpectation = [self expectationWithDescription:@"Protocol receives the authenticaiont results"];
    [protocolDelegate setDidReciveAuthentications:^(QredoClaimantAttestationProtocol *p, QredoAuthenticationResponse *ar) {
        XCTAssertEqual(protocol, p);
        authenticationResponse = ar;
        [protocolReceivsAuthenticationsExpectation fulfill];
    }];
    
    __block QredoAuthenticationResponse *authenticatorAuthenticationResponse = nil;
    [self.bobHelper finishAuthenticationWithCompletionHandler:authenticationCompletionHandler
                                                        block:^QredoAuthenticationResponse *
     {
         NSMutableArray *credentialValidationResults = [NSMutableArray new];
         
         for (QredoClaimMessage *claimMessage in authenticationRequest.claimMessages) {
             
             QredoAuthenticationCode *claimHash = claimMessage.claimHash;
             QredoCredentialValidationResult *validationResult = [QredoCredentialValidationResult credentialValidity];
             
             QredoAuthenticatedClaim *authenticatedClaim
             = [[QredoAuthenticatedClaim alloc] initWithValidity:validationResult
                                                       claimHash:claimHash
                                                    attesterInfo:nil];
             
             [credentialValidationResults addObject:authenticatedClaim];
             
         }
         
         authenticatorAuthenticationResponse
         = [[QredoAuthenticationResponse alloc] initWithCredentialValidationResults:credentialValidationResults
                                                                       sameIdentity:YES
                                                             authenticatorCertChain:[NSData new]
                                                                          signature:[NSData new]];
         
         return authenticatorAuthenticationResponse;
     }
                                                   errorBlock:^NSError *
     {
         return nil;
     }];
    
    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        protocolReceivsAuthenticationsExpectation = nil;
    }];
    
    XCTAssertNotNil(authenticationResponse);
    // TODO [GR]: Add more tests
    
    
    // Bob makes a choice and the protocol finishes
    // --------------------------------------------
    
    __block NSString *bobsChoiceString = nil;
    
    __block XCTestExpectation *sendtingBobsChoiceHasStartedExpectation = [self expectationWithDescription:@"Sending Bob choice has been started"];
    [protocolDelegate setDidStartSendingRelyingPartyChoice:^(QredoClaimantAttestationProtocol *p, BOOL accetped) {
        XCTAssertEqual(protocol, p);
        [sendtingBobsChoiceHasStartedExpectation fulfill];
    }];
    
    __block XCTestExpectation *hasSendChoiceExpectation = [self expectationWithDescription:@"Bob choice has been sent"];
    [protocolDelegate setDidFinishSendingRelyingPartyChoice:^(QredoClaimantAttestationProtocol *p) {
        XCTAssertEqual(protocol, p);
        [hasSendChoiceExpectation fulfill];
    }];
    
    __block XCTestExpectation *aliceHasRecivedChoiceExpectation = [self expectationWithDescription:@"Alice has received choice"];
    [self.alicesDevice setOnBobsChoice:^(QredoConversationMessage *m, NSString *choiceString, NSException *e) {
        bobsChoiceString = choiceString;
        [aliceHasRecivedChoiceExpectation fulfill];
    }];
    
    __block XCTestExpectation *protocolHasFinishedExpectation = [self expectationWithDescription:@"Protocol has finished"];
    [protocolDelegate setDidFinishWithError:^(QredoClaimantAttestationProtocol *p, NSError *e) {
        XCTAssertEqual(protocol, p);
        XCTAssertNil(e);
        [protocolHasFinishedExpectation fulfill];
    }];
    
    [protocol accept];
    
    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        sendtingBobsChoiceHasStartedExpectation = nil;
        hasSendChoiceExpectation = nil;
        aliceHasRecivedChoiceExpectation = nil;
        protocolHasFinishedExpectation = nil;
    }];
    
    XCTAssertEqualObjects(bobsChoiceString, kBobAcceptedString);
    
    
    
    // TODO [GR]: FINISH UP
    
}


@end


