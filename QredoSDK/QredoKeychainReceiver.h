/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "QredoDeviceInfo.h"

@class QredoKeychainReceiver;
@class QredoClient;

// see https://github.com/Qredo/qredo_ios_sdk/wiki/Keychain-Transporter
@protocol QredoKeychainReceiverDelegate <NSObject>

@required

// `cancelHandler` should be kept by the receiver delegate and called if user presses "Cancel" button.
// However, after getting calls `qredoKeychainReceiverDidReceiveKeychain:` or `qredoKeychainReceiver:didFailWithError:`, `cancelHandler` shall not be called
- (void)qredoKeychainReceiverWillCreateRendezvous:(QredoKeychainReceiver *)receiver;

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didCreateRendezvousWithTag:(NSString*)tag cancelHandler:(void(^)())cancelHandler;

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didEstablishConnectionWithFingerprint:(NSString*)fingerPrint;

- (void)qredoKeychainReceiverDidReceiveKeychain:(QredoKeychainReceiver *)receiver;

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didFailWithError:(NSError *)error;

@end

@interface QredoKeychainReceiver : NSObject

- (instancetype)initWithClient:(QredoClient*)client delegate:(id<QredoKeychainReceiverDelegate>)delegate;

- (void)start;

@end