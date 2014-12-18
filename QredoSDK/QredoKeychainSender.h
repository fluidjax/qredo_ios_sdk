/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "QredoDeviceInfo.h"

@class QredoKeychainSender;
@class QredoClient;

@protocol QredoKeychainSenderDelegate <NSObject>

@required

// `cancelHandler` should be used in the same way as in `QredoKeychainReceiverDelegate`
- (void)qredoKeychainSenderDiscoverRendezvous:(QredoKeychainSender *)sender completionHander:(BOOL(^)(NSString *rendezvousTag))completionHandler cancelHandler:(void(^)())cancelHandler;

- (void)qredoKeychainSender:(QredoKeychainSender *)sender didFailWithError:(NSError *)error;

- (void)qredoKeychainSender:(QredoKeychainSender *)sender didEstablishConnectionWithDevice:(QredoDeviceInfo *)deviceInfo fingerprint:(NSString *)fingerprint confirmationHandler:(void(^)(BOOL confirmed))confirmationHandler;

- (void)qredoKeychainSenderDidFinishSending:(QredoKeychainSender *)sender;

@end


@interface QredoKeychainSender : NSObject

- (instancetype)initWithClient:(QredoClient*)client delegate:(id<QredoKeychainSenderDelegate>)delegate;

- (void)startWithCompletionHandler:(void(^)(NSError *error))completionHandler;

@end