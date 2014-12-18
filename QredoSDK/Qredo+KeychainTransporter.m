/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"
#import "QredoKeychainSender.h"
#import "QredoKeychainSenderQR.h"
#import "QredoKeychainReceiver.h"
#import "QredoKeychainReceiverQR.h"
#import "QredoPrivate.h"



@implementation QredoClient (KeychainTransporter)

- (void)sendKeychainWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    QredoKeychainSenderQR *qrSender = [[QredoKeychainSenderQR alloc] init];

    QredoKeychainSender *keychainSender = [[QredoKeychainSender alloc] initWithClient:self delegate:qrSender];
    self.keychainSender = keychainSender;

    [keychainSender startWithCompletionHandler:completionHandler];
}

- (void)receiveKeychainWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    QredoKeychainReceiverQR *qrDelegate = [[QredoKeychainReceiverQR alloc] init];

    QredoKeychainReceiver *keychainReceiver = [[QredoKeychainReceiver alloc] initWithClient:self delegate:qrDelegate];
    self.keychainReceiver = keychainReceiver;
    [keychainReceiver startWithCompletionHandler:completionHandler];
}


@end