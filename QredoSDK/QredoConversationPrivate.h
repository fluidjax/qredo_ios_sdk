/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoConversationPrivate_h
#define QredoSDK_QredoConversationPrivate_h

#import "QredoConversation.h"
#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"


extern NSString *const kQredoConversationVaultItemLabelAmOwner;
extern NSString *const kQredoConversationVaultItemLabelId;
extern NSString *const kQredoConversationVaultItemLabelTag;
extern NSString *const kQredoConversationVaultItemLabelHwm;
extern NSString *const kQredoConversationVaultItemLabelType;


@class QredoClient;
@class QredoConversationDescriptor;

@interface QredoConversation (Private)

- (instancetype)initWithClient:(QredoClient *)client;
- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QredoConversationDescriptor*)descriptor;
- (instancetype)initWithClient:(QredoClient *)client rendezvousTag:(NSString *)rendezvousTag converationType:(NSString *)conversationTag transCap:(NSSet *)transCap;
// Generate the keys, conversation ID, queue IDs and will save in the vault
- (void)generateAndStoreKeysWithPrivateKey:(QredoDhPrivateKey*)privateKey publicKey:(QredoDhPublicKey*)publicKey rendezvousOwner:(BOOL)rendezvousOwner completionHandler:(void(^)(NSError *error))completionHandler;
- (void)respondToRendezvousWithTag:(NSString *)rendezvousTag completionHandler:(void(^)(NSError *error))completionHandler;

- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                           incoming:(BOOL)incoming
                  completionHandler:(void(^)(NSError *error))completionHandler
                              since:(QredoConversationHighWatermark*)sinceWatermark
               highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler
             excludeControlMessages:(BOOL)excludeControlMessages;


- (void)loadHighestHWMWithCompletionHandler:(void(^)(NSError *error))completionHandler;


@end

@interface QredoConversationMessage (Private)

- (BOOL)isControlMessage;
- (QredoConversationControlMessageType)controlMessageType;

@end

@interface QredoConversationHighWatermark (Private)

- (instancetype)initWithSequenceValue:(NSData*)sequenceValue;

@end

@interface QredoConversationMetadata (Private)

@property (readwrite) NSString *type;
@property (readwrite) QredoQUID *conversationId;
@property (readwrite) BOOL amRendezvousOwner;
@property (readwrite) NSString *rendezvousTag;

@end


#endif
