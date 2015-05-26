/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainReceiver.h"
#import "Qredo.h"
#import "QredoKeychainTransporterConsts.h"
#import "QredoPrivate.h"
#import "QredoKeychain.h"
#import "QredoConversationProtocolFSM.h"
#import "QredoKeychainTransporterHelper.h"

@interface QredoKeychainReceiver () <QredoRendezvousDelegate, QredoConversationProtocolFSMDelegate>
{
    // completion handler that is passed to startWithCompletionHandler:
    void(^clientCompletionHandler)(NSError *error);
    BOOL cancelled;
}

@property (weak) id<QredoKeychainReceiverDelegate> delegate;
@property (weak) QredoClient *client;
@property QredoKeychain *keychain;
@property NSData *keychainData;
@property QredoRendezvous *rendezvous;
@property QredoConversationProtocolFSM *conversationProtocol;

@property QredoConversationProtocolProcessingState *confirmKeychainState;
@property QredoConversationMessage *senderDeviceInfoMessage;
@property QredoDeviceInfo *senderDeviceInfo;

@end

@implementation QredoKeychainReceiver

- (instancetype)initWithClient:(QredoClient*)client delegate:(id<QredoKeychainReceiverDelegate>)delegate
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
    [self.delegate qredoKeychainReceiver:self willCreateRendezvousWithCancelHandler:^{
        [self cancel];
    }];

    NSString *randomTag = [[QredoQUID QUID] QUIDString];

    QredoRendezvousConfiguration *configuration
    = [[QredoRendezvousConfiguration alloc] initWithConversationType:QredoKeychainTransporterConversationType
                                                     durationSeconds:@(QredoKeychainTransporterRendezvousDuration)
                                                    maxResponseCount:@1];

    [self.client createAnonymousRendezvousWithTag:randomTag
                                    configuration:configuration
                                completionHandler:^(QredoRendezvous *rendezvous, NSError *error)
     {
         if (cancelled) return ;

         if (error) {
             [self handleError:error];
             return;
         }
         [self didCreateRendezvous:rendezvous];

     }];
}

- (void)cancel {
    if (self.conversationProtocol)  {
        [self.conversationProtocol cancel];
    } else {
        if (clientCompletionHandler) clientCompletionHandler(nil);
    }
}

- (void)didCreateRendezvous:(QredoRendezvous *)rendezvous
{
    [self.delegate qredoKeychainReceiver:self
              didCreateRendezvousWithTag:[QredoRendezvousURIProtocol stringByAppendingString:rendezvous.tag]];

    self.rendezvous = rendezvous;
    self.rendezvous.delegate = self;
    [self.rendezvous startListening];
}

- (void)startProtocolWithConversation:(QredoConversation *)conversation
{
    self.conversationProtocol = [[QredoConversationProtocolFSM alloc] initWithConversation:conversation];

    NSString *fingerprint = [QredoKeychainTransporterHelper fingerprintWithConversation:conversation];

    __weak QredoKeychainReceiver *weakSelf = self;

    QredoConversationProtocolPublishingState *publishDeviceInfoState
    = [[QredoConversationProtocolPublishingState alloc] initWithBlock:^QredoConversationMessage * __nonnull{
        return [QredoKeychainTransporterHelper deviceInfoMessage];
    }];


    QredoConversationProtocolProcessingState *notifyDidSendDeviceInfoState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        if ([weakSelf.delegate respondsToSelector:@selector(qredoKeychainReceiverDidSendDeviceInfo:)]) {
            [weakSelf.delegate qredoKeychainReceiverDidSendDeviceInfo:weakSelf];
        }
        [state finishProcessing];
    }];

    QredoConversationProtocolExpectingState  *expectSenderDeviceInfoState
    = [[QredoConversationProtocolExpectingState alloc] initWithBlock:^BOOL(QredoConversationMessage * __nonnull message) {
        if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeDeviceInfo]) {
            weakSelf.senderDeviceInfoMessage = message;
            return YES;
        }
        return NO;
    }];

    QredoConversationProtocolProcessingState *parseSenderDeviceInfoState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state)
    {
        NSError *error = nil;
        weakSelf.senderDeviceInfo
        = [QredoKeychainTransporterHelper parseDeviceInfoFromMessage:weakSelf.senderDeviceInfoMessage
                                                               error:&error];

        if (!weakSelf.senderDeviceInfo) {
            [state failWithError:error];
        } else {
            [state finishProcessing];
        }
    }];

    QredoConversationProtocolProcessingState *showFingerprintState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        [weakSelf.delegate qredoKeychainReceiver:weakSelf didEstablishConnectionWithFingerprint:fingerprint];
        [state finishProcessing];
    }];

    QredoConversationProtocolExpectingState *expectKeychainState
    = [[QredoConversationProtocolExpectingState alloc] initWithBlock:^BOOL(QredoConversationMessage * __nonnull message) {
        if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeKeychain] && message.value) {
            weakSelf.keychainData = message.value;
            return YES;
        }
        return NO;
    }];

    QredoConversationProtocolProcessingState *confirmKeychainState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        weakSelf.confirmKeychainState = state;
        [state onInterrupted:^{
            weakSelf.confirmKeychainState = nil;
        }];

        [weakSelf.delegate qredoKeychainReceiver:weakSelf didReceiveKeychainWithConfirmationHandler:^(BOOL confirmed) {
            [weakSelf.confirmKeychainState finishProcessing];
            weakSelf.confirmKeychainState = nil;
        }];
    }];

    QredoConversationProtocolPublishingState *publishReceiptConfirmationState
    = [[QredoConversationProtocolPublishingState alloc] initWithBlock:^QredoConversationMessage * __nonnull{
        return [[QredoConversationMessage alloc] initWithValue:nil
                                                      dataType:QredoKeychainTransporterMessageTypeConfirmReceiving
                                                 summaryValues:nil];
    }];

    QredoConversationProtocolProcessingState *parseKeychainState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        NSError *error = nil;
        BOOL parsed = [weakSelf parseKeychainFromData:weakSelf.keychainData error:&error];

        if (!parsed) {
            [state failWithError:error];
        } else {
            [state finishProcessing];
        }
    }];


    QredoConversationProtocolProcessingState *showParseConfirmationKeychainState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        [weakSelf.delegate qredoKeychainReceiver:weakSelf didReceiveKeychainWithConfirmationHandler:^(BOOL confirmed) {
            if (confirmed) {
                [state finishProcessing];
            } else {
                [weakSelf.conversationProtocol cancel];
            }
        }];
    }];

    QredoConversationProtocolProcessingState *installKeychainState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        NSError *error = nil;
        if ([weakSelf installkeychainWithError:&error]) {
            [weakSelf.delegate qredoKeychainReceiverDidInstallKeychain:weakSelf];

            [state finishProcessing];
        } else {
            [state failWithError:error];
        }
    }];

    [self.conversationProtocol addStates:@[publishDeviceInfoState,
                                           notifyDidSendDeviceInfoState,
                                           expectSenderDeviceInfoState,
                                           parseSenderDeviceInfoState,
                                           showFingerprintState,
                                           expectKeychainState,
                                           confirmKeychainState,
                                           publishReceiptConfirmationState,
                                           parseKeychainState,
                                           showParseConfirmationKeychainState,
                                           installKeychainState]];
    [self.conversationProtocol startWithDelegate:self];
}

- (BOOL)parseKeychainFromData:(NSData*)data error:(NSError **)error;
{
    QredoKeychain *keychain = nil;
    NSError *parseError = nil;

    @try {
        keychain = [[QredoKeychain alloc] initWithData:data];
    }
    @catch (NSException *exception) {
        parseError = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeKeychainCouldNotBeRetrieved
                                     userInfo:@{NSLocalizedDescriptionKey: exception.description}];
    }

    
    BOOL success = keychain != nil;

    if (success) {
        self.keychain = keychain;
    } else {
        parseError = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeUnknown
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid keychain data"}];
    }

    if (error && parseError) {
        *error = parseError;
    }

    return success;
}

- (void)handleError:(NSError *)error
{
    [self.delegate qredoKeychainReceiver:self didFailWithError:error];
    if (clientCompletionHandler) clientCompletionHandler(error);
}

- (BOOL)installkeychainWithError:(NSError **)error
{
    return [self.client setKeychain:self.keychain error:error];
}

#pragma mark QredoRendezvousDelegate

- (void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    [self startProtocolWithConversation:conversation];
    [self.rendezvous stopListening];
    self.rendezvous = nil;
}

- (void)qredoRendezvous:(QredoRendezvous *)rendezvous didTimeout:(NSError *)error
{
    // TODO: timeouts are not implemented right now and, therefore, not tested

    [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                          code:QredoErrorCodeUnknown // TODO: timeout error
                                      userInfo:nil]];
}

#pragma mark QredoConversationProtocolFSMDelegate

- (void)qredoConversationProtocolDidFinishSuccessfuly:(QredoConversationProtocolFSM *)protocol
{
    if (clientCompletionHandler) clientCompletionHandler(nil);
}

- (void)qredoConversationProtocol:(QredoConversationProtocolFSM *)protocol didFailWithError:(NSError *)error
{
    NSAssert(error, @"Should never fail without an error");
    [self.delegate qredoKeychainReceiver:self didFailWithError:error];
    if (clientCompletionHandler) clientCompletionHandler(error);
}
@end
