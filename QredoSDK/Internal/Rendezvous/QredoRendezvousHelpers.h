/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoRendezvousHelper.h"

@interface QredoRendezvousHelpers : NSObject
+ (id<QredoRendezvousHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType tag:(NSString *)tag;
@end
