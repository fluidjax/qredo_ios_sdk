/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"
#import "QredoClaimantAttestationSession.h"
#import "QredoClaimantAttestationProtocol.h"
#import "QredoAuthenticatoinClaimsProtocol.h"

@interface QredoClaimantAttestationSession ()
    <QredoClaimantAttestationProtocolDelegate, QredoClaimantAttestationProtocolDataSource,
     QredoAuthenticationProtocolDelegate>
{
    void(^cancelCompletionHandler)(NSError *error);
    void(^sendResultsCompletionHandler)(NSError *error);
    QredoClaimantAttestationProtocolAuthenticationCompletionHandler authenticationCompletionHandler;
}


@property (nonatomic) NSArray *claims;
@property (nonatomic) NSDictionary *claimsHashes;
@property (nonatomic) QredoClient *client;
@property (nonatomic) QredoClaimantAttestationProtocol *attestationProtocol;
@property (nonatomic) QredoAuthenticationProtocol *authenticationProtocol;

- (instancetype)initWithConversation:(QredoConversation *)conversation
                    attestationTypes:(NSSet *)attestationTypes
                       authenticator:(NSString *)authenticator;


@end