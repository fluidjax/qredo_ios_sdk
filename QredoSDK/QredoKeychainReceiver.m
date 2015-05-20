/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainReceiver.h"
#import "Qredo.h"
#import "QredoKeychainTransporterConsts.h"
#import "QredoPrivate.h"
#import "QredoKeychain.h"
#import "QredoConversationProtocolFSM.h"

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
@property QredoConversationProtocolFSM *conversationProtocol;

@property QredoConversationProtocolProcessingState *confirmKeychainState;

@property NSString *senderDeviceName;

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

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:QredoKeychainTransporterConversationType
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

    rendezvous.delegate = self;
    [rendezvous startListening];
}

- (QredoDeviceInfo*)deviceInfo
{
    QredoDeviceInfo *info = [[QredoDeviceInfo alloc] init];

    info.name = @"iPhone"; // TODO: put the device name

    return info;
}

- (void)startProtocolWithConversation:(QredoConversation *)conversation
{
    self.conversationProtocol = [[QredoConversationProtocolFSM alloc] initWithConversation:conversation];

    NSString *fingerprint = [self fingerPrintWithConversation:conversation];

    QredoConversationProtocolPublishingState *publishDeviceInfoState
    = [[QredoConversationProtocolPublishingState alloc] initWithBlock:^QredoConversationMessage * __nonnull{
        QredoDeviceInfo *deviceInfo = [self deviceInfo];

        return [[QredoConversationMessage alloc] initWithValue:nil
                                                      dataType:QredoKeychainTransporterMessageTypeDeviceInfo
                                                 summaryValues:@{QredoKeychainTransporterMessageKeyDeviceName: deviceInfo.name}];

    }];


    QredoConversationProtocolProcessingState *notifyDidSendDeviceInfoState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        if ([self.delegate respondsToSelector:@selector(qredoKeychainReceiverDidSendDeviceInfo:)]) {
            [self.delegate qredoKeychainReceiverDidSendDeviceInfo:self];
        }
        [state finishProcessing];
    }];

    QredoConversationProtocolExpectingState  *expectSenderDeviceInfoState
    = [[QredoConversationProtocolExpectingState alloc] initWithBlock:^BOOL(QredoConversationMessage * __nonnull message) {
        if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeDeviceInfo]) {
            self.senderDeviceName = message.summaryValues[QredoKeychainTransporterMessageKeyDeviceName];

            if (self.senderDeviceName) {
                return YES;
            }
        }
        return NO;
    }];

    QredoConversationProtocolProcessingState *showFingerprintState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        [self.delegate qredoKeychainReceiver:self didEstablishConnectionWithFingerprint:fingerprint];
    }];

    QredoConversationProtocolExpectingState *expectKeychainState
    = [[QredoConversationProtocolExpectingState alloc] initWithBlock:^BOOL(QredoConversationMessage * __nonnull message) {
        if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeKeychain] && message.value) {
            self.keychainData = message.value;
            return YES;
        }
        return NO;
    }];

    QredoConversationProtocolProcessingState *confirmKeychainState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        self.confirmKeychainState = state;
        [state onInterrupted:^{
            self.confirmKeychainState = nil;
        }];

        [self.delegate qredoKeychainReceiver:self didReceiveKeychainWithConfirmationHandler:^(BOOL confirmed) {
            [self.confirmKeychainState finishProcessing];
            self.confirmKeychainState = nil;
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
        BOOL parsed = [self parseKeychainFromData:self.keychainData error:&error];

        if (!parsed) {
            [state failWithError:error];
        } else {
            [state finishProcessing];
        }
    }];


    QredoConversationProtocolProcessingState *showParseConfirmationKeychainState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        [self.delegate qredoKeychainReceiver:self didReceiveKeychainWithConfirmationHandler:^(BOOL confirmed) {
            if (confirmed) {
                [state finishProcessing];
            } else {
                [self.conversationProtocol cancel];
            }
        }];
    }];

    QredoConversationProtocolProcessingState *installKeychainState
    = [[QredoConversationProtocolProcessingState alloc] initWithBlock:^(QredoConversationProtocolProcessingState * __nonnull state) {
        NSError *error = nil;
        if ([self installkeychainWithError:&error]) {
            [self.delegate qredoKeychainReceiverDidInstallKeychain:self];

            [state finishProcessing];
        } else {
            [state failWithError:error];
        }
    }];

    [self.conversationProtocol addStates:@[publishDeviceInfoState,
                                           notifyDidSendDeviceInfoState,
                                           expectSenderDeviceInfoState,
                                           showFingerprintState,
                                           expectKeychainState,
                                           confirmKeychainState,
                                           publishReceiptConfirmationState,
                                           parseKeychainState,
                                           showParseConfirmationKeychainState,
                                           installKeychainState]];
    [self.conversationProtocol startWithDelegate:self];
}

- (NSString *)fingerPrintWithConversation:(QredoConversation *)conversation
{
    return [[conversation.metadata.conversationId QUIDString] substringToIndex:QredoKeychainTransporterFingerprintLength];
}

- (BOOL)parseKeychainFromData:(NSData*)data error:(NSError **)error;
{
    QredoKeychain *keychain = nil;
    NSError *parseError = nil;

    @try {
        keychain = [[QredoKeychain alloc] initWithData:data];
    }
    @catch (NSException *exception) {
        parseError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeKeychainCouldNotBeRetrieved userInfo:@{NSLocalizedDescriptionKey: exception.description}];
    }

    
    BOOL success = keychain != nil;

    if (success) {
        self.keychain = keychain;
    } else {
        parseError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeUnknown userInfo:@{NSLocalizedDescriptionKey: @"Invalid keychain data"}];
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
}

- (void)qredoRendezvous:(QredoRendezvous *)rendezvous didTimeout:(NSError *)error
{
    // TODO: timeouts are not implemented right now and, therefore, not tested

    [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                          code:QredoErrorCodeUnknown // TODO: timeout error
                                      userInfo:nil]];
}

#pragma mark

- (void)qredoConversationProtocolDidFinishSuccessfuly:(QredoConversationProtocolFSM *)protocol
{
    if (clientCompletionHandler) clientCompletionHandler(nil);
}

- (void)qredoConversationProtocol:(QredoConversationProtocolFSM *)protocol didFailWithError:(NSError *)error
{
    NSAssert(error, @"Should never fail without an error");
    if (clientCompletionHandler) clientCompletionHandler(error);
}
@end
