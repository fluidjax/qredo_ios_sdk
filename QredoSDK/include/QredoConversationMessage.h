/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

@class QredoQUID;
@class QredoConversation;
@class QredoConversationHighWatermark;

@interface QredoConversationMessage :NSObject

@property (readonly) QredoQUID *messageId;

@property (readonly) NSDictionary *summaryValues;
@property (readonly) QredoQUID *parentId;
@property (readonly) BOOL incoming;
@property (readonly) QredoConversationHighWatermark *highWatermark;
@property (readonly) NSData *value;


-(instancetype)initWithValue:(NSData*)value
               summaryValues:(NSDictionary*)summaryValues;

@end
