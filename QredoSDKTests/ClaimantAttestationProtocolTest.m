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


static NSString *const kDefaultCancelMessageType = @"com.qredo.attestation.cancel";

static NSString *KAttestationClaimantConversationType = @"com.qredo.attesation.relyingparty";

static NSString *kAttestationPresentationRequestMessageType = @"com.qredo.attestation.presentation.request";
static NSString *kAttestationPresentationMessageType = @"com.qredo.attestation.presentation";

static NSString *kAttestationRelyingPartyChoiceMessageType = @"com.qredo.attestation.relyingparty.decision";
static NSString *kAttestationRelyingPartyChoiceAccepted = @"ACCEPTED";
static NSString *kAttestationRelyingPartyChoiceRejected = @"REJECTED";


static NSTimeInterval kDefaultExpectationTimeout = 5.0;



//===============================================================================================================
#pragma mark - Alice device mock -
//===============================================================================================================


@interface ClaimantAttestationProtocolTest_AliceDevice : NSObject<QredoConversationDelegate>

@property (nonatomic) QredoConversationMessage *receivedMemessage;

@property (nonatomic) QredoConversationMessage *onPresentationRequestMemessage;
@property (nonatomic) QredoPresentationRequest *onPresentationRequestPresentationRequest;
@property (nonatomic) NSException *onPresentationRequestException;
@property (nonatomic, copy) void(^onPresentationRequest)(QredoConversationMessage *message, QredoPresentationRequest *presentationRequest, NSException *unmarshalException);

@property (nonatomic) QredoConversationMessage *sendPresentationMessage;
@property (nonatomic) QredoPresentation *sendPresentationPresentation;
@property (nonatomic) NSError *sendPresentationError;

@property (nonatomic) QredoConversationMessage *onBobsChoiceMemessage;
@property (nonatomic, copy) NSString *onBobsChoiceChoice;
@property (nonatomic) NSException *onBobsChoiceException;
@property (nonatomic, copy) void(^onBobsChoice)(QredoConversationMessage *message, NSString *choice, NSException *unmarshalException);

@property (nonatomic) QredoConversationMessage *onBobsCancelMemessage;
@property (nonatomic, copy) void(^onBobsCancel)(QredoConversationMessage *message);

@property (nonatomic) QredoConversationMessage *sendCancelMemessage;
@property (nonatomic) NSError *sendCancelError;

@property (nonatomic) QredoConversation *conversation;

- (void)respondToRendezvousWithTag:(NSString *)rendezvousTag completionHandler:(void(^)(NSError *error))completionHandler;

- (void)sendPresentationWithBlock:(QredoPresentation *(^)())presentationBlock
                completionHandler:(void(^)(NSError *error))completionHandler;

@end

@implementation ClaimantAttestationProtocolTest_AliceDevice
{
    QredoClient *_qredoClient;
}

#pragma mark Actions

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
    self.sendPresentationPresentation = presentation;
    
    NSData *messageValue
    = [QredoPrimitiveMarshallers marshalObject:presentation
                                    marshaller:[QredoClientMarshallers presentationMarshaller]];
    
    QredoConversationMessage *message
    = [[QredoConversationMessage alloc] initWithValue:messageValue
                                             dataType:kAttestationPresentationMessageType
                                        summaryValues:nil];
    self.sendPresentationMessage = message;
    [self.conversation publishMessage:message
                    completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error)
    {
        self.sendPresentationError = error;
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)sendCancelMessageWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    QredoConversationMessage *message
    = [[QredoConversationMessage alloc] initWithValue:nil
                                             dataType:kDefaultCancelMessageType
                                        summaryValues:nil];
    self.sendCancelMemessage = message;
    [self.conversation publishMessage:message
                    completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error)
     {
         self.sendCancelError = error;
         if (completionHandler) {
             completionHandler(error);
         }
     }];
}

#pragma mark Internal

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
    self.onPresentationRequestMemessage = message;
    
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
        self.onPresentationRequestPresentationRequest = presentationRequest;
        self.onPresentationRequestException = unmarshalException;
        if (self.onPresentationRequest) {
            self.onPresentationRequest(message, presentationRequest, unmarshalException);
        }
    }
}

- (void)didReciveRelyingPartyDecisionMessage:(QredoConversationMessage *)message
{
    self.onBobsChoiceMemessage = message;
    
    static NSString *const kDecodingExeptionName = @"ClaimantAttestationProtocolTest_AliceDevice_MessageDecodingError";
    if (self.onBobsChoice) {
        
        NSData *choiceData = message.value;
        if ([choiceData length] < 1) {
            self.onBobsChoice(message, nil, [NSException exceptionWithName:kDecodingExeptionName
                                                                    reason:@"MissingData" userInfo:nil]);
        }
        
        NSString *choiceString = [[NSString alloc] initWithData:choiceData encoding:NSUTF8StringEncoding];
        
        self.onBobsChoiceChoice = choiceString;
        if ([choiceString isEqualToString:kAttestationRelyingPartyChoiceAccepted]) {
            self.onBobsChoice(message, choiceString, nil);
        } else if ([choiceString isEqualToString:kAttestationRelyingPartyChoiceRejected]) {
            self.onBobsChoice(message, choiceString, nil);
        } else {
            NSException *e = [NSException exceptionWithName:kDecodingExeptionName
                                                     reason:@"MalformedData"
                                                   userInfo:nil];
            self.onBobsChoiceException = e;
            self.onBobsChoice(message, nil, e);
        }
    }
}

- (void)didReciveCancelMessage:(QredoConversationMessage *)message
{
    self.onBobsCancelMemessage = message;
    if (self.onBobsCancel) {
        self.onBobsCancel(nil);
    }
}

#pragma mark  QredoConversationDelegate
- (void)qredoConversation:(QredoConversation *)conversation
     didReceiveNewMessage:(QredoConversationMessage *)message
{
    self.receivedMemessage = message;
    
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


@interface ClaimantAttestationProtocolTest_ProtocolDelegate: NSObject<QredoClaimantAttestationProtocolDelegate>

@property (nonatomic) QredoClaimantAttestationProtocol *didStartBlockProtocol;

@property (nonatomic) QredoClaimantAttestationProtocol *didRecivePresentationsProtocol;
@property (nonatomic) QredoPresentation *didRecivePresentationsPresentation;

@property (nonatomic) QredoClaimantAttestationProtocol *didReciveAuthenticationsProtocol;
@property (nonatomic) QredoAuthenticationResponse *didReciveAuthenticationsAuthenticationResponse;

@property (nonatomic) QredoClaimantAttestationProtocol *didFinishAuthenticationWithErrorProtocol;
@property (nonatomic) NSError *didFinishAuthenticationWithErrorError;

@property (nonatomic) QredoClaimantAttestationProtocol *didStartSendingRelyingPartyChoiceProtocol;
@property (nonatomic) BOOL didStartSendingRelyingPartyChoiceClaimsAccepted;

@property (nonatomic) QredoClaimantAttestationProtocol *didFinishSendingRelyingPartyChoiceProtocol;

@property (nonatomic) QredoClaimantAttestationProtocol *didFinishWithErrorProtocol;
@property (nonatomic) NSError *didFinishWithErrorError;


@property (nonatomic, copy) void(^didStartBlock)(QredoClaimantAttestationProtocol *protocol);
@property (nonatomic, copy) void(^didRecivePresentations)(QredoClaimantAttestationProtocol *protocol, QredoPresentation *presentation);
@property (nonatomic, copy) void(^didReciveAuthentications)(QredoClaimantAttestationProtocol *protocol, QredoAuthenticationResponse *authentications);
@property (nonatomic, copy) void(^didFinishAuthenticationWithError)(QredoClaimantAttestationProtocol *protocol, NSError *error);
@property (nonatomic, copy) void(^didStartSendingRelyingPartyChoice)(QredoClaimantAttestationProtocol *protocol, BOOL claimsAccepted);
@property (nonatomic, copy) void(^didFinishSendingRelyingPartyChoice)(QredoClaimantAttestationProtocol *protocol);
@property (nonatomic, copy) void(^didFinishWithError)(QredoClaimantAttestationProtocol *protocol, NSError *error);


@end

@implementation ClaimantAttestationProtocolTest_ProtocolDelegate


- (void)didStartClaimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
{
    self.didStartBlockProtocol = protocol;
    if (self.didStartBlock) {
        self.didStartBlock(protocol);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
             didRecivePresentations:(QredoPresentation *)presentation
{
    self.didRecivePresentationsProtocol = protocol;
    self.didRecivePresentationsPresentation = presentation;
    if (self.didRecivePresentations) {
        self.didRecivePresentations(protocol, presentation);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
           didReciveAuthentications:(QredoAuthenticationResponse *)authentications
{
    self.didReciveAuthenticationsProtocol = claimantAttestationProtocol;
    self.didReciveAuthenticationsAuthenticationResponse = authentications;
    if (self.didReciveAuthentications) {
        self.didReciveAuthentications(claimantAttestationProtocol, authentications);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
   didFinishAuthenticationWithError:(NSError *)error
{
    self.didFinishAuthenticationWithErrorProtocol = claimantAttestationProtocol;
    self.didFinishAuthenticationWithErrorError = error;
    if (self.didFinishAuthenticationWithError) {
        self.didFinishAuthenticationWithError(claimantAttestationProtocol, error);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
  didStartSendingRelyingPartyChoice:(BOOL)claimsAccepted
{
    self.didStartSendingRelyingPartyChoiceProtocol = claimantAttestationProtocol;
    self.didStartSendingRelyingPartyChoiceClaimsAccepted = claimsAccepted;
    if (self.didStartSendingRelyingPartyChoice) {
        self.didStartSendingRelyingPartyChoice(claimantAttestationProtocol, claimsAccepted);
    }
}

- (void)claimantAttestationProtocolDidFinishSendingRelyingPartyChoice:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
{
    self.didFinishSendingRelyingPartyChoiceProtocol = claimantAttestationProtocol;
    if (self.didFinishSendingRelyingPartyChoice) {
        self.didFinishSendingRelyingPartyChoice(claimantAttestationProtocol);
    }
}

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)claimantAttestationProtocol
                 didFinishWithError:(NSError *)error
{
    self.didFinishWithErrorProtocol = claimantAttestationProtocol;
    self.didFinishWithErrorError = error;
    if (self.didFinishWithError) {
        self.didFinishWithError(claimantAttestationProtocol, error);
    }
}

@end

typedef ClaimantAttestationProtocolTest_ProtocolDelegate ProtocolDelegate;



//===============================================================================================================
#pragma mark - Bob helper -
//===============================================================================================================


@interface ClaimantAttestationProtocolTest_BobHelper : NSObject<QredoRendezvousDelegate, QredoClaimantAttestationProtocolDataSource>

@property (nonatomic) QredoRendezvous *rendezvous;
@property (nonatomic) QredoConversation *conversation;

@property (nonatomic) QredoClaimantAttestationProtocol *authenticateRequestProtocol;
@property (nonatomic) QredoAuthenticationRequest *authenticateRequestAuthenticationRequest;
@property (nonatomic, copy) NSString *authenticateRequestAuthenticator;
@property (nonatomic, copy) QredoClaimantAttestationProtocolAuthenticationCompletionHandler authenticateRequestCompletionHandler;
@property (nonatomic, copy) void(^authenticateRequest)(QredoClaimantAttestationProtocol *protocol, QredoAuthenticationRequest *authenticationRequest, NSString *authenticator, QredoClaimantAttestationProtocolAuthenticationCompletionHandler completionHandler);

@property (nonatomic) QredoAuthenticationResponse *finishAuthenticationAuthenticationResponse;
@property (nonatomic) NSError *finishAuthenticationError;


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
             self.rendezvous = rendezvous;
             rendezvous.delegate = self;
             [rendezvous startListening];
             
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

#pragma mark Authentication action

- (void)finishAuthenticationWithCompletionHandler:(QredoClaimantAttestationProtocolAuthenticationCompletionHandler)complitionHandler
                                            block:(QredoAuthenticationResponse *(^)())authenticationResponseBlock
                                       errorBlock:(NSError *(^)())errorBlock
{
    QredoAuthenticationResponse *response = authenticationResponseBlock ? authenticationResponseBlock() : nil;
    self.finishAuthenticationAuthenticationResponse = response;
    NSError *error = errorBlock ? errorBlock() : nil;
    self.finishAuthenticationError = error;
    complitionHandler(response, error);
    
}

#pragma mark QredoClaimantAttestationProtocolDataSource

- (void)claimantAttestationProtocol:(QredoClaimantAttestationProtocol *)protocol
                authenticateRequest:(QredoAuthenticationRequest *)authenticationRequest
                      authenticator:(NSString *)authenticator
                  completionHandler:(QredoClaimantAttestationProtocolAuthenticationCompletionHandler)completionHandler
{
    self.authenticateRequestProtocol = protocol;
    self.authenticateRequestAuthenticationRequest = authenticationRequest;
    self.authenticateRequestAuthenticator = authenticator;
    self.authenticateRequestCompletionHandler = completionHandler;
    if (self.authenticateRequest) {
        self.authenticateRequest(protocol, authenticationRequest, authenticator, completionHandler);
    }
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
@property (nonatomic) QredoClaimantAttestationProtocol *protocol;
@property (nonatomic) BobHelper *bobHelper;
@property (nonatomic) ProtocolDelegate *protocolDelegate;
@property (nonatomic) AlicesDevice *alicesDevice;
@end

@implementation ClaimantAttestationProtocolTest

- (void)setUp
{
    [super setUp];
    
    self.bobHelper = [[BobHelper alloc] init];
    self.protocolDelegate = [[ProtocolDelegate alloc] init];
    self.alicesDevice = [[AlicesDevice alloc] init];
    
    __block XCTestExpectation *bobCreatesRendezvousExpectation = [self expectationWithDescription:@"Bob creates rendezvous"];
    [self.bobHelper createRendezvousWithCompletionHandler:^(NSError *error) {
        NSAssert(!error, @"Could not create rendezvous for Bob.");
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
         NSAssert(!error, @"Alice could nor respond to Bob's rendezvous.");
         [aliceRespondsToRendezvousExpectation fulfill];
     }];

    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        aliceRespondsToRendezvousExpectation = nil;
        bobsConversationIsCreatedExpectation = nil;
    }];
    
    NSAssert(self.bobHelper.conversation, @"Bob has not got he's end of the conversation.");
}

- (void)tearDown
{
    self.bobHelper = nil;
    self.protocolDelegate = nil;
    self.alicesDevice = nil;
    [super tearDown];
}


#pragma mark Tests

- (void)testNormalFlow
{
    
    QredoClaimantAttestationProtocol *protocol
    = [[QredoClaimantAttestationProtocol alloc] initWithConversation:self.bobHelper.conversation
                                                    attestationTypes:[NSSet setWithArray:@[@"picture", @"dob"]]
                                                       authenticator:nil];
    
    protocol.delegate = self.protocolDelegate;
    protocol.dataSource = self.bobHelper;
    self.protocol = protocol;
    
    
    // Starting the protocol and send presentation request
    // ---------------------------------------------------
    
    [self startTheProtocolAndSendPresentationRequest];
    
    XCTAssertEqual(protocol, self.protocolDelegate.didStartBlockProtocol);
    
    XCTAssertNotNil(self.alicesDevice.onPresentationRequestMemessage);
    XCTAssertNotNil(self.alicesDevice.onPresentationRequestPresentationRequest);
    XCTAssertEqual([self.alicesDevice.onPresentationRequestPresentationRequest.requestedAttestationTypes count], 2);
    XCTAssert([self.alicesDevice.onPresentationRequestPresentationRequest.requestedAttestationTypes containsObject:@"picture"]);
    XCTAssert([self.alicesDevice.onPresentationRequestPresentationRequest.requestedAttestationTypes containsObject:@"dob"]);
    XCTAssertNil(self.alicesDevice.onPresentationRequestException);
    
    XCTAssert([protocol canCancel]);
    XCTAssertFalse([protocol canAcceptOrRejct]);
    
    
    // Recive presentation and send authenticaion request
    // --------------------------------------------------
    
    [self recivePresentationAndSendAuthenticaionRequest];

    XCTAssertNil(self.alicesDevice.sendPresentationError);

    XCTAssertEqual(self.protocolDelegate.didRecivePresentationsProtocol, protocol);
    // TODO [GR]: Add more tests here.
    
    XCTAssertNotNil(self.protocolDelegate.didRecivePresentationsPresentation);
    XCTAssertEqual([self.protocolDelegate.didRecivePresentationsPresentation.attestations count],
                   [self.alicesDevice.sendPresentationPresentation.attestations count]);
    // TODO [GR]: Add more tests here.
    
    XCTAssertNotNil(self.bobHelper.authenticateRequestAuthenticationRequest);
    // TODO [GR]: Add more tests here.

    
    XCTAssert([protocol canCancel]);
    XCTAssert([protocol canAcceptOrRejct]);
    
    
    // Recive presentation request and wait for Bob's choice
    // -----------------------------------------------------
    
    [self recivePresentationRequestAndWaitForBobsChoice];
    
    XCTAssertEqual(protocol, self.bobHelper.authenticateRequestProtocol);
    XCTAssertNotNil(self.bobHelper.finishAuthenticationAuthenticationResponse);
    // TODO [GR]: Add more tests
    
    
    // Bob makes a choice and the protocol finishes
    // --------------------------------------------
    
    [self bobMakesAChoiceAndTheProtocolFinishesWithBobsChoiceAccept:YES];
    
    XCTAssertEqual(protocol, self.protocolDelegate.didStartSendingRelyingPartyChoiceProtocol);
    
    XCTAssertEqual(protocol, self.protocolDelegate.didFinishSendingRelyingPartyChoiceProtocol);
    
    XCTAssertEqualObjects(self.alicesDevice.onBobsChoiceChoice, kAttestationRelyingPartyChoiceAccepted);

    XCTAssertEqual(protocol, self.protocolDelegate.didFinishWithErrorProtocol);
    XCTAssertNil(self.protocolDelegate.didFinishWithErrorError);
    
    
    // TODO [GR]: FINISH UP
    
}

#pragma mark Steps

- (void)startTheProtocolAndSendPresentationRequest
{
    __block XCTestExpectation *protocolStartsExpectation = [self expectationWithDescription:@"Protocol starts"];
    
    [self.protocolDelegate setDidStartBlock:^(QredoClaimantAttestationProtocol *p) {
        [protocolStartsExpectation fulfill];
    }];
    
    __block XCTestExpectation *aliceReceivesPresentationRequestExepctation = [self expectationWithDescription:@"Alice recieves a presentation request"];
    [self.alicesDevice setOnPresentationRequest:^(QredoConversationMessage *m,
                                                  QredoPresentationRequest *pr,
                                                  NSException *e)
     {
         [aliceReceivesPresentationRequestExepctation fulfill];
     }];
    
    [self.protocol start];
    
    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        protocolStartsExpectation = nil;
        aliceReceivesPresentationRequestExepctation = nil;
    }];
}

- (void)recivePresentationAndSendAuthenticaionRequest
{
    __block XCTestExpectation *protocolReceivesPresentationExpectation = [self expectationWithDescription:@"Protocol receives presentation"];
    [self.protocolDelegate setDidRecivePresentations:^(QredoClaimantAttestationProtocol *p, QredoPresentation *pres) {
        [protocolReceivesPresentationExpectation fulfill];
    }];
    
    __block XCTestExpectation *authenticationRequestExpectation = [self expectationWithDescription:@"Has send authentication request"];
    [self.bobHelper setAuthenticateRequest:^(QredoClaimantAttestationProtocol *p,
                                             QredoAuthenticationRequest *ar,
                                             NSString *authenticator,
                                             QredoClaimantAttestationProtocolAuthenticationCompletionHandler compHandler) {
        [authenticationRequestExpectation fulfill];
    }];
    
    __block XCTestExpectation *aliceHasSentPresentationExpectation = [self expectationWithDescription:@"Alice has sent presentation"];
    [self.alicesDevice sendPresentationWithBlock:^QredoPresentation *{
        
        NSMutableSet *attestations = [NSMutableSet new];
        for (NSString *attestationType in self.alicesDevice.onPresentationRequestPresentationRequest.requestedAttestationTypes) {
            
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
        
        return [[QredoPresentation alloc] initWithAttestations:attestations];
        
    } completionHandler:^(NSError *error) {
        
        [aliceHasSentPresentationExpectation fulfill];
        
    }];
    
    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        protocolReceivesPresentationExpectation = nil;
        authenticationRequestExpectation = nil;
        aliceHasSentPresentationExpectation = nil;
    }];

}

- (void)recivePresentationRequestAndWaitForBobsChoice
{
    __block XCTestExpectation *protocolReceivsAuthenticationsExpectation = [self expectationWithDescription:@"Protocol receives the authenticaiont results"];
    [self.protocolDelegate setDidReciveAuthentications:^(QredoClaimantAttestationProtocol *p,
                                                         QredoAuthenticationResponse *ar) {
        [protocolReceivsAuthenticationsExpectation fulfill];
    }];
    
    [self.bobHelper finishAuthenticationWithCompletionHandler:self.bobHelper.authenticateRequestCompletionHandler
                                                        block:^QredoAuthenticationResponse *
     {
         NSMutableArray *credentialValidationResults = [NSMutableArray new];
         
         for (QredoClaimMessage *claimMessage in self.bobHelper.authenticateRequestAuthenticationRequest.claimMessages) {
             
             QredoAuthenticationCode *claimHash = claimMessage.claimHash;
             QredoCredentialValidationResult *validationResult = [QredoCredentialValidationResult credentialValidity];
             
             QredoAuthenticatedClaim *authenticatedClaim
             = [[QredoAuthenticatedClaim alloc] initWithValidity:validationResult
                                                       claimHash:claimHash
                                                    attesterInfo:nil];
             
             [credentialValidationResults addObject:authenticatedClaim];
             
         }
         
         return [[QredoAuthenticationResponse alloc] initWithCredentialValidationResults:credentialValidationResults
                                                                            sameIdentity:YES
                                                                  authenticatorCertChain:[NSData new]
                                                                               signature:[NSData new]];
     }
                                                   errorBlock:^NSError *
     {
         return nil;
     }];
    
    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        protocolReceivsAuthenticationsExpectation = nil;
    }];
}

- (void)bobMakesAChoiceAndTheProtocolFinishesWithBobsChoiceAccept:(BOOL)bobAccept
{
    __block XCTestExpectation *sendtingBobsChoiceHasStartedExpectation = [self expectationWithDescription:@"Sending Bob choice has been started"];
    [self.protocolDelegate setDidStartSendingRelyingPartyChoice:^(QredoClaimantAttestationProtocol *p, BOOL accetped) {
        [sendtingBobsChoiceHasStartedExpectation fulfill];
    }];
    
    __block XCTestExpectation *hasSendChoiceExpectation = [self expectationWithDescription:@"Bob choice has been sent"];
    [self.protocolDelegate setDidFinishSendingRelyingPartyChoice:^(QredoClaimantAttestationProtocol *p) {
        [hasSendChoiceExpectation fulfill];
    }];
    
    __block XCTestExpectation *aliceHasRecivedChoiceExpectation = [self expectationWithDescription:@"Alice has received choice"];
    [self.alicesDevice setOnBobsChoice:^(QredoConversationMessage *m, NSString *choiceString, NSException *e) {
        [aliceHasRecivedChoiceExpectation fulfill];
    }];
    
    __block XCTestExpectation *protocolHasFinishedExpectation = [self expectationWithDescription:@"Protocol has finished"];
    [self.protocolDelegate setDidFinishWithError:^(QredoClaimantAttestationProtocol *p, NSError *e) {
        [protocolHasFinishedExpectation fulfill];
    }];
    
    if (bobAccept) {
        [self.protocol accept];
    } else {
        [self.protocol reject];
    }
    
    [self waitForExpectationsWithTimeout:kDefaultExpectationTimeout handler:^(NSError *error) {
        sendtingBobsChoiceHasStartedExpectation = nil;
        hasSendChoiceExpectation = nil;
        aliceHasRecivedChoiceExpectation = nil;
        protocolHasFinishedExpectation = nil;
    }];

}

@end


