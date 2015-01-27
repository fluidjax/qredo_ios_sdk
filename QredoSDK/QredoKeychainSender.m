/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainSender.h"
#import "Qredo.h"
#import "QredoKeychainTransporterConsts.h"
#import "QredoPrivate.h"
#import "QredoVaultPrivate.h"
#import "QredoKeychain.h"

@interface QredoKeychainSender () <QredoConversationDelegate>
{
    // completion handler that is passed to startWithCompletionHandler:
    void(^clientCompletionHandler)(NSError *error);
    BOOL keychainHasBeenSent;
    BOOL cancelled;
}

@property id<QredoKeychainSenderDelegate> delegate;
@property QredoClient *client;
@property QredoConversation *conversation;

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

    [self.delegate qredoKeychainSenderDiscoverRendezvous:self completionHander:^BOOL(NSString *rendezvousTagWithProtocol) {

        BOOL validTag = YES;

        NSString *rendezvousTag = [self stringProtocolFromTag:rendezvousTagWithProtocol];


        if (!rendezvousTag) {
            validTag = NO;
        } else {
            validTag = [self verifyRendezvousTag:rendezvousTag];
        }

        if (!validTag) {
            completionHandler([NSError errorWithDomain:QredoErrorDomain
                                                  code:QredoErrorCodeUnknown
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

- (BOOL)verifyRendezvousTag:(NSString *)rendezvousTag
{
    return YES;
//    @try {
//        QredoQUID *quid = [[QredoQUID alloc] initWithQUIDString:rendezvousTag];
//        return quid != nil;
//    }
//    @catch (NSException *exception) {
//        return NO;
//    }

}

- (void)didDiscoverRendezvousTag:(NSString *)rendezvousTag
{
    [self.client respondWithTag:rendezvousTag completionHandler:^(QredoConversation *conversation, NSError *error) {
        @synchronized(self) {
            if (cancelled) return ;

            if (error) {
                [self handleError:error];
                return ;
            }

            if (![conversation.metadata.type isEqualToString:QredoKeychainTransporterConversationType])
            {
                [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                                      code:QredoErrorCodeUnknown // TODO
                                                  userInfo:@{NSLocalizedDescriptionKey : @"Wrong conversation type"}]];
                return ;
            }

            QredoConversationMessage *deviceInfoMessage = [[QredoConversationMessage alloc] initWithValue:nil dataType:QredoKeychainTransporterMessageTypeDeviceInfo
                                                                                            summaryValues:@{QredoKeychainTransporterMessageKeyDeviceName: @"iPhone"}];

            self.conversation = conversation;
            self.conversation.delegate = self;

            [conversation publishMessage:deviceInfoMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                if (error) {
                    [self handleError:error];
                    return;
                }
                
                [self.conversation startListening];
            }];

        }
    }];
}

- (void)stopCommunication
{
    [self.conversation stopListening];
}

// called when user presses "Cancel" in the UI, and when user doesn't confirm sending the keychain
- (void)cancel
{
    @synchronized(self) {
        cancelled = true;
        if (self.conversation) {
            // Notify the receiver that this device is not going to send anything
            QredoConversationMessage *cancelMessage = [[QredoConversationMessage alloc] initWithValue:nil
                                                                                             dataType:QredoKeychainTransporterMessageTypeCancelReceiving
                                                                                        summaryValues:nil];

            [self.conversation publishMessage:cancelMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
                [self stopCommunication];
            }];
        } else {
            [self stopCommunication];
        }

        if (clientCompletionHandler) {
            clientCompletionHandler([NSError errorWithDomain:QredoErrorDomain
                                                        code:QredoErrorCodeUnknown
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Transmission has been cancelled"}]);
        }
    }
}

- (void)handleError:(NSError *)error
{
    [self stopCommunication];
    [self.delegate qredoKeychainSender:self didFailWithError:error];
    if (clientCompletionHandler) clientCompletionHandler(error);
}

- (NSString *)fingerprint
{
    return [[self.conversation.metadata.conversationId QUIDString] substringToIndex:5];
}

- (void)didReceiveDeviceInfoMessage:(QredoConversationMessage *)message
{
    NSError *error = nil;
    QredoDeviceInfo *deviceInfo = [self parseDeviceInfoFromMessage:message error:&error];

    if (error) {
        [self handleError:error];
        return;
    }

    [self.delegate qredoKeychainSender:self didEstablishConnectionWithDevice:deviceInfo fingerprint:[self fingerprint]
                   confirmationHandler:^(BOOL confirmed) {

                       if (confirmed) {
                           [self sendKeychain];
                       } else {
                           // the delegate should hide all the UI at this point
                           [self cancel];
                       }

                   }];
}

- (void)sendKeychain
{
    NSData *keychainData = [[self.client.systemVault qredoKeychain] data];

    QredoConversationMessage *keychainMessage = [[QredoConversationMessage alloc] initWithValue:keychainData
                                                                                       dataType:QredoKeychainTransporterMessageTypeKeychain
                                                                                  summaryValues:nil];

    [self.conversation publishMessage:keychainMessage completionHandler:^(QredoConversationHighWatermark *messageHighWatermark, NSError *error) {
        self->keychainHasBeenSent = true;
    }];
}

- (QredoDeviceInfo*)parseDeviceInfoFromMessage:(QredoConversationMessage *)message error:(NSError**)error
{
    id deviceName = message.summaryValues[QredoKeychainTransporterMessageKeyDeviceName];

    if (!deviceName || ![deviceName isKindOfClass:[NSString class]]) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeUnknown userInfo:@{NSLocalizedDescriptionKey : @"Invalid device name"}];
        }
        return nil;
    }

    QredoDeviceInfo *info = [[QredoDeviceInfo alloc] init];

    info.name = deviceName;

    return info;
}

- (void)throwInconsistentState
{
    [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                          code:QredoErrorCodeUnknown // TODO
                                      userInfo:@{NSLocalizedDescriptionKey: @"Inconsistent state"}]];
}

- (void)didReceiveParsedConfirmationMessage:(QredoConversationMessage *)message
{
    if (!keychainHasBeenSent) {
        [self throwInconsistentState];
        return;
    }

    BOOL success = YES;
    // TODO: this message should contain flag if the parsing of the keychai was successful
    if (success) {
        [self.delegate qredoKeychainSenderDidFinishSending:self];

        if (clientCompletionHandler) clientCompletionHandler(nil);
    } else {
        [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                              code:QredoErrorCodeUnknown
                                          userInfo:@{NSLocalizedDescriptionKey: @"The other device failed to parse the keychain"}]];
    }
}

- (void)didReceiveCancelMessage:(QredoConversationMessage *)message
{
    if (!keychainHasBeenSent) {
        [self throwInconsistentState];
        return;
    }

    [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                          code:QredoErrorCodeUnknown
                                      userInfo:@{NSLocalizedDescriptionKey: @"The other device has cancelled the transmission"}]];
}


#pragma mark QredoConversationDelegate

- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message
{
    if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeDeviceInfo]) {
        [self didReceiveDeviceInfoMessage:message];
    } else if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeConfirmReceiving]) {
        [self didReceiveParsedConfirmationMessage:message];
    } else if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeCancelReceiving]) {
        [self didReceiveCancelMessage:message];
    } else {
        NSLog(@"Unsupported message type: %@", message.dataType);
        [self handleError:[NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeUnknown userInfo:@{NSLocalizedDescriptionKey : @"Received unknown message"}]];
    }
}

@end
