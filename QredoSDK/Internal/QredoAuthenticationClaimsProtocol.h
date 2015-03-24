/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoConversationProtocol.h"
#import "QredoClient.h"

@class QredoAuthenticationProtocol;
@protocol QredoAuthenticationProtocolDelegate

- (void)qredoAuthenticationProtocolDidSendClaims:(QredoAuthenticationProtocol *)protocol;;
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFailWithError:(NSError *)error;
- (void)qredoAuthenticationProtocol:(QredoAuthenticationProtocol *)protocol didFinishWithResults:(QLFAuthenticationResponse *)results;

@end


@interface QredoAuthenticationProtocol : QredoConversationProtocol
@property id<QredoAuthenticationProtocolDelegate> delegate;

- (void)sendAuthenticationRequest:(QLFAuthenticationRequest *)authenticationRequest;
- (void)cancel;

@end