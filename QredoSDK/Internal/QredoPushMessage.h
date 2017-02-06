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

typedef NS_ENUM (NSUInteger,QredoPushMessageType) {
    QREDO_PUSH_UNKNOWNTYPE_MESSAGE = 0,
    QREDO_PUSH_CONVERSATION_MESSAGE = 0,
};


@interface QredoPushMessage : NSObject

@property (readonly) NSString* alert;
@property (assign,readonly) BOOL contentAvailable;
@property (assign,readonly) BOOL mutableContent;
@property (assign,readonly) int messageType;
@property (readonly) QredoQUID *queueId;



-(instancetype)initWithMessage:(NSDictionary*)message qredoClient:(QredoClient*)client;

@end
