/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainReceiver.h"
#import "Qredo.h"
#import "QredoKeychainTransporterConsts.h"

@interface QredoKeychainReceiver () <QredoRendezvousDelegate, QredoConversationDelegate>
{
    // completion handler that is passed to startWithCompletionHandler:
    void(^clientCompletionHandler)(NSError *error);
}

@property id<QredoKeychainReceiverDelegate> delegate;
@property QredoClient *client;
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
    [self.delegate qredoKeychainReceiverWillCreateRendezvous:self cancelHandler:^{
        [self cancel];
    }];

    NSString *randomTag = [[QredoQUID QUID] QUIDString];

    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc] initWithConversationType:QredoKeychainTransporterConversationType
                                                                                                 durationSeconds:[NSNumber numberWithUnsignedInteger:QredoKeychainTransporterRendezvousDuration]
                                                                                                maxResponseCount:@1];
    [self.client createRendezvousWithTag:randomTag configuration:configuration
                       completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                           if (error) {
                               [self handleError:error];
                               return;
                           }

                           [self didCreateRendezvous:rendezvous];
                       }];
}

- (void)cancel {

}

- (void)didCreateRendezvous:(QredoRendezvous *)rendezvous
{
    [self.delegate qredoKeychainReceiver:self didCreateRendezvousWithTag:rendezvous.tag];

    rendezvous.delegate = self;

    [rendezvous startListening];
}

- (QredoDeviceInfo*)deviceInfo
{
    QredoDeviceInfo *info = [[QredoDeviceInfo alloc] init];

    info.name = @"iPhone"; // TODO put the device name

    return info;
}

- (void)didPublishDeviceInfo
{
    [self.conversation startListening];
}

- (void)parseKeychainFromData:(NSData*)data
{
    BOOL success = YES;
    NSError *parseError = nil;

    // TODO parse

    if (success) {
        [self didParseKeychainSuccessfuly];
    } else {
        [self handleError:parseError];
    }
}

- (void)handleError:(NSError *)error
{
    [self cancel];
    [self.delegate qredoKeychainReceiver:self didFailWithError:error];
    clientCompletionHandler(error);
    // now this object can die
}

- (void)didParseKeychainSuccessfuly
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


- (void)didConfirmParsingKeychain
{
    [self.delegate qredoKeychainReceiverDidReceiveKeychain:self confirmationHandler:^(BOOL confirmed) {
        if (confirmed) {
            // TODO install keychain here
            clientCompletionHandler(nil);
        } else {
            [self cancel];
        }
    }];
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
    // TODO timeouts are not implemented right now and, therefore, not tested

    [self handleError:[NSError errorWithDomain:QredoErrorDomain
                                          code:QredoErrorCodeUnknown // TODO: timeout error
                                      userInfo:nil]];
}

#pragma mark QredoConversationDelegate

- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message
{
    if ([message.dataType isEqualToString:QredoKeychainTransporterMessageTypeKeychain]) {
        [self parseKeychainFromData:message.value];
    } else {
        NSLog(@"Unknown message type");
        // Probably even [self.delegate qredoKeychainReceiver:self didFailWithError:]
    }
}

@end
