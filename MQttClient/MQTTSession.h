//
// MQTTSession.h
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
#import "MQTTDecoder.h"
#import "MQTTEncoder.h"
#import "MQTTTypes.h"

@protocol MQTTSessionDelegate;


typedef NS_ENUM(NSInteger, MQTTSessionStatus) {
    MQTTSessionStatusCreated,
    MQTTSessionStatusConnecting,
    MQTTSessionStatusConnected,
    MQTTSessionStatusError
};

typedef NS_ENUM(NSInteger, MQTTSessionEvent) {
    MQTTSessionEventConnected,
    MQTTSessionEventConnectionRefused,
    MQTTSessionEventConnectionClosed,
    MQTTSessionEventConnectionError,
    MQTTSessionEventProtocolError
};

@interface MQTTSession : NSObject

- (id)initWithClientId:(NSString*)theClientId;

- (id)initWithClientId:(NSString*)theClientId runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;

- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUsername
              password:(NSString*)thePassword;

- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUserName
              password:(NSString*)thePassword
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;

- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUsername
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)cleanSessionFlag;

- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUsername
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAlive
          cleanSession:(BOOL)theCleanSessionFlag
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theMode;

- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUserName
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)theCleanSessionFlag
             willTopic:(NSString*)willTopic
               willMsg:(NSData*)willMsg
               willQoS:(UInt8)willQoS
        willRetainFlag:(BOOL)willRetainFlag;

- (id)initWithClientId:(NSString*)theClientId
              userName:(NSString*)theUserName
              password:(NSString*)thePassword
             keepAlive:(UInt16)theKeepAliveInterval
          cleanSession:(BOOL)theCleanSessionFlag
             willTopic:(NSString*)willTopic
               willMsg:(NSData*)willMsg
               willQoS:(UInt8)willQoS
        willRetainFlag:(BOOL)willRetainFlag
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;

- (id)initWithClientId:(NSString*)theClientId
             keepAlive:(UInt16)theKeepAliveInterval
        connectMessage:(MQTTMessage*)theConnectMessage
               runLoop:(NSRunLoop*)theRunLoop
               forMode:(NSString*)theRunLoopMode;

- (void)dealloc;
- (void)close;
- (void)setDelegate:(id<MQTTSessionDelegate>)aDelegate;
- (void)connectToHost:(NSString*)ip port:(UInt32)port;
- (void)connectToHost:(NSString*)ip port:(UInt32)port usingSSL:(BOOL)usingSSL;
- (void)connectToHost:(NSString*)ip
                 port:(UInt32)port
usingSSLWithStreamSocketSecurityLevel:(CFStringRef)streamSocketSecurityLevel
       trustValidator:(MQTTSessionTrustValidator)trustValidator;
- (void)subscribeTopic:(NSString*)theTopic;
- (void)subscribeToTopic:(NSString*)topic atLevel:(UInt8)qosLevel;
- (void)unsubscribeTopic:(NSString*)theTopic;
- (void)publishData:(NSData*)theData onTopic:(NSString*)theTopic;
- (void)publishDataAtLeastOnce:(NSData*)theData onTopic:(NSString*)theTopic;
- (void)publishDataAtLeastOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag;
- (void)publishDataAtMostOnce:(NSData*)theData onTopic:(NSString*)theTopic;
- (void)publishDataAtMostOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag;
- (void)publishDataExactlyOnce:(NSData*)theData onTopic:(NSString*)theTopic;
- (void)publishDataExactlyOnce:(NSData*)theData onTopic:(NSString*)theTopic retain:(BOOL)retainFlag;
- (void)publishJson:(id)payload onTopic:(NSString*)theTopic;

@end

@protocol MQTTSessionDelegate <NSObject>

- (void)session:(MQTTSession*)session handleEvent:(MQTTSessionEvent)eventCode;
- (void)session:(MQTTSession*)session newMessage:(NSData*)data onTopic:(NSString*)topic;

@optional
- (void)session:(MQTTSession*)session evaluateTrustOfStream:(NSStream *)aStream;

@end