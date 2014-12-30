/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoKeychainReceiver.h"
#import "QredoKeychainSendReceiveViewController.h"

@interface QredoKeychainReceiverQR : QredoKeychainSendReceiveViewController <QredoKeychainReceiverDelegate>
@property (nonatomic, copy) void(^completionHandler)(NSError *error);
@property (nonatomic) QredoKeychainReceiver *keychianReceiver;
@end
