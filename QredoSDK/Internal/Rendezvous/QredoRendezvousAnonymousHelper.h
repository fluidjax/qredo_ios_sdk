/* HEADER GOES HERE */
#import "QredoRendezvousHelper_Private.h"

@interface QredoAbstractRendezvousAnonymousHelper :QredoAbstractRendezvousHelper
@end

@interface QredoRendezvousAnonymousCreateHelper :QredoAbstractRendezvousAnonymousHelper<QredoRendezvousCreatePrivateHelper>
@end

@interface QredoRendezvousAnonymousRespondHelper :QredoAbstractRendezvousAnonymousHelper<QredoRendezvousRespondPrivateHelper>
@end
