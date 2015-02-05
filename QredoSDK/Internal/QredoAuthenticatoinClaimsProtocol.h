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

@interface QredoAuthenticationState : QredoConversationProtocolCancelableState
// Events
@end

@interface QredoAuthenticationProtocol : QredoConversationProtocol
@property id<QredoAuthenticationProtocolDelegate> delegate;
@end