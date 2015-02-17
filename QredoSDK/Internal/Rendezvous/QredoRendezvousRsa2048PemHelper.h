/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoRendezvousHelper_Private.h"

// Length of salt used for signing RSA authenticated rendezvous
extern const NSInteger kRsa2048AuthenticatedRendezvousSaltLength;

@interface QredoAbstractRendezvousRsa2048PemHelper : QredoAbstractRendezvousHelper
@end

@interface QredoRendezvousRsa2048PemCreateHelper : QredoAbstractRendezvousRsa2048PemHelper<QredoRendezvousCreatePrivateHelper>
@end

@interface QredoRendezvousRsa2048PemRespondHelper : QredoAbstractRendezvousRsa2048PemHelper<QredoRendezvousRespondPrivateHelper>
@end