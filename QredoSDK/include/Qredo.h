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

typedef uint64_t QredoVaultSequenceValue;

/** Options for [QredoClient initWithServiceURL:options:] */
extern NSString *const QredoClientOptionVaultID;

@class QredoClient;
@class QredoRendezvousMetadata;

/** Delegate for Qredo client. Mainly notifies about notification status, as authentication might be done in background */
@protocol QredoClientDelegate <NSObject>
@optional
/** Called before attempting to authenticate and showing any authentication UI */
- (void)qredoClientWillAuthenticate:(QredoClient*)client;

/** Called when authentication has beed done in background */
- (void)qredoClientDidAuthenticate:(QredoClient *)client;
/** Called when authentication failed*/
- (void)qredoClient:(QredoClient *)client didFailAuthenticationWithError:(NSError *)error;
- (void)qredoClient:(QredoClient *)client didCloseSessionWithError:(NSError *)error;

/** for any generic errors, such as connection problem, out of disk space, failed signature verification or anything else */
- (void)qredoClient:(QredoClient *)client didFailWithError:(NSError *)error;

@end

/** Qredo Client */
@interface QredoClient : NSObject
@property (weak) id<QredoClientDelegate>delegate;
@property (readonly) NSURL *serviceURL;

/** Creates instance of qredo client
 @param serviceURL Root URL for Qredo services
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL;
/** 
 @param serviceURL serviceURL Root URL for Qredo services
 @param options qredo options. At the moment there is only `QredoClientOptionVaultID`
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL options:(NSDictionary*)options;

// Authentication. Can be skipped for now
// These calls might not be necessary, as authentication does happen implicitly on other calls (may show UI)
- (BOOL)isAuthenticated;
- (void)authenticateWithCompletionHandler:(void(^)(NSError *error))completionHandler; // show UI
- (void)closeSession;

- (QredoVault*) defaultVault;

@end

@interface QredoClient (Rendezvous)

/** Creates a rendezvous and automatically stores it in the vault */
- (void)createRendezvousWithTag:(NSString *)tag configuration:(QredoRendezvousConfiguration *)configuration completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

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
@end

#endif
