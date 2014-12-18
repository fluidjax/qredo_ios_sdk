/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "QredoKeychainActivityViewController.h"

@interface QredoKeychainFingerprintConfirmationViewController : QredoKeychainActivityViewController

- (instancetype)initWithConfirmButtonTitle:(NSString *)aConfirmButtonTitle
                      confirmButtonHandler:(void(^)())aConfirmButtonHandler;

@end
