/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoAuthenticatoinClaimsProtocol.h"
#import "QredoConversation.h"


//
@interface QredoAuthenticationState_Finish : QredoAuthenticationState
@end
// Sent error message
// Enter: delegate.didFinishWithError(error)
@interface QredoAuthenticationState_SentErrorMessage : QredoAuthenticationState
@property (nonatomic) NSError *error;
@end
//
@interface QredoAuthenticationState_Start : QredoAuthenticationState
@end
// Received result
// Enter: delegate.didReceiveResult()
@interface QredoAuthenticationState_ReceivedResult : QredoAuthenticationState
@property (nonatomic) NSArray *results;
@end
// Sending claims for authentication
// Enter: publishMessage(com.qredo.attestation.authentication(credentials))
@interface QredoAuthenticationState_SendingClaims : QredoAuthenticationState
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

@interface QredoAuthenticationProtocol ()
@property (nonatomic) QredoAuthenticationState_Finish *finishState;
@property (nonatomic) QredoAuthenticationState_SentErrorMessage *sentErrorMessageState;
@property (nonatomic) QredoAuthenticationState_Start *startState;
@property (nonatomic) QredoAuthenticationState_ReceivedResult *receivedResultState;
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

- (void)didReceiveCancelConversationMessageWithError:(NSError *)error
{

}

@end

#pragma GCC diagnostic push
#pragma clang diagnostic push

#pragma GCC diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wprotocol"


@implementation QredoAuthenticationProtocol
@end

#pragma clang diagnostic pop
#pragma GCC diagnostic pop



#pragma mark - States implementation

@implementation QredoAuthenticationState_Finish
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

@implementation QredoAuthenticationState_Start
@end

@implementation QredoAuthenticationState_ReceivedResult
- (void)prepareForReuse
{
    [super prepareForReuse];
    self.results = nil;
}
- (void)didEnter
{
    [self.authenticationProtocol.delegate qredoAuthenticationProtocol:self.authenticationProtocol
                                                 didFinishWithResults:self.results];

    [self.authenticationProtocol switchToState:self.authenticationProtocol.finishState withConfigBlock:nil];
}
@end

@implementation QredoAuthenticationState_SendingClaims
- (void)didEnter
{
    QredoConversationMessage *claimsMessage = nil; // TODO:
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
    [self.authenticationProtocol switchToState:self.authenticationProtocol.errorState withConfigBlock:^{
        self.authenticationProtocol.errorState.error = nil; // TODO: fill an error
    }];
}

@end

@implementation QredoAuthenticationState_WaitingForResult
- (void)cancel
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.cancelState withConfigBlock:nil];
}

- (void)didTimeout
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.errorState withConfigBlock:^{
        self.authenticationProtocol.errorState.error = nil; // TODO: fill an error
    }];
}

- (void)didReceiveNonCancelConversationMessage:(QredoConversationMessage *)message
{
    if ([message.dataType isEqualToString: @"com.qredo.attestation.authentication.result"]) {
        [self.conversationProtocol switchToState:self.authenticationProtocol.receivedResultState
                                 withConfigBlock: ^
        {
            self.authenticationProtocol.receivedResultState.results = nil; // TODO: parse results
        }];
    } else {
        [self.conversationProtocol switchToState:self.authenticationProtocol.errorState withConfigBlock:^{
            self.authenticationProtocol.errorState.error = nil; // TODO: fill an error
        }];
    }
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
    // TODO: Enter: publishMessage(com.qredo.attestation.cancel[error=...])
    QredoConversationMessage *errorMessage = nil; // TODO:
    [self.conversationProtocol.conversation publishMessage:errorMessage
                                         completionHandler:^(QredoConversationHighWatermark *messageHighWatermark,
                                                             NSError *error)
    {
        [self.authenticationProtocol didFinishSendingMessageWithError:self.error];
    }];
}

- (void)didFinishSendingMessageWithError:(NSError *)error
{
    [self.conversationProtocol switchToState:self.authenticationProtocol.sentErrorMessageState
                             withConfigBlock:^
     {
         self.authenticationProtocol.sentErrorMessageState.error = error;
     }];
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
                                                                                     dataType:@"com.qredo.attestation.cancel"
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
    NSError *cancelError = nil; // TODO: fill in error
    [self.authenticationProtocol.delegate qredoAuthenticationProtocol:self.authenticationProtocol didFailWithError:cancelError];
}
@end