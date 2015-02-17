/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoRendezvousRsaPemCommonHelper.h"

//@interface QredoRendezvousRsa4096PemHelper : QredoRendezvousRsaPemCommonHelper
//
//@end
//
@interface QredoRendezvousRsa4096PemCreateHelper : QredoRendezvousRsaPemCreateHelper<QredoRendezvousCreatePrivateHelper>
@end

@interface QredoRendezvousRsa4096PemRespondHelper : QredoRendezvousRsaPemRespondHelper<QredoRendezvousRespondPrivateHelper>
@end