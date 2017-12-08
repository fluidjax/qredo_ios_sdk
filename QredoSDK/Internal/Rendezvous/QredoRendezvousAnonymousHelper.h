/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoRendezvousHelper_Private.h"

@interface QredoAbstractRendezvousAnonymousHelper :QredoAbstractRendezvousHelper
@end

@interface QredoRendezvousAnonymousCreateHelper :QredoAbstractRendezvousAnonymousHelper<QredoRendezvousCreatePrivateHelper>
@end

@interface QredoRendezvousAnonymousRespondHelper :QredoAbstractRendezvousAnonymousHelper<QredoRendezvousRespondPrivateHelper>
@end
