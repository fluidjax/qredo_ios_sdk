/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_Qredo_h
#define QredoSDK_Qredo_h


#import <Foundation/Foundation.h>
#import "QredoQUID.h"
#import "QredoConversation.h"
#import "QredoTypes.h"
#import "QredoVault.h"
#import "QredoRendezvous.h"
#import "QredoErrorCodes.h"

// Revision 1
// See https://github.com/Qredo/ios-sdk/wiki/SDK-revisions

/** Options for [QredoClient initWithServiceURL:options:] */
extern NSString *const QredoClientOptionServiceURL;
extern NSString *const QredoRendezvousURIProtocol;

@class QredoClient;
@class QredoRendezvousMetadata;

@interface QredoClientOptions : NSObject

@property BOOL useMQTT;
@property BOOL resetData;


- (instancetype)initWithMQTT:(BOOL)useMQTT;
- (instancetype)initWithMQTT:(BOOL)useMQTT resetData:(BOOL)resetData;
- (instancetype)initWithResetData:(BOOL)resetData;

@end

/** Qredo Client */
@interface QredoClient : NSObject
/** Before using the SDK, the application should call this function with the required conversation types and vault data types.
 During the authorization the SDK may ask user to allow access to their Qredo account.
 
 If the app calls any Vault, Rendezvous or Conversation API without an authorization, then those methods will return `QredoErrorCodeAppNotAuthorized` error immediately.
 */
+ (void)authorizeWithConversationTypes:(NSArray*)conversationTypes vaultDataTypes:(NSArray*)vaultDataTypes completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler;

+ (void)authorizeWithConversationTypes:(NSArray*)conversationTypes vaultDataTypes:(NSArray*)vaultDataTypes options:(QredoClientOptions*)options completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler;

+ (void)openSettings;

- (void)closeSession;
- (BOOL)isClosed;

- (QredoVault*) defaultVault;

@end

@interface QredoClient (Rendezvous)

/** Creates an anonymous rendezvous and automatically stores it in the vault */
- (void)createAnonymousRendezvousWithTag:(NSString *)tag
                           configuration:(QredoRendezvousConfiguration *)configuration
                       completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Creates an authenticated rendezvous using internally generated keys and automatically stores it in the vault. Private key part is discarded, so keypair cannot be re-used for another rendezvous. */
- (void)createAuthenticatedRendezvousWithPrefix:(NSString *)prefix
                             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                  configuration:(QredoRendezvousConfiguration *)configuration
                              completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Creates an authenticated rendezvous using externally generated keys and automatically stores it in the vault. Externally generated keys can be re-used for other rendezvous. */
- (void)createAuthenticatedRendezvousWithPrefix:(NSString *)prefix
                             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                  configuration:(QredoRendezvousConfiguration *)configuration
                                      publicKey:(NSData *)publicKey
                                 signingHandler:(signDataBlock)signingHandler
                              completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Enumerates through the rendezvous that have been stored in the Vault
 @discussion assign YES to *stop to break the enumeration */
- (void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler;

/** Fetches previously created rendezvous that has been stored in the vault */
- (void)fetchRendezvousWithTag:(NSString *)tag completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Fetches previously created rendezvous that has been stored in the vault */
- (void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Joins the rendezvous and stores conversation into the vault */
- (void)respondWithTag:(NSString *)tag completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler;

/** Enumerates through the conversations that have been stored in the Vault
 @discussion assign YES to *stop to break the enumeration */
- (void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler;

- (void)fetchConversationWithId:(QredoQUID*)conversationId completionHandler:(void(^)(QredoConversation* conversation, NSError *error))completionHandler;

- (void)deleteConversationWithId:(QredoQUID*)conversationId completionHandler:(void(^)(NSError *error))completionHandler;

@end

#endif
