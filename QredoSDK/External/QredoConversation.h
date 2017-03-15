/* HEADER GOES HERE */
#import "QredoConversationMessage.h"
#import "QredoTypes.h"



@class QredoVault;
@class QredoQUID;



/** Represents the authentication status of a Conversation.
 This will be red, amber or green and is set by calling [otherPartyHasMyFingerPrint](../Classes/QredoConversation.html#/c:objc(cs)QredoConversation(im)otherPartyHasMyFingerPrint:) or [iHaveRemoteFingerPrint](../Classes/QredoConversation.html#/c:objc(cs)QredoConversation(im)iHaveRemoteFingerPrint:)
 
 */
typedef NS_ENUM (NSUInteger,QredoAuthenticationStatus) {
    /** Neither party has confirmed their Conversationpublic key fingerprint */
    QREDO_RED = 0,
    /** Only one party has confirmed their Conversation public key fingerprint */
    QREDO_AMBER = 1,
    /** Both parties have confirmed their Conversation public key fingerprints. The Conversation is fully authenticated */
    QREDO_GREEN = 2,
};


extern NSString *const kQredoConversationVaultItemType;

/** A constant used to specify the start of the Conversation. Used when enumerating Conversation messages  */
extern QredoConversationHighWatermark *const QredoConversationHighWatermarkOrigin;

/** The highwater mark is the marker from which to retrieve messages in a Conversation. Objects of this class are not created directly  */

@interface QredoConversationHighWatermark :NSObject

/**
 return YES if this watermark represents a higher location than the one specified.
 */

-(BOOL)isLaterThan:(QredoConversationHighWatermark *)other;
@end


/**
 Used to refer to a specific `QredoConversation`. Not created directly. Developers can find extract this value from the `QredoConversationMetadata`.
 */

@interface QredoConversationRef :QredoObjectRef
-(NSString *)description;
@end


/**
 Contains information about a `QredoConversation`. Accessed from `QredoConversation.metadata` and returned by [enumerateConversationsWithBlock](QredoClient.html#/c:objc(cs)QredoClient(im)enumerateConversationsWithBlock:completionHandler:)
 
 The properties are all read only.
 
 */

@interface QredoConversationMetadata :NSObject


/**
 Pass this to [fetchConversationWithRef](QredoClient.html#/c:objc(cs)QredoClient(im)fetchConversationWithRef:completionHandler:) to retrieve the `QredoConversation`
 */
@property (readonly) QredoConversationRef *conversationRef;

/** This value is not used */
@property (readonly) NSString *type;

/** This value is not used */
@property (readonly) QredoQUID *conversationId;

/** YES if this Conversation was created as a result of another user responding to a Rendezvous we created */
@property (readonly) BOOL amRendezvousOwner;

/** The Rendezvous tag for the Rendezvous from which this Conversation was created */
@property (readonly) NSString *rendezvousTag;

/** User dictionary of key/values associated with a conversation */
@property (readonly) NSDictionary *summaryValues;

@end


/** The protocol that must implemented by the object that listens for new messages received within a `QredoConversation`
 
 @see Listening for Conversation Messages: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/listening_for_messages.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/listening_for_messages.html)
 
 */

@protocol QredoConversationObserver <NSObject>

@required

/**
 Invoked when a new message is received in the Conversation.
 
 @param conversation The Conversation within which the new message is received
 @param message The new message
 
 @note this method must be implemented
 */

-(void)qredoConversation:(QredoConversation *)conversation
    didReceiveNewMessage:(QredoConversationMessage *)message;


@optional
/**
 
 Invoked when the other party to the Conversation leaves as a result of calling [deleteConversationWithCompletionHandler](../Classes/QredoConversation.html#/c:objc(cs)QredoConversation(im)deleteConversationWithCompletionHandler:)
 
 @note If the other party leaves the Conversation, they will no longer receive any more messages, but the message history will still be available.
 
 */

-(void)qredoConversationOtherPartyHasLeft:(QredoConversation *)conversation;
@end


/**
 Represents a secure channel of communication between two app users
 
 Objects of this class are never created directly, but returned by the Qredo SDK as a result of:
 
 - responding to a Rendezvous by calling [respondWithTag](QredoClient.html#/c:objc(cs)QredoClient(im)respondWithTag:completionHandler:)
 - enumerating the list of Conversations that the current user is a party to by calling [enumerateConversationsWithBlock](QredoClient.html#/c:objc(cs)QredoClient(im)enumerateConversationsWithBlock:completionHandler:)
 
 @note When a Conversation is established between two parties, as a result of one user responding to a Rendezvous, a Diffie-Hellman key exchange takes place between the creator and the responder. These keys are randomly generated and used to derive a further set of keys that are used to encrypt messages in such a way that only the two parties in the Conversation are able to read the messages.
 All of this is handled behind the scenes by the Qredo SDK, but you can use the fingerprints of the public keys to authenticate the Conversation and ensure that there has not been a 'man-in-the-middle' attack. See the [Authenticating a Conversation](#/Authenticating%20a%20Conversation) methods later in this section.
 
 */

@interface QredoConversation :NSObject

#pragma mark - Properties

/**
 The current highwatermark for this Conversation. This is used when enumerating `QredoConversationMessages`.
 */

@property (readonly) QredoConversationHighWatermark *highWatermark;

#pragma mark - Methods


/**
 @return the `QredoConversationMetadata` for this Conversation.
 */

-(QredoConversationMetadata *)metadata;

/**
 Resets the highwatermark to the start. Enumerating `QredoConversationMessages` will start from the beginning of the `QredoConversation`.
 */

-(void)resetHighWatermark;


#pragma mark - Updating Conversation Metadata

/**
 Sets up or updates the summaryValues stored in the `QredoConversationMetadata` for this Conversation.
 
 @param summaryValues A dictionary of key/value pairs. This will replace any existing summaryValues.
 
 @param completionHandler When this method completes error will be non nil if an error occurs.
 
 @note When the update is successful, the `QredoConversationRef` will be updated so you will need to update any stored references to this value.
 
 @see Updating Conversation Metadata: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/updating_a_conversation.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/updating_a_conversation)
 
 */


-(void)updateConversationWithSummaryValues:(NSDictionary *)summaryValues completionHandler:(void (^)(NSError *error))completionHandler;



#pragma mark - Sending a message


/**
 Send the specified message to the other party in the Conversation
 
 @param message The `QredoConversationMessage` to send.
 @param completionHandler Returns the new `QredoConversationHighWatermark` within this Conversation. error will be non nil if an error occurs.
 
 @see Sending a Conversation Message: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/sending_a_conversation_message.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/sending_a_conversation_message.html)
 
 */

-(void)publishMessage:(QredoConversationMessage *)message
    completionHandler:(void (^)(QredoConversationHighWatermark *messageHighWatermark,NSError *error))completionHandler;

#pragma mark - Listening for messages


/**
 
 Listen for `QredoConversationMessage` received within a Conversation
 
 Adds an observer that adopts the `QredoConversationObserver` protocol. The [qredoConversation](../Protocols/QredoConversationObserver.html#/c:objc(pl)QredoConversationObserver(im)qredoConversation:didReceiveNewMessage:
 ) method must be implemented.
 
 @see Listening for Conversation Messages: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/listening_for_messages.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/listening_for_messages.html)
 
 @param observer The object that implements the QredoConversationObserver protocol.
 
 */

-(void)addConversationObserver:(id<QredoConversationObserver>)observer;

/**
 Add Conversation listener, and in addition requests Push Notification Messages for the Apple Supplied DeviceToken specified.
 @note Observers are automatically deleted when you close the connection to the `QredoClient`, but push notifications subscriptions are persistent across sessions.
 */

-(void)addConversationObserver:(id<QredoConversationObserver>)observer withPushNotifications:(NSData*)deviceToken;


/**
 Stop listening for messages received in the Conversation and delete the observer object.
 @param observer to remove
 
 @note Observers are automatically deleted when you close the connection to the `QredoClient`.
 
 */
-(void)removeConversationObserver:(id<QredoConversationObserver>)observer;


#pragma mark - Deleting Conversations

/**
 Deletes the specified Conversation. No further messages can be sent and received within this Conversation.
 
 @param completionHandler error will be non nil if the Conversation cannot be deleted.
 
 @note The Conversation will only be deleted from this user's message queue, the other party will still be able to access the Conversation and all messages within it. The other party will be notified in [qredoConversationOtherPartyHasLeft](../Protocols/QredoConversationObserver.html#/c:objc(pl)QredoConversationObserver(im)qredoConversationOtherPartyHasLeft:) that the current user is no longer part of the Conversation.
 
 
 */


-(void)deleteConversationWithCompletionHandler:(void (^)(NSError *error))completionHandler;


#pragma mark - Listing messages


/**
 
 Goes through the messages received in a conversation and calls the specified code block for each one.
 
 @see Listing Conversation Messages: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/listing_conversation_messages.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/listing_conversation_messages.html)
 
 @param block Called for each `QredoConversationMessage`. Set `stop` to YES to terminate the enumeration
 @param sinceWatermark the point at which to start the search. Use `QredoConversationHighWatermarkOrigin` to start from the beginning of the Conversation
 @param completionHandler will be called if an error occurs, such as when there is a problem connecting to the server. error will be no nil.
 */
-(void)enumerateReceivedMessagesUsingBlock:(void (^)(QredoConversationMessage *message,BOOL *stop))block
                                     since:(QredoConversationHighWatermark *)sinceWatermark
                         completionHandler:(void (^)(NSError *error))completionHandler;


/**
 
 Goes through the messages sent in a conversation and calls the specified code block for each one.
 
 @see Listing Conversation Messages: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/listing_conversation_messages.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/listing_conversation_messages.html)
 
 @param block Called for each `QredoConversationMessage`. Set `stop` to YES to terminate the enumeration
 @param sinceWatermark the point at which to start the search. Use `QredoConversationHighWatermarkOrigin` to start from the beginning of the Conversation
 @param completionHandler will be called if an error occurs, such as when there is a problem connecting to the server. error will be no nil.
 */


-(void)enumerateSentMessagesUsingBlock:(void (^)(QredoConversationMessage *message,BOOL *stop))block
                                 since:(QredoConversationHighWatermark *)sinceWatermark
                     completionHandler:(void (^)(NSError *error))completionHandler;



#pragma mark - Authenticating a Conversation


/** Call if the other party in the Conversation confirms that they have the fingerprint to your Conversation public key */
-(void)otherPartyHasMyFingerPrint:(void (^)(NSError *error))completionHandler;

/** Call this if the other party to the Conversation confirms that you have their fingerprint */
-(void)iHaveRemoteFingerPrint:(void (^)(NSError *error))completionHandler;

/** Retrieve the Conversation [authentication status](../Enums/QredoAuthenticationStatus.html).
 This will be red if neither party has confirmed their fingerprint, amber if only one party has and green if both parties have confirmed their fingerprint and the conversation is fully authenticated
 
 @return The Conversation authentication status: red, amber or green */
-(QredoAuthenticationStatus)authTrafficLight;


/** Show my public key fingerprint as a hex string */
-(NSString *)showMyFingerPrint;

/** Show the other party's public key fingerprint as a hex string */
-(NSString *)showRemoteFingerPrint;





@end
