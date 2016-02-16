/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"

// Length of salt used for signing X509 authenticated rendezvous
extern const NSInteger kX509AuthenticatedRendezvousSaltLength;

@interface QredoAbstractRendezvousX509PemHelper : QredoAbstractRendezvousHelper

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto
               trustedRootPems:(NSArray *)trustedRootPems
                       crlPems:(NSArray *)crlPems
                         error:(NSError **)error;

@end

@interface QredoRendezvousX509PemCreateHelper : QredoAbstractRendezvousX509PemHelper<QredoRendezvousCreatePrivateHelper>
@end

@interface QredoRendezvousX509PemRespondHelper : QredoAbstractRendezvousX509PemHelper<QredoRendezvousRespondPrivateHelper>
@end