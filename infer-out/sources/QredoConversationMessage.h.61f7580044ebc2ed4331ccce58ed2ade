/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@class QredoQUID;
@class QredoConversation;
@class QredoConversationHighWatermark;

/**
 Represents a Conversation message. Contains the message itself, together with metadata
 
 @see Sending a Conversation Message: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/sending_a_conversation_message.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/sending_a_conversation_message.html)  
 Listening for Conversation Messages: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/listening_for_messages.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/listening_for_messages.html)

*/

@interface QredoConversationMessage :NSObject

#pragma mark - Properties

/** Identifies an individual message */
@property (readonly) QredoQUID *messageId;

/** The message metadata. Set when the message is created. */
@property (readonly) NSDictionary *summaryValues;

/** The conversationId of the `QredoConversation` that this message is a part of */
@property (readonly) QredoQUID *parentId;

/** YES if the current user received the message, NO if they sent it */
@property (readonly) BOOL incoming;

/** The current position within the `QredoConversation` */
@property (readonly) QredoConversationHighWatermark *highWatermark;

/** The message data 
 @see Sending a Conversation Message: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/sending_a_conversation_message.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/sending_a_conversation_message.html)
 */
@property (readonly) NSData *value;


#pragma mark - Methods

/** Called to initialise the message with the value and metadata 
 
 @see Sending a Conversation Message: [Objective-C](https://docs.qredo.com/ios/objective-c/programming_guide/html/conversations/sending_a_conversation_message.html), [Swift](https://docs.qredo.com/ios/swift/programming_guide/html/conversations/sending_a_conversation_message.html)
 
 @param value The message value as a `NSData` object
 @param summaryValues A dictionary of key/value pairs. These can be anything you like, but must be objects of the class `NSDate`, `NSNumber` or `NSString`

 */


-(instancetype)initWithValue:(NSData*)value
               summaryValues:(NSDictionary*)summaryValues;

@end
