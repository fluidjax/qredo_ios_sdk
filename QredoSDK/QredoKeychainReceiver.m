/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainReceiver.h"
#import "Qredo.h"
#import "QredoKeychainTransporterConsts.h"
#import "QredoPrivate.h"
#import "QredoKeychain.h"

@interface QredoKeychainReceiver () <QredoRendezvousDelegate, QredoConversationDelegate>
{
    // completion handler that is passed to startWithCompletionHandler:
    void(^clientCompletionHandler)(NSError *error);
    BOOL cancelled;
}

@property id<QredoKeychainReceiverDelegate> delegate;
@property QredoClient *client;
@property QredoKeychain *keychain;
@property QredoConversation *conversation;

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
                                                                                                 durationSeconds:[NSNumber numberWithUnsignedInteger:QredoKeychainTransporterRendezvousDuration]
                                                                                                maxResponseCount:@1];
    
    // No signing handler needed as no authentication type provided above (so anonymous)
    [self.client createRendezvousWithTag:randomTag
                           configuration:configuration
                          signingHandler:nil
                       completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                           @synchronized (self) {
                               if (cancelled) return ;

                               if (error) {
                                   [self handleError:error];
                                   return;
                               }
                           }
                               [self didCreateRendezvous:rendezvous];

                       }];
}

- (void)sendCancellationMessage {
    QredoConversationMessage *confirmMessage = [[QredoConversationMessage alloc] initWithValue:nil
                                                                                      dataType:QredoKeychainTransporterMessageTypeCancelReceiving
                                                                                 summaryValues:nil];

    [self.conversation publishMessage:confirmMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
        if (error) {
            [self handleError:error];
            return ;
        }
        [self didConfirmParsingKeychain];
    }];
}

- (void)cancel {
    @synchronized(self) {
        cancelled = true;

        if (self.conversation) {
            [self sendCancellationMessage];
        }

        [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                              code:QredoErrorCodeUnknown // TODO
                                          userInfo:@{NSLocalizedDescriptionKey: @"User cancelled the transport"}]];
    }
}

- (void)didCreateRendezvous:(QredoRendezvous *)rendezvous
{
    [self.delegate qredoKeychainReceiver:self didCreateRendezvousWithTag:[QredoRendezvousURIProtocol stringByAppendingString:rendezvous.tag]];

    rendezvous.delegate = self;

    [rendezvous startListening];
}

- (QredoDeviceInfo*)deviceInfo
{
    QredoDeviceInfo *info = [[QredoDeviceInfo alloc] init];

    info.name = @"iPhone"; // TODO: put the device name

    return info;
}

- (void)didPublishDeviceInfo
{
    [self.conversation startListening];
    [self.delegate qredoKeychainReceiver:self didEstablishConnectionWithFingerprint:[[self.conversation.metadata.conversationId QUIDString] substringToIndex:QredoKeychainTransporterFingerprintLength]];
}

- (void)parseKeychainFromData:(NSData*)data
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
        [self didParseKeychainSuccessfuly];
    } else {
        parseError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeUnknown userInfo:@{NSLocalizedDescriptionKey: @"Invalid keychain data"}];
        [self sendCancellationMessage];
        [self handleError:parseError];
    }
}

- (void)stopCommunication {

}

- (void)handleError:(NSError *)error
{
    [self stopCommunication];
    [self.delegate qredoKeychainReceiver:self didFailWithError:error];
    if (clientCompletionHandler) clientCompletionHandler(error);
    // now this object can die
}

- (void)didParseKeychainSuccessfuly
{
    [self.delegate qredoKeychainReceiver:self didReceiveKeychainWithConfirmationHandler:^(BOOL confirmed) {
        if (confirmed) {
            NSError *error = nil;
            if ([self installkeychainWithError:&error]) {
                [self.delegate qredoKeychainReceiverDidInstallKeychain:self];
                if (clientCompletionHandler) clientCompletionHandler(nil);
                [self didConfirmInstallingKeychain];
            } else {
                [self handleError:error];
            }
        } else {
            [self cancel];
        }
    }];
}

- (BOOL)installkeychainWithError:(NSError **)error
{
    return [self.client setKeychain:self.keychain error:error];
}

- (void)didConfirmInstallingKeychain
{
    QredoConversationMessage *confirmMessage = [[QredoConversationMessage alloc] initWithValue:nil
                                                                                      dataType:QredoKeychainTransporterMessageTypeConfirmReceiving
                                                                                 summaryValues:nil];

    [self.conversation publishMessage:confirmMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
        if (error) {
            [self handleError:error];
            return ;
        }
        [self didConfirmParsingKeychain];
        
    }];
}

- (void)didConfirmParsingKeychain {
    [self stopCommunication];
}

- (void)didFailToParseKeychain {
    [self cancel];
}

#pragma mark QredoRendezvousDelegate

- (void)qredoRendezvous:(QredoRendezvous *)rendezvous didReceiveReponse:(QredoConversation *)conversation
{
    QredoDeviceInfo *deviceInfo = [self deviceInfo];

    QredoConversationMessage *deviceInfoMessage = [[QredoConversationMessage alloc] initWithValue:nil dataType:QredoKeychainTransporterMessageTypeDeviceInfo
                                                                                    summaryValues:@{QredoKeychainTransporterMessageKeyDeviceName: deviceInfo.name}];

    self.conversation = conversation;
    self.conversation.delegate = self;

    [conversation publishMessage:deviceInfoMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
        if (error) {
            [self handleError:error];
            return;
        }

        [self didPublishDeviceInfo];
    }];
}

- (void)qredoRendezvous:(QredoRendezvous *)rendezvous didTimeout:(NSError *)error
{
    // TODO: timeouts are not implemented right now and, therefore, not tested

    [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                          code:QredoErrorCodeUnknown // TODO: timeout error
                                      userInfo:nil]];
}

#pragma mark QredoConversationDelegate

- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message
{
    if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeKeychain]) {
        [self parseKeychainFromData:message.value];
    } else if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeDeviceInfo]) {
    } else {
        [self cancel];
    }
}

@end
