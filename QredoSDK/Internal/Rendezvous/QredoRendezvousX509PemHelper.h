/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"

@interface QredoAbstractRendezvousX509PemHelper : QredoAbstractRendezvousHelper
@end

@interface QredoRendezvousX509PemCreateHelper : QredoAbstractRendezvousX509PemHelper<QredoRendezvousCreatePrivateHelper>
@end

@interface QredoRendezvousX509PemRespondHelper : QredoAbstractRendezvousX509PemHelper<QredoRendezvousRespondPrivateHelper>
@end