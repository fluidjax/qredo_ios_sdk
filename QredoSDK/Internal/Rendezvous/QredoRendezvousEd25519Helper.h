/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"


@interface QredoAbstractRendezvousEd25519Helper : QredoAbstractRendezvousHelper
@end

@interface QredoRendezvousEd25519CreateHelper : QredoAbstractRendezvousEd25519Helper<QredoRendezvousCreatePrivateHelper>
@end

@interface QredoRendezvousEd25519RespondHelper : QredoAbstractRendezvousEd25519Helper<QredoRendezvousRespondPrivateHelper>
@end



