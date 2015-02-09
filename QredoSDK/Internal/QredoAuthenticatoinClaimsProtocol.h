/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoConversationProtocol.h"


@class QredoAuthenticationProtocol;
@protocol QredoAuthenticationProtocolDelegate

- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error;
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFinishWithResults:(NSArray *)results;

@end

@protocol QredoAuthenticationProtocolEvents <NSObject>

- (void)didSendClaims;
- (void)didFailToSendClaimsWithError:(NSError *)error;

- (void)didFinishSendingCancelMessage;
- (void)didFinishSendingMessageWithError:(NSError *)error;


@end

@interface QredoAuthenticationState : QredoConversationProtocolCancelableState <QredoAuthenticationProtocolEvents>
// Events

@end

@interface QredoAuthenticationProtocol : QredoConversationProtocol <QredoAuthenticationProtocolEvents>
@property id<QredoAuthenticationProtocolDelegate> delegate;
@end