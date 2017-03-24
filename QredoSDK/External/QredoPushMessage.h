//
//  QredoPushMessage.h
//  QredoSDK
//
//  Created by Christopher Morris on 06/02/2017.

/**
  Encapsulates the decoding of incoming Apple Push Notifications into Qredo Objects representing the decrypted message and its parent (QredoConversation)
  The APN contains a Qredo Queue ID which is an internal representation of one side of a QredoConversation, this reference is used to lookup a reference
  to the coresponding QredoConversaition. This lookup table is store in NSUserDefaults
  Although the Payload of the Push Notification is Encrypted, the Push Notification leaks some information - in particular the  Queue ID could be used to group
  a number sequence of Push Notificaiotns together.

  Without a QredoClient object the Push Notificaiton can't be decrypted. So in order to automatically create a QredoClient when an incoming Push Message is
  received the Login/Credential values must be stored somewhere locally. See Qredo.h initializeFromUserDefaultCredentialsInAppGroup for more details.
 
 */

#import <Foundation/Foundation.h>

@class QredoQUID;
@class QredoClient;
@class QredoConversation;
@class QredoConversationMessage;
@class QredoConversationRef;

typedef NS_ENUM (NSUInteger,QredoPushMessageType) {
    QREDO_PUSH_UNKNOWNTYPE_MESSAGE = 0,
    QREDO_PUSH_CONVERSATION_MESSAGE = 1,
};


@interface QredoPushMessage : NSObject



/* The following properties are available read only once the PushMessage has been instatiated */

/**
 Alert is not set to a meaningful value by the Qredo Server - as it is sent clear text and will therefore leak information
*/
@property (readonly)        NSString* alert;


/**
 The content-available property in the APNS message
 */
@property (assign,readonly) BOOL contentAvailable;


/**
 The mutableContent property in the APNS message
 */

@property (assign,readonly) BOOL mutableContent;


@property (assign,readonly) QredoPushMessageType messageType;
@property (readonly)        QredoQUID *queueId;

/** QredoConversationMessage object for the incoming message */
@property (readonly)        QredoConversationMessage *conversationMessage;

/** QredoConversation owner of for the incoming message */
@property (readonly)        QredoConversation *conversation;

/* String representation of the incoming decrypted message */
@property (readonly)        NSString *incomingMessageText;


@property (readonly)        NSNumber *sequenceValue;
@property (readonly)        QredoConversationRef *conversationRef;



/** param message - A dictionary passed into the App from iOS Push service,
                        UNNotificationRequest.content.userInfo
    param client - A previously instantiated Qredo Client to enable - without a client the message can't be decrypted
 */

+(void)initializeWithRemoteNotification:(NSDictionary*)message
                            qredoClient:(QredoClient*)client
                      completionHandler:(void (^)(QredoPushMessage *pushMessage,NSError *error))completionHandler;

+(void)initializeWithRemoteNotification:(NSDictionary*)message
                      completionHandler:(void (^)(QredoPushMessage *pushMessage,NSError *error))completionHandler;

@end
