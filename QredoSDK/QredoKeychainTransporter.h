/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@class QredoKeychainReceiver;
@class QredoKeychainSender;

@interface QredoKeychainDeviceInfo : NSObject

@property NSString *name;

@end


/*
 In https://www.websequencediagrams.com

 App->+QredoClient: receiveKeychainWithCompletionHandler:
 QredoClient->+QredoKeychainReceiverQR: <<new>>
 QredoKeychainReceiverQR-->-QredoClient: receiverDelegate
 QredoClient-> QredoKeychainReceiver: initWithDelegate:senderDelegate

 QredoClient->-QredoKeychainReceiver: start

 QredoKeychainReceiver-->+QredoKeychainReceiverQR: qredoKeychainReceiverWillCreateRendezvous

 QredoKeychainReceiverQR->-UI: show spinner

 QredoKeychainReceiver->QredoClient: createRendezvousWithTag:randomTag
 QredoClient->QredoRendezvous: <<new>>
 QredoClient-->QredoKeychainReceiver: rendezvous

 QredoKeychainReceiver-->QredoKeychainReceiverQR: didCreateRendezvousWithTag:tag

 QredoKeychainReceiverQR->UI: show QR code

 QredoKeychainReceiver->QredoRendezvous: startListening

 opt
 QredoRendezvous->QredoKeychainReceiver: didReceiveReponse(conversation)
 QredoKeychainReceiver->QredoKeychainReceiver: deviceInfo
 QredoKeychainReceiver->QredoConversation: publishMessage(deviceInfo)

 QredoKeychainReceiver->+QredoKeychainReceiverQR: didEstablishConnectionWithFingerprint

 QredoKeychainReceiverQR-->-UI: hide QR, show fingerprint, "waiting for keychain"

 QredoKeychainReceiver->QredoConversation: startListening
 opt
 QredoConversation->QredoKeychainReceiver: didReceiveNewMessage(keychain)
 QredoKeychainReceiver->QredoKeychainReceiver: parseKeychain
 QredoKeychainReceiver->QredoConversation: publishMessage (confirm)
 QredoKeychainReceiver->QredoConversation: stopListening
 QredoKeychainReceiver->QredoClient: installKeychain
 QredoClient->App:completionHandler
 end
 end
*/
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

/*
 In https://www.websequencediagrams.com

 App->+QredoClient: sendKeychainWithCompletionHandler:
 QredoClient->+QredoKeychainSenderQR: <<new>>
 QredoKeychainSenderQR-->-QredoClient: senderDelegate
 QredoClient->QredoKeychainSender: initWithDelegate:senderDelegate

 QredoClient->-QredoKeychainSender: start

 QredoKeychainSender-->QredoKeychainSenderQR: qredoKeychainSenderDiscoveringRendezvous

 QredoKeychainSenderQR->UI: show QR scanner
 UI-->QredoKeychainSenderQR: scanned tag


 QredoKeychainSenderQR->+QredoKeychainSender: completionHander(tag)
 note right of QredoKeychainSender: verify tag (length, characters)
 QredoKeychainSender-->-QredoKeychainSenderQR: true

 QredoKeychainSenderQR-->UI: hide QR scanner

 QredoKeychainSender->QredoClient: respondWithTag:tag

 QredoClient->+QredoConversation: <<new>>
 QredoClient-->QredoKeychainSender: conversation
 QredoKeychainSender

 QredoKeychainSender->QredoConversation: startListening

 note over QredoKeychainSender, QredoConversation: Receiving device info

 QredoConversation->QredoKeychainSender: didReceiveNewMessage (device-name)

 QredoKeychainSender->+QredoKeychainSenderQR: didEstablishConnectionWithDevice

 QredoKeychainSenderQR->UI: show confirmation
 UI->QredoKeychainSenderQR: "confirm"

 QredoKeychainSenderQR->-QredoKeychainSender: confimrationHandler(true)

 note over QredoKeychainSender, QredoConversation: Sending keychain

 QredoKeychainSender->QredoClient: getKeychain (with device unlock)
 QredoClient->QredoKeychainSender: keychain

 QredoKeychainSender->QredoConversation: publishMessage(serializedKeychain)

 note over QredoKeychainSender, QredoConversation: Receive confirmation

 QredoConversation->QredoKeychainSender: didReceiveNewMessage (keychain-received)

 QredoKeychainSender->QredoKeychainSenderQR: didFinishSending
 QredoKeychainSenderQR->UI: hide

 QredoKeychainSender->App: completionHandler
 */
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