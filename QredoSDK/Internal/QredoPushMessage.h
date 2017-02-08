//
//  QredoPushMessage.h
//  QredoSDK
//
//  Created by Christopher Morris on 06/02/2017.
//
//

#import <Foundation/Foundation.h>


@class QredoQUID;
@class QredoClient;
@class QredoConversation;
@class QredoConversationMessage;

typedef NS_ENUM (NSUInteger,QredoPushMessageType) {
    QREDO_PUSH_UNKNOWNTYPE_MESSAGE = 0,
    QREDO_PUSH_CONVERSATION_MESSAGE = 1,
};


@interface QredoPushMessage : NSObject

@property (readonly)        NSString* alert;
@property (assign,readonly) BOOL contentAvailable;
@property (assign,readonly) BOOL mutableContent;
@property (assign,readonly) int messageType;
@property (readonly)        QredoQUID *queueId;
@property (readonly)        QredoConversationMessage *conversationMessage;
@property (readonly)        QredoConversation *conversation;
@property (readonly)        NSString *incomingMessageText;
@property (readonly)        NSNumber *sequenceValue;

+(void)initializeWithRemoteNotification:(NSDictionary*)message
                            qredoClient:(QredoClient*)client
                      completionHandler:(void (^)(QredoPushMessage *pushMessage,NSError *error))completionHandler;

@end
