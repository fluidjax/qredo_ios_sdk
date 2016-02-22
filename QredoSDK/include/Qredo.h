/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "QredoConversation.h"
#import "QredoConversationMessage.h"
#import "QredoErrorCodes.h"
#import "QredoLogger.h"
#import "QredoTypes.h"
#import "QredoVault.h"
#import "QredoRendezvous.h"
#import "QredoQUID.h"

@import CoreData;


@class QredoClient;
@class QredoRendezvousMetadata;
@class QredoCertificate;



/** Qredo Client */
@interface QredoClient :NSObject

/** Before using the SDK, the application should call this function with the required conversation types and vault data types.
 During the authorization the SDK may ask user to allow access to their Qredo account.
 
 If the app calls any Vault, Rendezvous or Conversation API without an authorization, then those methods will return `QredoErrorCodeAppNotAuthorized` error immediately.
 
 appSecret  is a hex String supplied by Qredo
 userId     is a unique identifier for a user of the App, usually username or email address
 userSecret a password for the user of the App.
 
 */
+(void)initializeWithAppSecret:(NSString*)appSecret
                        userId:(NSString*)userId
                    userSecret:(NSString*)userSecret
             completionHandler:(void (^)(QredoClient *client, NSError *error))completionHandler;



-(void)closeSession;
-(BOOL)isClosed;
-(QredoVault *)defaultVault;

/**
 Report the current version of the framework in Major.Minor.Patch format
 */
-(NSString *)versionString;
/**
 Report the current build number of the framework. (The number is total count of the number of Git commits)
 */
-(NSString *)buildString;

@end

@interface QredoClient (Rendezvous)


/** Creates an anonymous rendezvous and automatically stores it in the vault
 Defaults:
    Conversation Type is the Apps' AppID eg. "com.qredo.myapp"
    duration = infinte
    unlimitedResponses = YES
 */
-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;


/** Create an anonymous rendezvous with a random tag (32 chars alpha/numeric) */
-(void)createAnonymousRendezvousWithRandomTagCompletionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Creates an anonymous rendezvous and automatically stores it in the vault */
-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                               duration:(long)duration
                     unlimitedResponses:(BOOL)unlimitedResponses
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Enumerates through the rendezvous that have been stored in the Vault
 @discussion assign YES to *stop to break the enumeration */
-(void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block
                  completionHandler:(void (^)(NSError *error))completionHandler;

/** Fetch previously created rendezvous that has been stored in the vault by tag */
-(void)fetchRendezvousWithTag:(NSString *)tag
            completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Fetches previously created rendezvous that has been stored in the vault */
-(void)fetchRendezvousWithRef:(QredoRendezvousRef *)ref
            completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Fetches previously created rendezvous that has been stored in the vault */
-(void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata
                 completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Joins the rendezvous and stores conversation into the vault */
-(void)respondWithTag:(NSString *)tag
    completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler;


/** Enumerates through the conversations that have been stored in the Vault
 @discussion assign YES to *stop to break the enumeration */
-(void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata, BOOL *stop))block
                     completionHandler:(void (^)(NSError *error))completionHandler;

-(void)fetchConversationWithRef:(QredoConversationRef *)conversationRef
              completionHandler:(void (^)(QredoConversation* conversation, NSError *error))completionHandler;

-(void)deleteConversationWithRef:(QredoConversationRef *)conversationRef
               completionHandler:(void (^)(NSError *error))completionHandler;

/** Activates an existing Rendezvous.
 The duration is reset to the duration passed in. The response count is set to unlimited.
 Note that the RendezvousRef will be updated. Use rendezvous.metadata.rendezvousRef to access the updated ref */
-(void)activateRendezvousWithRef:(QredoRendezvousRef *)ref duration:(long)duration
               completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Deactivates a Rendezvous.
 Existing conversations established with this Rendezvous will still be available and are NOT closed
 New responses to the Rendezvous will fail. To accept new responses, activate the Rendezous again */
-(void)deactivateRendezvousWithRef:(QredoRendezvousRef *)ref
                 completionHandler:(void (^)(NSError *error))completionHandler;


@end