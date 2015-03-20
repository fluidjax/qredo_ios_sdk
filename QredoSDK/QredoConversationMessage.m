/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationMessage.h"
#import "NSDictionary+IndexableSet.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoConversationMessagePrivate.h"

NSString *const kQredoConversationMessageTypeControl = @"Ctrl";

@interface QredoConversationMessage ()

@property QredoQUID *messageId;
@property QredoConversationHighWatermark *highWatermark;
@property QredoQUID *parentId;

@end


@implementation QredoConversationMessage

- (instancetype)initWithMessageLF:(QLFConversationMessageLF*)messageLF incoming:(BOOL)incoming
{
    self = [self initWithValue:messageLF.value
                      dataType:messageLF.metadata.dataType
                 summaryValues:[messageLF.metadata.summaryValues dictionaryFromIndexableSet]];
    if (!self) return nil;

    _messageId = messageLF.metadata.id;
    _parentId = [messageLF.metadata.parentId anyObject];
    _incoming = incoming;

    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return self; // for immutable objects
}

- (instancetype)initWithValue:(NSData*)value dataType:(NSString*)dataType summaryValues:(NSDictionary*)summaryValues
{
    self = [super init];
    if (!self) return nil;

    _dataType = [dataType copy];
    _value = [value copy];
    _summaryValues = [summaryValues copy];

    return self;
}

- (QLFConversationMessageLF*)messageLF
{
    NSSet* summaryValuesSet = [self.summaryValues indexableSet];

    QLFConversationMessageMetaDataLF *messageMetadata =
    [QLFConversationMessageMetaDataLF conversationMessageMetaDataLFWithID:[QredoQUID QUID]
                                                                   parentId:self.parentId ? [NSSet setWithObject:self.parentId] : nil
                                                                   sequence:nil // TODO
                                                                   dataType:self.dataType
                                                              summaryValues:summaryValuesSet];

    QLFConversationMessageLF *message = [[QLFConversationMessageLF alloc] initWithMetadata:messageMetadata value:self.value];
    return message;

}

- (BOOL)isControlMessage
{
    return [self.dataType isEqualToString:kQredoConversationMessageTypeControl];
}

- (QredoConversationControlMessageType)controlMessageType
{
    if (![self isControlMessage]) return QredoConversationControlMessageTypeNotControlMessage;



    NSData *qrvValue = [QredoPrimitiveMarshallers marshalObject:[QLFCtrl qRV]
                                                     marshaller:[QLFCtrl marshaller]];


    if ([self.value isEqualToData:qrvValue]) return QredoConversationControlMessageTypeJoined;

    NSData *qrtValue = [QredoPrimitiveMarshallers marshalObject:[QLFCtrl qRT]
                                                     marshaller:[QLFCtrl marshaller]];


    if ([self.value isEqualToData:qrtValue]) return QredoConversationControlMessageTypeLeft;

    return QredoConversationControlMessageTypeUnknown;
}


@end