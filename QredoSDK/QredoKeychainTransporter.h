/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@class QredoKeychainReceiver;
@class QredoKeychainSender;

@interface QredoKeychainDeviceInfo : NSObject

@property NSString *name;

@end


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

@protocol QredoKeychainSenderDelegate <NSObject>

@required

// `cancelHandler` should be used in the same way as in `QredoKeychainReceiverDelegate`
- (void)qredoKeychainSenderDiscoveringRendezvous:(QredoKeychainSender *)sender completionHander:(BOOL(^)(NSString *rendezvousTag))completionHandler cancelHandler:(void(^)())cancelHandler;

- (void)qredoKeychainSender:(QredoKeychainSender *)sender didFailWithError:(NSError *)error;

- (void)qredoKeychainSender:(QredoKeychainSender *)sender didEstablishConnectionWithDevice:(QredoKeychainDeviceInfo *)deviceInfo fingerprint:(NSString *)fingerprint confirmationHandler:(void(^)(BOOL confirmed))confirmationHandler;;

- (void)qredoKeychainSenderDidFinishSending:(QredoKeychainSender *)sender;

@end


@interface QredoKeychainReceiver : NSObject

- (instancetype)initWithDelegate:(id<QredoKeychainReceiverDelegate>)delegate;

- (void)start;

@end

@interface QredoKeychainSender : NSObject

- (instancetype)initWithDelegate:(id<QredoKeychainSenderDelegate>)delegate;

- (void)start;

@end