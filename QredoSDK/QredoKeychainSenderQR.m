/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainSenderQR.h"

@implementation QredoKeychainSenderQR

- (void)qredoKeychainSenderDiscoverRendezvous:(QredoKeychainSender *)sender completionHander:(BOOL(^)(NSString *rendezvousTag))completionHandler cancelHandler:(void(^)())cancelHandler
{

}

- (void)qredoKeychainSender:(QredoKeychainSender *)sender didFailWithError:(NSError *)error
{

}

- (void)qredoKeychainSender:(QredoKeychainSender *)sender didEstablishConnectionWithDevice:(QredoDeviceInfo *)deviceInfo fingerprint:(NSString *)fingerprint confirmationHandler:(void(^)(BOOL confirmed))confirmationHandler
{

}

- (void)qredoKeychainSenderDidFinishSending:(QredoKeychainSender *)sender
{

}

@end
