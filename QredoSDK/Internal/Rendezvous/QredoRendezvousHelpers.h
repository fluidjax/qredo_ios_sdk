/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoRendezvousHelper.h"

@protocol CryptoImpl;

@interface QredoRendezvousHelpers : NSObject
+ (id<QredoRendezvousHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType tag:(NSString *)tag crypto:(id<CryptoImpl>)crypto;
@end
