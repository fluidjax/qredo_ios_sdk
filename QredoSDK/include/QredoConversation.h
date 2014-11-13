/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoConversation_h
#define QredoSDK_QredoConversation_h

#import "QredoQUID.h"

extern NSString *const kQredoConversationVaultItemType;

@interface QredoConversationHighWatermark : NSObject

- (BOOL)isLaterThan:(QredoConversationHighWatermark*)other;

@end

extern QredoConversationHighWatermark *const QredoConversationHighWatermarkOrigin;

@class QredoConversation;
@interface QredoConversationMessage : NSObject
// metadata

@property (readonly) QredoQUID *messageId;
@property (readonly) NSString *dataType;
@property (readonly) NSDictionary *summaryValues;
@property (readonly) QredoQUID *parentId;
@property (readonly) BOOL incoming;

@property (readonly) QredoConversationHighWatermark *highWatermark;

@property (readonly) NSData *value;

- (instancetype)initWithValue:(NSData*)value dataType:(NSString*)dataType summaryValues:(NSDictionary*)summaryValues;

@end

@interface QredoConversationMetadata : NSObject
/** Same as `QredoRendezvousConfiguration.conversationType` */
@property (readonly) NSString *type;
@property (readonly) QredoQUID *conversationId;
@property (readonly) BOOL amRendezvousOwner;
@property (readonly) NSString *rendezvousTag;
@end

@protocol QredoConversationDelegate <NSObject>

@required
- (void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message;

@end

@interface QredoConversation : NSObject
/** See `QredoConversationDelegate` */
@property (weak) id<QredoConversationDelegate> delegate;

- (QredoConversationMetadata *)metadata;
@property (readonly) QredoConversationHighWatermark* highWatermark;

- (void)resetHighWatermark;

- (void)publishMessage:(QredoConversationMessage *)message completionHandler:(void(^)(QredoConversationHighWatermark *messageHighWatermark, NSError *error))completionHandler;

/**
 The logic of acknowledging message receipt is not defined yet.
 */
- (void)acknowledgeReceiptUpToHighWatermark:(QredoConversationHighWatermark*)highWatermark;

- (void)startListening;
- (void)stopListening;

/**
 Not implemented at the moment
 */
- (void)deleteConversation;

/**
 @param block is called for every received message. If the block sets `stop` to `NO`, then it terminates the enumeration
 @param completionHandler is called when an error is occured during communication with the server
 */
- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block since:(QredoConversationHighWatermark*)sinceWatermark completionHandler:(void(^)(NSError *error))completionHandler;

- (void)enumerateSentMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block since:(QredoConversationHighWatermark*)sinceWatermark completionHandler:(void(^)(NSError *error))completionHandler;


@end

#endif
