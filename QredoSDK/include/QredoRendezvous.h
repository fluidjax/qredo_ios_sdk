/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoTypes.h"

/** Type definition for `QredoRendezvousHighWatermark`  */
typedef uint64_t QredoRendezvousHighWatermark;

/** A constant used to specify the start of the Rendezvous. Used when enumerating Conversation messages  */
extern const QredoRendezvousHighWatermark QredoRendezvousHighWatermarkOrigin;
/** Used internally  */
extern NSString *const kQredoRendezvousVaultItemType;
/** Used internally  */
extern NSString *const kQredoRendezvousVaultItemLabelTag;
/** Used internally  */
extern NSString *const kQredoRendezvousVaultItemLabelAuthenticationType;

/** Used to establish a secure Conversation between two app users using just a string tag.
 Objects of this class are returned by `createAnonymousRendezvousWithTagType`.
 
 @see Creating a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/creating_a_rendezvous.html),
 [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/creating_a_rendezvous.html)

 */







@class QredoRendezvous;

/** The protocol that must implemented by the object that listens for new messages received within a `QredoConversation`
 
 @see Listening for Conversation Messages: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/listening_for_messages.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/listening_for_messages.html)
 
 */

@protocol QredoRendezvousObserver <NSObject>

@required
/**
 Invoked when this Rendezvous is responded to
 
 @param conversation The Rendezvous being responded to
 @param message The Conversation created by Qredo from the Rendezvous
 
 @note this method must be implemented
 */
-(void)qredoRendezvous:(QredoRendezvous*)rendezvous
     didReceiveReponse:(QredoConversation *)conversation;

@end

/** Used to retrieve, activate and deactivate a particular Rendezvous. 
 
 Pass this ref to [fetchRendezvousWithRef](QredoClient.html#/c:objc(cs)QredoClient(im)fetchRendezvousWithRef:completionHandler:), [activateRendezvousWithRef](QredoClient.html#/c:objc(cs)QredoClient(im)activateRendezvousWithRef:duration:completionHandler:) and [deactivateRendezvousWithRef](QredoClient.html#/c:objc(cs)QredoClient(im)deactivateRendezvousWithRef:completionHandler:)

 Stored in the `QredoRendezvousMetadata`
 */

@interface QredoRendezvousRef :QredoObjectRef
-(NSString *)description;
@end


/** Contains information about a previously created Rendezvous. 
 Used to retrieve the `QredoRendezvousRef`
 
  `QredoRendezvousMetadata` objects are returned by [enumerateRendezvousWithBlock:completionHandler](QredoClient.html#/c:objc(cs)QredoClient(im)enumerateRendezvousWithBlock:completionHandler:)
 
 Other Rendezvous information can be accessed from the `QredoRendezvous`
*/

@interface QredoRendezvousMetadata :NSObject
/** Use this ref to retrieve, activate or deactivate a Rendezvous */
@property (readonly) QredoRendezvousRef *rendezvousRef;

/** The Rendezvous tag */
@property (readonly, copy) NSString *tag;
@end



/** 
 Represents a Rendezvous. 
 Created with [createAnonymousRendezvousWithTagType](QredoClient.html#/c:objc(cs)QredoClient(im)createAnonymousRendezvousWithTagType:completionHandler:)
 */


@interface QredoRendezvous :NSObject

#pragma mark - Properties

/** See `QredoRendezvousMetadata` */
@property (readonly) QredoRendezvousMetadata *metadata;

/** The duration in seconds after which the Rendezvous will expire. Expired Rendezvous can no longer be responded to.
 To activate an expired Rendezvous call [activateRendezvousWithRef](QredoClient.html#/c:objc(cs)QredoClient(im)activateRendezvousWithRef:duration:completionHandler:)
*/
@property (readonly) long duration;

/** Set to YES if the Rendezvous accepts multiple responses, otherwise only one response will be accepted before the Rendezvous expires */
@property (readonly) BOOL unlimitedResponses;

/** The date and time at which the Rendezvous expires. */
@property (readonly) NSDate *expiresAt;

/** The Rendezvous tag */
@property (readonly) NSString *tag;

/** Used to store the mark to search from when enumerating Conversations created for this Rendezvous
 Pass this as a parameter to [enumerateConversationsWithBlock](#/c:objc(cs)QredoRendezvous(im)enumerateConversationsWithBlock:completionHandler:
) */

@property (readonly) QredoRendezvousHighWatermark highWatermark;


/** Convert a readable tag into a hex tag */
+(NSString *)readableToTag:(NSString *)readableText;

/** The Rendezvous tag as a readbale string */
-(NSString *)readableTag;

/** Convert a hex tag into a readable string */
+(NSString *)tagToReadable:(NSString *)tag;


/** Resets the highwatermark so that the next enumeration starts from the first Conversation created from this Rendezvous */
-(void)resetHighWatermark;


#pragma mark - Listening for responses

/**
 
 Start listening for responses to this Rendezvous
 
 Adds an observer that adopts the `QredoRendezvousObserver` protocol. The [qredoRendezvous:didReceiveReponse](../Protocols/QredoRendezvousObserver.html#/c:objc(pl)QredoRendezvousObserver(im)qredoRendezvous:didReceiveReponse:) method must be implemented.
 
 @see Listening for Responses: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/listening_for_responses.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/rendezvous/listening_for_responses.html)
 
 @param observer The object that implements the QredoRendezvousObserver protocol.
 
 */

-(void)addRendezvousObserver:(id<QredoRendezvousObserver>)observer;


/**
 Stop listening for responses to this Rendezvous and delete the observer object
 
 @param observer The observer to remove
 
 @note Observers are automatically deleted when you close the connection to the `QredoClient`
 
 */

-(void)removeRendezvousObserver:(id<QredoRendezvousObserver>)observer;


#pragma mark - Listing Conversations

/**
 
 Goes through the Conversations created from this Rendezvous and calls the specified code block for each one passing the `QredoConversationMetadata`
 
 @see Listing Conversations created from a Rendezvous: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/listing_conversations_created_with_a_rendezvous.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/listing_conversations_created_with_a_rendezvous.html)
 
 @param block Called for each conversation. Set `stop` to YES to terminate the enumeration
 @param completionHandler will be called if an error occurs, such as when there is a problem connecting to the server. error will be no nil.
 */



-(void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata, BOOL *stop))block
                     completionHandler:(void (^)(NSError *error))completionHandler;


#pragma mark - Other methods

/** Deletes a Rendezvous. Not yet implemented.
 Use `deactivateRendezvous`
 @see [Deactivating a Rendezvous](https://docs.qredo.com/ios/objective-c/programming_guide/html/rendezvous/activating_and_deactivating_rendezvous.html)
 */
-(void)deleteWithCompletionHandler:(void (^)(NSError *error))completionHandler;


@end
