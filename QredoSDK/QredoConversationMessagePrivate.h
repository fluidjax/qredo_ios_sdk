/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationMessage.h"

typedef NS_ENUM(NSInteger, QredoConversationControlMessageType) {
    QredoConversationControlMessageTypeNotControlMessage = -2,
    QredoConversationControlMessageTypeUnknown = -1,
    QredoConversationControlMessageTypeJoined  = 0,
    QredoConversationControlMessageTypeLeft
};

extern NSString *const kQredoConversationMessageTypeControl;


@interface QredoConversationMessage (Private)

- (instancetype)initWithMessageLF:(QredoConversationMessageLF*)messageLF incoming:(BOOL)incoming;
// making read/write for private use
@property QredoConversationHighWatermark *highWatermark;


- (BOOL)isControlMessage;
- (QredoConversationControlMessageType)controlMessageType;

- (QredoConversationMessageLF*)messageLF;

@end