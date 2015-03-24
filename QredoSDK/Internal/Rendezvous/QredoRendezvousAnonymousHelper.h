/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"

@interface QredoAbstractRendezvousAnonymousHelper : QredoAbstractRendezvousHelper
@end

@interface QredoRendezvousAnonymousCreateHelper : QredoAbstractRendezvousAnonymousHelper<QredoRendezvousCreatePrivateHelper>
@end

@interface QredoRendezvousAnonymousRespondHelper : QredoAbstractRendezvousAnonymousHelper<QredoRendezvousRespondPrivateHelper>
@end