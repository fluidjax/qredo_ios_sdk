/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainSender.h"
#import "Qredo.h"
#import "QredoKeychainTransporterConsts.h"
#import "QredoPrivate.h"
#import "QredoVaultPrivate.h"
#import "QredoKeychain.h"
#import "QredoConversationProtocolFSM.h"
#import "QredoKeychainTransporterHelper.h"

@interface QredoKeychainSender () <QredoConversationProtocolFSMDelegate>
{
    // completion handler that is passed to startWithCompletionHandler:
    void(^clientCompletionHandler)(NSError *error);
    BOOL keychainHasBeenSent;
    BOOL cancelled;
}

@property (weak) id<QredoKeychainSenderDelegate> delegate;
@property (weak) QredoClient *client;

@property QredoConversationProtocolFSM *conversationProtocol;
@property QredoConversationMessage *receiverDeviceInfoMessage;
@property QredoDeviceInfo *receiverDeviceInfo;

@property QredoConversationProtocolProcessingState *confirmSendingState;

@end

@implementation QredoKeychainSender

- (instancetype)initWithClient:(QredoClient*)client delegate:(id<QredoKeychainSenderDelegate>)delegate
{
    self = [super init];
    if (!self) return nil;

    self.delegate = delegate;
    self.client = client;

    return self;
}

- (void)startWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    clientCompletionHandler = completionHandler;

    [self.delegate qredoKeychainSenderDiscoverRendezvous:self completionHander:^BOOL(NSString *rendezvousTagWithProtocol)
    {
        NSString *rendezvousTag = [self stringProtocolFromTag:rendezvousTagWithProtocol];

        if (!rendezvousTag) {
            completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                  code:QredoErrorCodeUnknown // TODO:
                                              userInfo:@{NSLocalizedDescriptionKey: @"Invalid rendevous tag"}]);
            return NO;
        }

        [self didDiscoverRendezvousTag:rendezvousTag];

        return YES;
    } cancelHandler:^{
        [self cancel];
    }];
}

- (NSString*)stringProtocolFromTag:(NSString*)rendezvousTagWithProtocol {
    if (![rendezvousTagWithProtocol hasPrefix:QredoRendezvousURIProtocol]) return nil;

    return [rendezvousTagWithProtocol substringFromIndex:QredoRendezvousURIProtocol.length];;
}

- (void)startProtocolWithConversation:(QredoConversation *)conversation
{
    self.conversationProtocol = [[QredoConversationProtocolFSM alloc] initWithConversation:conversation];

    NSString *fingerprint = [QredoKeychainTransporterHelper fingerprintWithConversation:conversation];

    __weak QredoKeychainSender *weakSelf = self;

    QredoConversationProtocolExpectingState  *expectReceiverDeviceInfoState
    = [[QredoConversationProtocolExpectingState alloc] initWithBlock:^BOOL(QredoConversationMessage * __nonnull message) {
        if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeDeviceInfo]) {
            weakSelf.receiverDeviceInfoMessage = message;
            return YES;
        }
        return NO;
    }];

    // TODO: move to receiver
    QredoConversationProtocolProcessingState *parseDeviceInfoState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        NSError *error = nil;
        weakSelf.receiverDeviceInfo
        = [QredoKeychainTransporterHelper parseDeviceInfoFromMessage:weakSelf.receiverDeviceInfoMessage
                                                               error:&error];

        if (!weakSelf.receiverDeviceInfo) {
            [state failWithError:error];
        } else {
            [state finishProcessing];
        }
    }];

    QredoConversationProtocolPublishingState *publishDeviceInfoState
    = [[QredoConversationProtocolPublishingState alloc] initWithBlock:^QredoConversationMessage * __nonnull {
        return [QredoKeychainTransporterHelper deviceInfoMessage];
    }];

    QredoConversationProtocolProcessingState *confirmSendingKeychainState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state)
       {
           weakSelf.confirmSendingState = state;

           [state onInterrupted:^{
               weakSelf.confirmSendingState = nil;
           }];

           [self.delegate qredoKeychainSender:weakSelf
             didEstablishConnectionWithDevice:weakSelf.receiverDeviceInfo
                                  fingerprint:fingerprint
                          confirmationHandler:^(BOOL confirmed)
            {
                if (confirmed) {
                    [weakSelf.confirmSendingState finishProcessing];
                    weakSelf.confirmSendingState = nil;
                } else {
                    [weakSelf.conversationProtocol cancel];
                }
            }];
       }];

    QredoConversationProtocolPublishingState *publishKeychainState
    = [[QredoConversationProtocolPublishingState alloc] initWithBlock:^QredoConversationMessage * __nonnull{
        NSData *keychainData = weakSelf.client.keychain.data;

        return [[QredoConversationMessage alloc] initWithValue:keychainData
                                                      dataType:QredoKeychainTransporterMessageTypeKeychain
                                                 summaryValues:nil];
    }];


    QredoConversationProtocolExpectingState *expectConfirmationMessageState
    = [[QredoConversationProtocolExpectingState alloc] initWithBlock:^BOOL(QredoConversationMessage * __nonnull message) {
        return [message.dataType isEqualToString: QredoKeychainTransporterMessageTypeConfirmReceiving];
    }];


    QredoConversationProtocolProcessingState *notifyFinishSendingState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        [weakSelf.delegate qredoKeychainSenderDidFinishSending:weakSelf];
        [state finishProcessing];
    }];

    [self.conversationProtocol addStates:@[expectReceiverDeviceInfoState,
                                           parseDeviceInfoState,
                                           publishDeviceInfoState,
                                           confirmSendingKeychainState,
                                           publishKeychainState,
                                           expectConfirmationMessageState,
                                           notifyFinishSendingState
                                           ]];

    [self.conversationProtocol startWithDelegate:self];
}

- (void)didDiscoverRendezvousTag:(NSString *)rendezvousTag
{
    [self.client respondWithTag:rendezvousTag
              completionHandler:^(QredoConversation *conversation, NSError *error)
     {
         if (cancelled) return ;

         if (error) {
             [self handleError:error];
             return ;
         }

         if (![conversation.metadata.type isEqualToString:QredoKeychainTransporterConversationType])
         {
             [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                                   code:QredoErrorCodeUnknown // TODO:
                                               userInfo:@{NSLocalizedDescriptionKey: @"Wrong conversation type"}]];
             return ;
         }

         [self startProtocolWithConversation:conversation];
     }];
}

// called when user presses "Cancel" in the UI, and when user doesn't confirm sending the keychain
- (void)cancel
{
    cancelled = true;

    if (self.conversationProtocol) {
        [self.conversationProtocol cancel];
    } else {
        if (clientCompletionHandler) clientCompletionHandler(nil);
    }
}

- (void)handleError:(NSError *)error
{
    [self.delegate qredoKeychainSender:self didFailWithError:error];
    if (clientCompletionHandler) clientCompletionHandler(error);
}

#pragma mark QredoConversationProtocolFSMDelegate

- (void)qredoConversationProtocolDidFinishSuccessfuly:(QredoConversationProtocolFSM *)protocol
{
    if (clientCompletionHandler) clientCompletionHandler(nil);
}

- (void)qredoConversationProtocol:(QredoConversationProtocolFSM *)protocol didFailWithError:(NSError *)error
{
    NSAssert(error, @"Should never fail without an error");
    [self.delegate qredoKeychainSender:self didFailWithError:error];
    if (clientCompletionHandler) clientCompletionHandler(error);
}



@end
