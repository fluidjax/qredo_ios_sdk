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
#import <CoreData/CoreData.h>
#import "QredoUtils.h"
#import "QredoIndexSummaryValues.h"

@class QredoClient;
@class QredoRendezvousMetadata;
@class QredoCertificate;


/** The security level used for a Rendezvous tag created with [createAnonymousRendezvousWithTagType](../Classes/QredoClient.html#/c:objc(cs)QredoClient(im)createAnonymousRendezvousWithTagType:completionHandler:)
 
 - Medium security tags have lower entropy but are more convenient to represent as a human readable string.
 - High security tags have high entropy, are guaranteed to be unique and are very difficult for another party to discover
 - We recommend only using medium security tags for testing during development */

/*
 Generated TAG lengths - use to define the key length when creating a rendezvous
 */
typedef NS_ENUM(NSUInteger, QredoSecurityLevel) {
    
    /**  6 bits tags that are represented by a 12 character hex string */
    QREDO_MEDIUM_SECURITY=6,
   
    /**  32 bit tags that are represented by a 64 character hex string */
    QREDO_HIGH_SECURITY=32
};


/**
 Used to manage connections to Qredo and create, manage and respond to Rendezvous.
 
 @note Your app must be initialised and connected to a network before using any Qredo services.
 */

@interface QredoClient :NSObject


#pragma mark - Creating and managing a Qredo session

/**
 Initializes the connection to Qredo and returns a `QredoClient` object to access Qredo services.
 
 The appID and appSecret will be generated for you by Qredo when you sign up for the developer program
 
 @note if a `QredoClient` object is returned this means that your app has been successfully initialised with Qredo and your credentials are correct.
 Subsequent calls to Qredo services such as Vault and Rendezvous will fail if you do not have a network connection, so always check the error codes returned from all Qredo functions.
 
 @see Connecting to Qredo: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/connecting_to_qredo/index.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/connecting_to_qredo/index.html)
 
 @param appSecret  a hex String supplied by Qredo. This is your API key for Qredo services.
 @param appSecret  a hex String supplied by Qredo. This uniquely identifies your app to Qredo
 @param userId     a unique identifier for a user of the App, usually username or email address
 @param userSecret a password for the user of the App.
 
 @param completionhandler Returns the `QredoClient` object or an error.
 The `QredoClient` parameter will be nil if the app cannot be initialized. See the note above.
 The `NSError` parameter will be non nil if an error has occured: `error.code` contains `QredoErrorCodeUnknown` if the credentials are incorrect or if the app cannot be initialised due to a network error. `error.localizedDescription` includes more information about the error.
 
 
 */

+(void)initializeWithAppId:(NSString*)appId
                 appSecret:(NSString*)appSecret
                    userId:(NSString*)userId
                userSecret:(NSString*)userSecret
         completionHandler:(void (^)(QredoClient *client, NSError *error))completionHandler;


/**
 Closes the connection to Qredo. Call this when you no longer require Qredo services.
 This method will remove any Vault, Conversation or ConversationMessage observers that were installed
 */

-(void)closeSession;


/**
 The status of the Qredo connection
 
 @return YES if the connection is closed, otherwise NO.
 */


-(BOOL)isClosed;



#pragma mark - Creating a Rendezvous


/** Creates an anonymous rendezvous and generates a random tag with the specified security level
 The duration and response count will be set to unlimited.
 
 @note We recommend using a security level of QREDO_MEDIUM_SECURITY only for testing during development
 
 @see Creating a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/creating_a_rendezvous.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/creating_a_rendezvous.html)
 
 
 @param tagSecurityLevel Use [QredoSecurityLevel](../Enums/QredoSecurityLevel.html) (QREDO_HIGH_SECURITY or QREDO_MEDIUM_SECURITY), to define the Security Level of the generated tag
 @param completionhandler returns a `QredoRendezvous` or nil if an error occurs. `error.code` contains `QredoErrorCodeRendezvousUnknownResponse` if the the app has not been initialised, or there is no network connection. `error.localizedDescription` includes more information about the error.
 
 */


-(void)createAnonymousRendezvousWithTagType:(QredoSecurityLevel)tagSecurityLevel
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;



/** Creates an anonymous rendezvous and generates a random tag with the specified security level. The duration and response count will be set to the values specified

 @note We recommend using a security level of QREDO_MEDIUM_SECURITY only for testing during development
 
 @see Creating a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/creating_a_rendezvous.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/creating_a_rendezvous.html)
 
 
 @param tagSecurityLevel Use [QredoSecurityLevel](../Enums/QredoSecurityLevel.html) (QREDO_HIGH_SECURITY or QREDO_MEDIUM_SECURITY), to define the Security Level of the generated tag
 @param duration the duration in seconds after which the Rendezvous will expire. Expired Rendezvous can no longer be responded to, but messages can still be sent within existing Conversations created from it. Expired Rendezvous can be reactivated by calling [activateRendezvousWithRef](#/c:objc(cs)QredoClient(im)deactivateRendezvousWithRef:completionHandler:)
 @param unlimitedResponses Set to YES if there can be an unlimited numbers of response to the Rendezvous. If the parameter is NO, then there can only be one response after which the Rendezvous will expire. Calling [activateRendezvousWithRef](#/c:objc(cs)QredoClient(im)deactivateRendezvousWithRef:completionHandler:)
 will set the response count to unlimited.
 @param completionhandler returns a `QredoRendezvous` or nil if an error occurs. `error.code` contains `QredoErrorCodeRendezvousUnknownResponse` if the the app has not been initialised, or there is no network connection. `error.localizedDescription` includes more information about the error.
 
 */


-(void)createAnonymousRendezvousWithTagType:(QredoSecurityLevel)tagSecurityLevel
                                   duration:(long)duration
                         unlimitedResponses:(BOOL)unlimitedResponses
                          completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;



#pragma mark - Retrieving a Rendezvous

/** Enumerates through all the Rendezvous created by the current app user passing the `QredoRendezvousMetadata` for each one.
 
 @param rendezvousMetadata The metadata for the current Rendezvous in the list. You can access the `QredoRendezvousRef` and tag from the metadata
 @param stop. Set this value to YES to stop the enumeration.
 @param completionHandler error will be non nil if an error occurs.
 
 @see Retrieving a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/listing_your_rendezvous.html)
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/listing_your_rendezvous.html)
 
 */

-(void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block
                  completionHandler:(void (^)(NSError *error))completionHandler;



/** Returns the QredoRendezvous represented by the specified tag.
 
 @note for performance reasons, we recommend using `fetchRendezvousWithRef` or `fetchRendezvousWithMetadata` instead of this method wherever possible.
 
 @param tag A string containing the tag of the `QredoRendezvous` to retrieve
 @param completionHandler rendezvous will be set to the QredoRendezvous or nil if it cannot be retrieved. If the Rendezvous cannot be found, then an error will be returned.
 
 @see Retrieving a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/listing_your_rendezvous.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/listing_your_rendezvous.html)
 
 */

-(void)fetchRendezvousWithTag:(NSString *)tag
            completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;



/** Returns the QredoRendezvous referred to by the specified `QredoRendezvousRef`.
 
 @note The `QredoRendezvousRef` can be retrieved from the `QredoRendezvousMetadata`.
 
 @see Retrieving a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/listing_your_rendezvous.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/listing_your_rendezvous.html)
 
 @param ref The `QredoRendevousRef` for the required `QredoRendevous`.
 @param completionHandler rendezvous will be set to the `QredoRendezvous` represented by the `QredoRendezvousRef` . If the Rendezvous cannot be found, then an error will be non nil and  error.code will be `QredoErrorCodeRendezvousNotFound`
 
 */
-(void)fetchRendezvousWithRef:(QredoRendezvousRef *)ref
               completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;


/** Returns the QredoRendezvous with the specified `QredoRendezvousMetadata`
 
 @note The `QredoRendezvousMetadata` can be retrieved from the `QredoRendezvous`. The metadata for each Rendezvous can be retrieved by calling `enumerateRendezvousWithBlock`
 
 @see Retrieving a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/listing_your_rendezvous.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/listing_your_rendezvous.html)
 
 @param metadata The `QredoRendezvousMetadata` for the required `QredoRendevous`.
 @param completionHandler rendezvous will be set to the `QredoRendezvous` represented by the `QredoRendezvousMetadata` . If the Rendezvous cannot be found, then an error will be non nil and  error.code will be `QredoErrorCodeRendezvousNotFound`
 */

-(void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata
                 completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;


#pragma mark - Responding to a Rendezvous

/** Respond to the Rendezvous with the specified tag. A secure `QredoConversation` will automatically be created between the creator and responder which you can then use to send and receive `QredoConversationMessage` objects
 
 
 @see Responding to a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/responding_to_a_rendezvous.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/responding_to_a_rendezvous.html)
 
 @param tag The string representing the tag of the Rendezvous to respond to.
 @param completionHandler conversation will be the QredoConversation created or nil if an error occured. error.code will be `QredoErrorCodeRendezvousNotFound`
 */

-(void)respondWithTag:(NSString *)tag
    completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler;


#pragma mark - Activating and Deactivating a Rendezvous

/** Activates an existing Rendezvous.
 The duration is reset to the duration passed in the duration parameter. The response count limit is set to NO (for unlimited responses)
 Note that the `QredoRendezvousRef` will be updated. Use rendezvous.metadata.rendezvousRef to access the updated ref and replace any stored values.
 
 @note This method can be called for any Rendezvous, irrespective of whether the Rendezvous has expired.
 
 @see Activating and Deactivating a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/activating_and_deactivating_rendezvous.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/activating_and_deactivating_rendezvous.html)
 
 
 @param tag The string representing the tag of the Rendezvous to respond to.
 @param completionHandler rendezvous will contain the activated Rendezvous or nil if an error occurs. error.code will contain `QredoErrorCodeRendezvousNotFound` if a Rendezvous with the specified `QredoRendezvousRef` cannot be found.
 
 
 */
-(void)activateRendezvousWithRef:(QredoRendezvousRef *)ref duration:(long)duration
               completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler;

/** Deactivates a Rendezvous.
 
 @note Existing conversations established with this Rendezvous will still be available and are NOT closed.
 New responses to the Rendezvous will fail. To accept new responses, activate the Rendezous again by calling `activateRendezvousWithRef`
 
 @see Activating and Deactivating a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/activating_and_deactivating_rendezvous.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/activating_and_deactivating_rendezvous.html)
 
 @param ref The `QredoRendezvousRef` for the Rendezvous to be deactivated
 @param completionHandler error will be non nil if an error occurs. error.code will be `QredoErrorCodeRendezvousNotFound` if a Rendezvous with the specified `QredoRendezvousRef` cannot be found.
 
 
 */
-(void)deactivateRendezvousWithRef:(QredoRendezvousRef *)ref
                 completionHandler:(void (^)(NSError *error))completionHandler;



#pragma mark - Conversation methods


/** Enumerates through all Conversations and sends back the `QredoConversationMetadata` for each one
 
 @note This method lists all Conversations that this user is a party to, whether as a result of responding to a Rendezvous or another user responding to a Rendezvous that this user created
 
 @see Listing all Conversations: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/listing_all_conversations.html),
 [Swift](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/listing_all_conversations.html)
 
 @param conversationMetadata The `QredoConversationMetadata` for the current Conversation being enumerated. The `QredoConversationRef` can be extracted from the metadata.
 @param stop Set to YES to stop the enumeration.
 @param completionHandler error will be non nil if an error occurs, such as no network connection.
 
 */
-(void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata, BOOL *stop))block
                     completionHandler:(void (^)(NSError *error))completionHandler;


/** Returns the `QredoConversation` referenced by the specified `QredoConversationRef`
 
 @param conversationRef The `QredoConversationRef` for the conversation to be retrieved
 @param completionHandler conversation  The `QredoConversation` or nil if the Conversation cannot be retrieved. error will be non nil if an error occurs. error.code will be `QredoErrorCodeConversationNotFound` if the conversation represented by the specified `QredoConversationRef` cannot be found.
 
 */

-(void)fetchConversationWithRef:(QredoConversationRef *)conversationRef
              completionHandler:(void (^)(QredoConversation* conversation, NSError *error))completionHandler;


/** This function is not currently implemented
 */

-(void)deleteConversationWithRef:(QredoConversationRef *)conversationRef
               completionHandler:(void (^)(NSError *error))completionHandler;


#pragma mark - Other methods

/** Returns an object used to access the app user's Vault.
 
 @see The Vault [Objective-C](https://docs.qredo.com/android/programming_guide/html/the_vault/index.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/the_vault/index.html)
 
 @warning If there is a problem initialising the app or connecting to the Qredo service, the default Vault will be nil, so always check before using it.
 
 @return The `QredoVault` object for the user's Vault. Use this to add and delete items and set up Vault listeners.
 
 */

-(QredoVault *)defaultVault;


/** Helper method to generate a random string of specified length using only chars from abcdefghjklmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ123456789
 
 @note this method is used by `createAnonymousRendezvousWithRandomTagCompletionHandler` to create a random tag
 
 @param len The length of the string to be generated
 
 @return `NSString` a random string of the specified length
 
 */

+(NSString *)randomStringWithLength:(int)len;


/**
 @return the current version of the framework in Major.Minor.Patch format
 */
-(NSString *)versionString;
/**
 @return the current build number of the framework. (The number is total count of the number of Git commits)
 */
-(NSString *)buildString;


/**
 @return the current Qredo network correctly DateTime - sync'd with NTP & TLS
 */
+(NSDate*)dateTime;

@end

