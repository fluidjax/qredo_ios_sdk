/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversation.h"
#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"
#import "QredoConversationMessage.h"
#import "QredoClient.h"

extern NSString *const kQredoConversationVaultItemLabelAmOwner;
extern NSString *const kQredoConversationVaultItemLabelId;
extern NSString *const kQredoConversationVaultItemLabelTag;
extern NSString *const kQredoConversationVaultItemLabelHwm;
extern NSString *const kQredoConversationVaultItemLabelType;

@class QredoClient;
@class QLFConversationDescriptor;

@interface QredoConversation (Private)

@property (nonatomic, readonly) QredoClient *client;

- (instancetype)initWithClient:(QredoClient *)client;
- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QLFConversationDescriptor*)descriptor;

- (instancetype)initWithClient:(QredoClient *)client
            authenticationType:(QLFRendezvousAuthType *)authenticationType
                 rendezvousTag:(NSString *)rendezvousTag
               converationType:(NSString *)conversationType
                      transCap:(NSSet *)transCap;

// Generate the keys, conversation ID, queue IDs and will save in the vault
- (void)generateAndStoreKeysWithPrivateKey:(QredoDhPrivateKey*)privateKey publicKey:(QredoDhPublicKey*)publicKey rendezvousOwner:(BOOL)rendezvousOwner completionHandler:(void(^)(NSError *error))completionHandler;
- (void)respondToRendezvousWithTag:(NSString *)rendezvousTag completionHandler:(void(^)(NSError *error))completionHandler;

- (void)enumerateMessagesUsingBlock:(void(^)(QredoConversationMessage *message, BOOL *stop))block
                           incoming:(BOOL)incoming
             excludeControlMessages:(BOOL)excludeControlMessages
                              since:(QredoConversationHighWatermark*)sinceWatermark
                  completionHandler:(void(^)(NSError *error))completionHandler
               highWatermarkHandler:(void(^)(QredoConversationHighWatermark *highWatermark))highWatermarkHandler;

- (void)loadHighestHWMWithCompletionHandler:(void(^)(NSError *error))completionHandler;

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
