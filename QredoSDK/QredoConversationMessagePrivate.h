/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationMessage.h"
#import "QredoClient.h"

typedef NS_ENUM(NSInteger, QredoConversationControlMessageType) {
    QredoConversationControlMessageTypeNotControlMessage = -2,
    QredoConversationControlMessageTypeUnknown = -1,
    QredoConversationControlMessageTypeJoined  = 0,
    QredoConversationControlMessageTypeLeft
};

extern NSString *const kQredoConversationMessageTypeControl;


@interface QredoConversationMessage (Private)

- (instancetype)initWithMessageLF:(QLFConversationMessage*)messageLF incoming:(BOOL)incoming;
// making read/write for private use
@property QredoConversationHighWatermark *highWatermark;


- (BOOL)isControlMessage;
- (QredoConversationControlMessageType)controlMessageType;

- (QLFConversationMessage*)messageLF;

@end