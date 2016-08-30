//
// MQTTEncoder.h
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

@protocol MQTTEncoderDelegate;

@interface MQTTEncoder : NSObject <NSStreamDelegate>

typedef NS_ENUM(NSInteger, MQTTEncoderEvent) {
    MQTTEncoderEventReady,
    MQTTEncoderEventErrorOccurred
} ;

typedef NS_ENUM(NSInteger, MQTTEncoderStatus) {
    MQTTEncoderStatusInitializing,
    MQTTEncoderStatusReady,
    MQTTEncoderStatusSending,
    MQTTEncoderStatusEndEncountered,
    MQTTEncoderStatusError
};

- (id)initWithStream:(NSOutputStream*)aStream
             runLoop:(NSRunLoop*)aRunLoop
         runLoopMode:(NSString*)aMode
      trustValidator:(MQTTSessionTrustValidator)aTrustValidator;
- (void)setDelegate:(id<MQTTEncoderDelegate>)aDelegate;
- (void)open;
- (void)close;
- (MQTTEncoderStatus)status;
- (void)stream:(NSStream*)sender handleEvent:(NSStreamEvent)eventCode;
- (void)encodeMessage:(MQTTMessage*)msg;

@end

@protocol MQTTEncoderDelegate <NSObject>

- (void)encoder:(MQTTEncoder*)sender handleEvent:(MQTTEncoderEvent)eventCode;

@end
