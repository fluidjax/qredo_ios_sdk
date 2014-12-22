/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoKeychainSender.h"
#import "QredoKeychainSendReceiveViewController.h"

@interface QredoKeychainSenderQR : QredoKeychainSendReceiveViewController <QredoKeychainSenderDelegate>
@property (nonatomic, copy) void(^completionHandler)(NSError *error);
@property (nonatomic) QredoKeychainSender *keychainSender;
@end
