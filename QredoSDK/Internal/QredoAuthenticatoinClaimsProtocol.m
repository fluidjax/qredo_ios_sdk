/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoAuthenticatoinClaimsProtocol.h"
#import "QredoConversation.h"
#import "QredoErrorCodes.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoClientMarshallers.h"
#import "QredoClient.h"

static NSString *const kAttestationCancelMessageType = @"com.qredo.attestation.cancel";
static NSString *const kAttestationValidationRequestMessageType = @"com.qredo.attestation.authentication.claims";
static NSString *const kAttestationValidationResultMessageType = @"com.qredo.attestation.authentication.result";

@protocol QredoAuthenticationProtocolEvents <NSObject>

- (void)didSendClaims;
- (void)didFailToSendClaimsWithError:(NSError *)error;

- (void)didFinishSendingCancelMessage;
- (void)didFinishSendingMessageWithError:(NSError *)error;

- (void)cancel;

@end

@interface QredoAuthenticationState : QredoConversationProtocolCancelableState <QredoAuthenticationProtocolEvents>
// Events

@end

//
@interface QredoAuthenticationState_Start : QredoAuthenticationState
@property (nonatomic) QredoAuthenticationRequest *authenticationRequest;
@end

//
@interface QredoAuthenticationState_Finish : QredoAuthenticationState
@end
// Sent error message
// Enter: delegate.didFinishWithError(error)
@interface QredoAuthenticationState_SentErrorMessage : QredoAuthenticationState
@property (nonatomic) NSError *error;
@end
// Sending claims for authentication
// Enter: publishMessage(com.qredo.attestation.authentication(credentials))
@interface QredoAuthenticationState_SendingClaims : QredoAuthenticationState
@property (nonatomic) QredoAuthenticationRequest *authenticationRequest;
@end
// Waiting for authentication result
@interface QredoAuthenticationState_WaitingForResult : QredoAuthenticationState
@end
// Sending error message
// Enter: publishMessage(com.qredo.attestation.cancel[error=...])
@interface QredoAuthenticationState_Error : QredoAuthenticationState
@property (nonatomic) NSError *error;
@end
// Sending cancel message
// Enter: publishMessage(com.qredo.attestation.cancel[error=nil]
@interface QredoAuthenticationState_Cancel : QredoAuthenticationState
@end
// Cancelled by Authenticator
// Enter: delegate.didFinishWithError(cancelled)
@interface QredoAuthenticationState_CancelledByOtherSide : QredoAuthenticationState
@end

@interface QredoAuthenticationProtocol () <QredoAuthenticationProtocolEvents>
@property (nonatomic) dispatch_queue_t queue;

@property (nonatomic) QredoAuthenticationState_Start *startState;
@property (nonatomic) QredoAuthenticationState_Finish *finishState;
@property (nonatomic) QredoAuthenticationState_SentErrorMessage *sentErrorMessageState;
@property (nonatomic) QredoAuthenticationState_SendingClaims *sendingClaimsState;
@property (nonatomic) QredoAuthenticationState_WaitingForResult *waitingForResultState;
@property (nonatomic) QredoAuthenticationState_Error *errorState;
@property (nonatomic) QredoAuthenticationState_Cancel *cancelState;
@property (nonatomic) QredoAuthenticationState_CancelledByOtherSide *cancelledByOtherSideState;
@end

@interface QredoAuthenticationState ()
@property (nonatomic, readonly) QredoAuthenticationProtocol *authenticationProtocol;
@end

@implementation QredoAuthenticationState

- (instancetype)init {
    self = [super init];

    if (!self) return nil;

    self.cancelMessageType = kAttestationCancelMessageType;

    return self;
}

- (QredoAuthenticationProtocol *)authenticationProtocol
{
    return (QredoAuthenticationProtocol *)self.conversationProtocol;
}

- (void)didSendClaims
{

}

- (void)didFailToSendClaimsWithError:(NSError *)error
{

}

- (void)didFinishSendingCancelMessage
{

}

- (void)didFinishSendingMessageWithError:(NSError *)error
{
    
}

- (void)didReceiveConversationMessage:(QredoConversationMessage *)message
{
    [super didReceiveConversationMessage:message];
}

- (void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message
{

}

- (void)conversationCanceledWithMessage:(QredoConversationMessage *)message
{
    dispatch_async(self.authenticationProtocol.queue, ^{
        [self.authenticationProtocol switchToState:self.authenticationProtocol.cancelledByOtherSideState withConfigBlock:nil];
    });
}

- (void)didReceiveUnexpectedMessage
{
    NSError * error = [NSError errorWithDomain:QredoErrorDomain
                                          code:QredoErrorCodeConversationProtocolUnexpectedMessageType
                                      userInfo:@{NSLocalizedDescriptionKey: @"Unexpected message type"}];

    dispatch_async(self.authenticationProtocol.queue, ^{
        [self.authenticationProtocol switchToState:self.authenticationProtocol.errorState withConfigBlock:^{
            self.authenticationProtocol.errorState.error = error;
        }];
    });
}

- (void)cancel {

}

@end

#pragma GCC diagnostic push
#pragma clang diagnostic push

#pragma GCC diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wprotocol"


@implementation QredoAuthenticationProtocol

- (instancetype)initWithConversation:(QredoConversation *)conversation
{
    self = [super initWithConversation:conversation];
    if (!self) return nil;

    self.queue = dispatch_queue_create("com.qredo.attestation.authentication.protocol", nil);

    self.startState = [[QredoAuthenticationState_Start alloc] init];
    self.finishState = [[QredoAuthenticationState_Finish alloc] init];
    self.sentErrorMessageState = [[QredoAuthenticationState_SentErrorMessage alloc] init];
    self.sendingClaimsState = [[QredoAuthenticationState_SendingClaims alloc] init];
    self.waitingForResultState = [[QredoAuthenticationState_WaitingForResult alloc] init];
    self.errorState = [[QredoAuthenticationState_Error alloc] init];
    self.cancelState = [[QredoAuthenticationState_Cancel alloc] init];
    self.cancelledByOtherSideState = [[QredoAuthenticationState_CancelledByOtherSide alloc] init];

    [self switchToState:self.startState withConfigBlock:nil];

    return self;
}

- (void)sendAuthenticationRequest:(QredoAuthenticationRequest *)authenticationRequest
{

    [self switchToState:self.startState withConfigBlock:^{
        self.startState.authenticationRequest = authenticationRequest;
    }];
}

- (void) cancel {
    [(QredoAuthenticationState *)self.currentState cancel];
}

@end

#pragma clang diagnostic pop
#pragma GCC diagnostic pop

#pragma mark - States implementation

@implementation QredoAuthenticationState_Start
- (void)didEnter
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.sendingClaimsState withConfigBlock:^{
        self.authenticationProtocol.sendingClaimsState.authenticationRequest = self.authenticationRequest;
    }];
}

- (void)cancel
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.cancelState withConfigBlock:nil];
}
@end


@implementation QredoAuthenticationState_Finish
- (void)didEnter {
    [self.authenticationProtocol.conversation stopListening];
}

- (void)conversationCanceledWithMessage:(QredoConversationMessage *)message {
    // do nothing
}

@end

@implementation QredoAuthenticationState_SentErrorMessage
- (void)prepareForReuse
{
    [super prepareForReuse];
    self.error = nil;
}
- (void)didEnter
{
    [self.authenticationProtocol.delegate qredoAuthenticationProtocol:self.authenticationProtocol didFailWithError:self.error];
    [self.authenticationProtocol switchToState:self.authenticationProtocol.finishState withConfigBlock:nil];
}
@end

@implementation QredoAuthenticationState_SendingClaims
- (void)prepareForReuse
{
    [super prepareForReuse];
    self.authenticationRequest = nil;
}

- (void)didEnter
{
    NSData *serializedCredentials = [QredoPrimitiveMarshallers marshalObject:self.authenticationRequest
                                                                  marshaller:[QredoClientMarshallers authenticationRequestMarshaller]];

    QredoConversationMessage *claimsMessage = [[QredoConversationMessage alloc] initWithValue:serializedCredentials
                                                                                     dataType:kAttestationValidationRequestMessageType
                                                                                summaryValues:nil];
    [self.conversationProtocol.conversation publishMessage:claimsMessage
                                         completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error)
    {
        if (error) {
            [self.authenticationProtocol didFailToSendClaimsWithError:error];
        } else {
            [self.authenticationProtocol didSendClaims];
        }
    }];
}

- (void)didSendClaims
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.waitingForResultState
                             withConfigBlock:nil];

}

- (void)didFailToSendClaimsWithError:(NSError *)error
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.errorState withConfigBlock:^{
        self.authenticationProtocol.errorState.error = error;
    }];
}

- (void)cancel
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.cancelState withConfigBlock:nil];
}

- (void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message
{
    [self didReceiveUnexpectedMessage];
}

@end

@implementation QredoAuthenticationState_WaitingForResult

- (void)didEnter
{
    [self.authenticationProtocol.delegate qredoAuthenticationProtocolDidSendClaims:self.authenticationProtocol];
    [self.authenticationProtocol.conversation startListening];
}

- (void)cancel
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.cancelState withConfigBlock:nil];
}

- (void)didTimeout
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.errorState withConfigBlock:^{
        self.authenticationProtocol.errorState.error = [NSError errorWithDomain:QredoErrorDomain
                                                                           code:QredoErrorCodeConversationProtocolTimeout
                                                                       userInfo:@{NSLocalizedDescriptionKey : @"Timeout"}];
    }];
}

- (void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message
{
    if ([message.dataType isEqualToString: kAttestationValidationResultMessageType]) {
        @try {
            QredoAuthenticationResponse * results = [QredoPrimitiveMarshallers unmarshalObject:message.value
                                                                                  unmarshaller:[QredoClientMarshallers authenticationResponseUnmarshaller]];


            dispatch_async(self.authenticationProtocol.queue, ^{
                [self.authenticationProtocol.delegate qredoAuthenticationProtocol:self.authenticationProtocol
                                                             didFinishWithResults:results];

                [self.authenticationProtocol switchToState:self.authenticationProtocol.finishState withConfigBlock:nil];
            });
        }
        @catch (NSException *exception) {
            [self didReceiveMalformedData];
        }
    } else {
        [self didReceiveUnexpectedMessage];
    }
}

- (void)didReceiveMalformedData {
    NSError * error = [NSError errorWithDomain:QredoErrorDomain
                                          code:QredoErrorCodeConversationProtocolReceivedMalformedData
                                      userInfo:@{NSLocalizedDescriptionKey: @"Malformed request"}];

    dispatch_async(self.authenticationProtocol.queue, ^{
        [self.authenticationProtocol switchToState:self.authenticationProtocol.errorState withConfigBlock:^{
            self.authenticationProtocol.errorState.error = error;
        }];
    });

}
@end

@implementation QredoAuthenticationState_Error
- (void)prepareForReuse
{
    [super prepareForReuse];
    self.error = nil;
}

- (void)didEnter
{
    NSData *messageValue = [self.error.localizedDescription dataUsingEncoding:NSUTF8StringEncoding];

    QredoConversationMessage *errorMessage = [[QredoConversationMessage alloc] initWithValue:messageValue
                                                                                    dataType:kAttestationCancelMessageType
                                                                               summaryValues:nil];
    [self.conversationProtocol.conversation publishMessage:errorMessage
                                         completionHandler:^(QredoConversationHighWatermark *messageHighWatermark,
                                                             NSError *error)
    {
        [self.authenticationProtocol didFinishSendingMessageWithError:self.error];
    }];
}

- (void)didFinishSendingMessageWithError:(NSError *)error
{
    dispatch_async(self.authenticationProtocol.queue, ^{
        [self.conversationProtocol switchToState:self.authenticationProtocol.sentErrorMessageState
                                 withConfigBlock:^
         {
             self.authenticationProtocol.sentErrorMessageState.error = error;
         }];
    });
}

- (void)cancel
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.sentErrorMessageState
                             withConfigBlock:nil];
}

@end

@implementation QredoAuthenticationState_Cancel

- (void)didEnter
{
    QredoConversationMessage *cancelMessage = [[QredoConversationMessage alloc] initWithValue:nil
                                                                                     dataType:kAttestationCancelMessageType
                                                                                summaryValues:nil];
    [self.conversationProtocol.conversation publishMessage:cancelMessage
                                         completionHandler:^(QredoConversationHighWatermark *messageHighWatermark,
                                                             NSError *error)
     {
         [self.authenticationProtocol didFinishSendingCancelMessage];
     }];
}

- (void)cancel
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.finishState withConfigBlock:nil];
}

- (void)didFinishSendingCancelMessage
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.finishState withConfigBlock:nil];
}
@end

@implementation QredoAuthenticationState_CancelledByOtherSide
- (void)didEnter
{
    NSError *cancelError = [NSError errorWithDomain:QredoErrorDomain
                                               code:QredoErrorCodeConversationProtocolCancelledByOtherSide
                                           userInfo:@{NSLocalizedDescriptionKey: @"Cancelled by the other side"}];

    [self.authenticationProtocol.delegate qredoAuthenticationProtocol:self.authenticationProtocol
                                                     didFailWithError:cancelError];

    [self.conversationProtocol switchToState:self.authenticationProtocol.finishState withConfigBlock:nil];
}
@end