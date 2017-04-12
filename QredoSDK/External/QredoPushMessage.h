/* HEADER GOES HERE */
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

/**
 Encapsulates the decoding of incoming Apple Push Notifications into Qredo Objects it contains the decrypted message and a refernece of it's parent 'QredoConversation'.
 The APN contains a Qredo Queue ID which is an internal representation of one side of a QredoConversation, this reference is used to lookup a reference
 to the coresponding QredoConversaition. This lookup table is stored in NSUserDefaults
 Although the Payload of the Push Notification is encrypted, the remaining parts of the Push Notification leaks some information - in particular the Queue ID could be used to group a number of Push Notificaiotns together. Careful thought should be given to the security requirements of your App, before using Push Notifications.
 
 Without a QredoClient object the Push Notificaiton can't be decrypted. So in order to automatically create a QredoClient when an incoming Push Message is
 received the Login/Credential values must be stored somewhere locally. See Qredo.h initializeFromUserDefaultCredentialsInAppGroup for more details.
 */
@interface QredoPushMessage : NSObject


/**
 Alert is not set to a meaningful value by the Qredo Server - as it is sent clear text and will therefore leak information
 You can safely ignore this message/value
 */
@property (readonly)        NSString* alert;


/**
 The content-available property in the APNS message
 */
@property (assign,readonly) BOOL contentAvailable;


/**
 The mutableContent property in the APNS message - this is currently always set to Yes, to enable a Push Notification Service Extension to run when the main app is not running/backgrounded.
 */
@property (assign,readonly) BOOL mutableContent;


/**
 An Enum Integer representing the 'QredoPushMessageType' of the incoming message.
 */
@property (assign,readonly) QredoPushMessageType messageType;

/**
 The QueueID that the message is sent on, this value is used to locally (NSUserDefaults) lookup the Conversation ID, and create the parent (of the message) QredoConversation object.
 */
@property (readonly)        QredoQUID *queueId;

/** QredoConversationMessage object for the incoming message */
@property (readonly)        QredoConversationMessage *conversationMessage;

/** QredoConversation owner of for the incoming message */
@property (readonly)        QredoConversation *conversation;

/** String representation of the incoming decrypted message */
@property (readonly)        NSString *incomingMessageText;


@property (readonly)        NSNumber *sequenceValue;
@property (readonly)        QredoConversationRef *conversationRef;



/** 
 Initializes a QredoPushMessage object with the contents passed in to the App from the Apple Push Notificaiotn server.
 
 @param message a dictionary passed into the App from iOS Push service. Available from UNNotificationRequest.content.userInfo.
 @param client a previously instantiated Qredo Client. If the QredfoPushMessage is instantiate with a QredoClient, the incoming message can't be decrypted.
 */
+(void)initializeWithRemoteNotification:(NSDictionary*)message
                            qredoClient:(QredoClient*)client
                      completionHandler:(void (^)(QredoPushMessage *pushMessage,NSError *error))completionHandler;

/**
 Initializes a QredoPushMessage object with the contents passed in to the App from the Apple Push Notificaiotn server. Without a QredoClient, the QredoPushMessage can't access the QredoConversation keys, and therefore can't decrypt the incoming message.
 
 @param message A dictionary passed into the App from iOS Push service. Available from UNNotificationRequest.content.userInfo.
 */

+(void)initializeWithRemoteNotification:(NSDictionary*)message
                      completionHandler:(void (^)(QredoPushMessage *pushMessage,NSError *error))completionHandler;

@end
