/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoClaimantAttestationSession.h"
#import "QredoClaimantAttestationSessionPrivate.h"



@implementation QredoAuthenticationResult
@end

@implementation QredoClaim : NSObject
@end


@implementation QredoClaimantAttestationSession

- (instancetype)initWithConversation:(QredoConversation *)conversation
{
    self = [super init];
    if (!self) return nil;

    self.conversation = conversation;

    return self;
}

- (void)startAuthentication
{
    // TODO [GR]: Implement this
}

- (void)cancelWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    // TODO [GR]: Implement this
}

- (void)finishAttestationWithResult:(BOOL)result completionHandler:(void(^)(NSError *error))completionHandler
{
    // TODO [GR]: Implement this
}


@end


