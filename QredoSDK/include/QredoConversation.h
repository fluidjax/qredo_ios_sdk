/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoQUID.h"
#import "QredoConversationMessage.h"
#import "QredoTypes.h"

@class QredoVault;
@class QredoConversation;

extern NSString *const kQredoConversationVaultItemType;

@interface QredoConversationHighWatermark : NSObject

- (BOOL)isLaterThan:(QredoConversationHighWatermark*)other;

@end

extern QredoConversationHighWatermark *const QredoConversationHighWatermarkOrigin;

@interface QredoConversationRef : QredoObjectRef

@end

@interface QredoConversationMetadata : NSObject
/** Same as `QredoRendezvousConfiguration.conversationType` */
@property (readonly) QredoConversationRef *conversationRef;
@property (readonly) NSString *type;
@property (readonly) QredoQUID *conversationId;
@property (readonly) BOOL amRendezvousOwner;
@property (readonly) NSString *rendezvousTag;
@property (readonly) QredoVault* store;
@property (readonly, getter=isEphemeral) BOOL ephemeral;
@property (readonly, getter=isPersistent) BOOL persistent;
@end

@protocol QredoConversationObserver <NSObject>

@required
- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message;

@optional
- (void)qredoConversationOtherPartyHasLeft:(QredoConversation *)conversation;

@end

@interface QredoConversation : NSObject

- (QredoConversationMetadata *)metadata;
@property (readonly) QredoConversationHighWatermark* highWatermark;

- (void)resetHighWatermark;

- (void)publishMessage:(QredoConversationMessage *)message completionHandler:(void(^)(QredoConversationHighWatermark *messageHighWatermark, NSError *error))completionHandler;

/**
 The logic of acknowledging message receipt is not defined yet.
 */
- (void)acknowledgeReceiptUpToHighWatermark:(QredoConversationHighWatermark*)highWatermark;

- (void)addConversationObserver:(id<QredoConversationObserver>)observer;
- (void)removeConversationObaserver:(id<QredoConversationObserver>)observer;

- (QredoVault*)store;

- (void)deleteConversationWithCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)subscribeToMessagesWithBlock:(void(^)(QredoConversationMessage *message))block
       subscriptionTerminatedHandler:(void (^)(NSError *))subscriptionTerminatedHandler
                               since:(QredoConversationHighWatermark *)sinceWatermark
                highWatermarkHandler:(void(^)(QredoConversationHighWatermark *newWatermark))highWatermarkHandler;

/**
 @param block is called for every received message. If the block sets `stop` to `NO`, then it terminates the enumeration
 @param completionHandler is called when an error is occured during communication with the server
 */
- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block since:(QredoConversationHighWatermark*)sinceWatermark completionHandler:(void(^)(NSError *error))completionHandler;

- (void)enumerateSentMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block since:(QredoConversationHighWatermark*)sinceWatermark completionHandler:(void(^)(NSError *error))completionHandler;

@end
