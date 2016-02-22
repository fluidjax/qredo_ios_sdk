/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationMessage.h"
#import "QredoTypes.h"

@class QredoVault;
@class QredoQUID;

extern NSString *const kQredoConversationVaultItemType;
extern QredoConversationHighWatermark *const QredoConversationHighWatermarkOrigin;


@interface QredoConversationHighWatermark :NSObject
-(BOOL)isLaterThan:(QredoConversationHighWatermark*)other;
@end



@interface QredoConversationRef :QredoObjectRef
@end



@interface QredoConversationMetadata :NSObject
@property (readonly) QredoConversationRef *conversationRef;
@property (readonly) NSString *type;
@property (readonly) QredoQUID *conversationId;
@property (readonly) BOOL amRendezvousOwner;
@property (readonly) NSString *rendezvousTag;
@property (readonly) QredoVault* store;
@end



@protocol QredoConversationObserver <NSObject>
@required
-(void)qredoConversation:(QredoConversation *)conversation didReceiveNewMessage:(QredoConversationMessage *)message;
@optional
-(void)qredoConversationOtherPartyHasLeft:(QredoConversation *)conversation;
@end



@interface QredoConversation :NSObject
@property (readonly) QredoConversationHighWatermark* highWatermark;
-(QredoConversationMetadata *)metadata;
-(void)resetHighWatermark;
-(void)publishMessage:(QredoConversationMessage *)message
    completionHandler:(void (^)(QredoConversationHighWatermark *messageHighWatermark, NSError *error))completionHandler;
-(void)acknowledgeReceiptUpToHighWatermark:(QredoConversationHighWatermark*)highWatermark;
-(void)addConversationObserver:(id<QredoConversationObserver>)observer;
-(void)removeConversationObserver:(id<QredoConversationObserver>)observer;
-(QredoVault*)store;
-(void)deleteConversationWithCompletionHandler:(void (^)(NSError *error))completionHandler;
-(void)subscribeToMessagesWithBlock:(void (^)(QredoConversationMessage *message))block
      subscriptionTerminatedHandler:(void (^)(NSError *))subscriptionTerminatedHandler
                              since:(QredoConversationHighWatermark *)sinceWatermark
               highWatermarkHandler:(void (^)(QredoConversationHighWatermark *newWatermark))highWatermarkHandler;


/**
 @param block is called for every received message. If the block sets `stop` to `NO`, then it terminates the enumeration
 @param completionHandler is called when an error is occured during communication with the server
 */
-(void)enumerateReceivedMessagesUsingBlock:(void (^)(QredoConversationMessage *message, BOOL *stop))block
                                     since:(QredoConversationHighWatermark*)sinceWatermark
                         completionHandler:(void (^)(NSError *error))completionHandler;

-(void)enumerateSentMessagesUsingBlock:(void (^)(QredoConversationMessage *message, BOOL *stop))block
                                 since:(QredoConversationHighWatermark*)sinceWatermark
                     completionHandler:(void (^)(NSError *error))completionHandler;



@end
