//
// MQTTDecoder.h
// MQtt Client
// 
// Copyright (c) 2011, 2013, 2lemetry LLC
// 
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// and Eclipse Distribution License v. 1.0 which accompanies this distribution.
// The Eclipse Public License is available at http://www.eclipse.org/legal/epl-v10.html
// and the Eclipse Distribution License is available at
// http://www.eclipse.org/org/documents/edl-v10.php.
//
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
// 

#import <Foundation/Foundation.h>
#import "MQTTMessage.h"
#import "MQTTTypes.h"

@protocol MQTTDecoderDelegate;

@interface MQTTDecoder : NSObject <NSStreamDelegate>

typedef enum {
    MQTTDecoderEventProtocolError,
    MQTTDecoderEventConnectionClosed,
    MQTTDecoderEventConnectionError
} MQTTDecoderEvent;

typedef NS_ENUM(NSInteger, MQTTDecoderStatus) {
    MQTTDecoderStatusInitializing,
    MQTTDecoderStatusDecodingHeader,
    MQTTDecoderStatusDecodingLength,
    MQTTDecoderStatusDecodingData,
    MQTTDecoderStatusConnectionClosed,
    MQTTDecoderStatusConnectionError,
    MQTTDecoderStatusProtocolError
};

- (id)initWithStream:(NSInputStream*)aStream
             runLoop:(NSRunLoop*)aRunLoop
         runLoopMode:(NSString*)aMode
      trustValidator:(MQTTSessionTrustValidator)aTrustValidator;
- (void)setDelegate:(id<MQTTDecoderDelegate>)aDelegate;
- (void)open;
- (void)close;
- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode;
@end

@protocol MQTTDecoderDelegate <NSObject>

- (void)decoder:(MQTTDecoder*)sender newMessage:(MQTTMessage*)msg;
- (void)decoder:(MQTTDecoder*)sender handleEvent:(MQTTDecoderEvent)eventCode;

@end
