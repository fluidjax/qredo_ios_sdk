/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"
#import "QredoKeychainSender.h"
#import "QredoKeychainSenderQR.h"
#import "QredoKeychainReceiver.h"
#import "QredoKeychainReceiverQR.h"

@implementation QredoClient (KeychainTransporter)

- (void)sendKeychainWithCompletionHandler:(void(^)(NSError *error))completionHandler
{

    completionHandler([NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeUnknown userInfo:@{NSLocalizedDescriptionKey: @"Not implemented"}]);

}

- (void)receiveKeychainWithCompletionHandler:(void(^)(NSError *error))completionHandler
{

}


@end
