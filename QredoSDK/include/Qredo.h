/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoConversation.h"
#import "QredoTypes.h"
#import "QredoVault.h"
#import "QredoRendezvous.h"
#import "QredoErrorCodes.h"
#import "QredoLogger.h"
@import CoreData;

// Revision 1
// See https://github.com/Qredo/ios-sdk/wiki/SDK-revisions

/** Options for [QredoClient initWithServiceURL:options:] */
extern NSString *const QredoClientOptionServiceURL;
extern NSString *const QredoRendezvousURIProtocol;
static long long QREDO_DEFAULT_INDEX_CACHE_SIZE = 250000000; //in bytes 250Meg

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
@property BOOL disableMetadataIndex;


- (instancetype)initWithDefaultTrustedRoots;
- (instancetype)initDefaultPinnnedCertificate;
- (instancetype)initWithPinnedCertificate:(QredoCertificate *)certificate;

@end

/** Qredo Client */
@interface QredoClient : NSObject
/** Before using the SDK, the application should call this function with the required conversation types and vault data types.
 During the authorization the SDK may ask user to allow access to their Qredo account.
 
 If the app calls any Vault, Rendezvous or Conversation API without an authorization, then those methods will return `QredoErrorCodeAppNotAuthorized` error immediately.
 
 appSecret  is a hex String supplied by Qredo
 userId     is a unique identifier for a user of the App, usually username or email address
 userSecret a password for the user of the App.
 
 */


+ (void)initializeWithAppSecret:(NSString*)appSecret
                         userId:(NSString*)userId
                     userSecret:(NSString*)userSecret
             completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler;

+ (void)initializeWithAppSecret:(NSString*)appSecret
                         userId:(NSString*)userId
                     userSecret:(NSString*)userSecret
                        options:(QredoClientOptions*)options
              completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler;

- (void)closeSession;
- (BOOL)isClosed;
- (QredoVault *) defaultVault;

/**
    Report the current version of the framework in Major.Minor.Patch format
 */
- (NSString *)versionString;

/**
     Report the current build number of the framework. (The number is total count of the number of Git commits)
 */
- (NSString *)buildString;

@end

@interface QredoClient (Rendezvous)



-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;


/** Creates an anonymous rendezvous and automatically stores it in the vault */
-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                       conversationType:(NSString*)conversationType
                               duration:(long)duration
                     unlimitedResponses:(BOOL)unlimitedResponses
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

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

/** Fetch previously created rendezvous that has been stored in the vault by tag */
-(void)fetchRendezvousWithTag:(NSString *)tag completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

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




