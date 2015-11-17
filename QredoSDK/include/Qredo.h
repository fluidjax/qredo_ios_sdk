/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
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
@class QredoCertificate;


typedef NS_ENUM(NSUInteger, QredoClientOptionsTransportType) {
    QredoClientOptionsTransportTypeHTTP,
    QredoClientOptionsTransportTypeMQTT,
    QredoClientOptionsTransportTypeWebSockets,
};


@interface QredoClientOptions : NSObject

@property (nonatomic) QredoClientOptionsTransportType transportType;
@property BOOL resetData;

- (instancetype)initWithDefaultTrustedRoots;
- (instancetype)initDefaultPinnnedCertificate;
- (instancetype)initWithPinnedCertificate:(QredoCertificate *)certificate;

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

/** Creates an authenticated rendezvous using externally generated keys and automatically stores it in the vault. Externally generated keys can be re-used for other rendezvous. Public key is either base58 for Ed25519, or PEM for X.509 and RSA formats */
- (void)createAuthenticatedRendezvousWithPrefix:(NSString *)prefix
                             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                  configuration:(QredoRendezvousConfiguration *)configuration
                                      publicKey:(NSString *)publicKey
                                trustedRootPems:(NSArray *)trustedRootPems
                                        crlPems:(NSArray *)crlPems
                                 signingHandler:(signDataBlock)signingHandler
                              completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Enumerates through the rendezvous that have been stored in the Vault
 @discussion assign YES to *stop to break the enumeration */
- (void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler;

/** Fetches previously created rendezvous that has been stored in the vault */
- (void)fetchRendezvousWithRef:(QredoRendezvousRef *)ref completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Fetches previously created rendezvous that has been stored in the vault */
- (void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Joins the rendezvous and stores conversation into the vault */
- (void)respondWithTag:(NSString *)tag
     completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler;

/** Joins the rendezvous and stores conversation into the vault */
- (void)respondWithTag:(NSString *)tag
       trustedRootPems:(NSArray *)trustedRootPems
               crlPems:(NSArray *)crlPems
     completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler;

/** Enumerates through the conversations that have been stored in the Vault
 @discussion assign YES to *stop to break the enumeration */
- (void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler;

- (void)fetchConversationWithRef:(QredoConversationRef *)conversationRef completionHandler:(void(^)(QredoConversation* conversation, NSError *error))completionHandler;

- (void)deleteConversationWithRef:(QredoConversationRef *)conversationRef completionHandler:(void(^)(NSError *error))completionHandler;

/** Activates an existing Rendezvous. 
 The duration is reset to the duration passed in. The response count is set to unlimited.
 Note that the RendezvousRef will be updated. Use rendezvous.metadata.rendezvousRef to access the updated ref */
- (void)activateRendezvousWithRef:(QredoRendezvousRef *)ref  duration:(NSNumber *)duration
        completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Deactivates a Rendezvous.
Existing conversations established with this Rendezvous will still be available and are NOT closed
New responses to the Rendezvous will fail. To accept new responses, activate the Rendezous again */
 - (void)deactivateRendezvousWithRef:(QredoRendezvousRef *)ref completionHandler:(void(^)(NSError *error))completionHandler;

@end
