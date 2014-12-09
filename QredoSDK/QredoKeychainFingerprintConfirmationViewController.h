/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>

@interface QredoKeychainFingerprintConfirmationViewController : UIViewController
- (instancetype)initWithFingerprint:(NSString *)aFingerprint
                         deviceName:(NSString *)aDeviceName
                 confirmButtonTitle:(NSString *)aConfirmButtonTitle
               confirmButtonHandler:(void(^)())aConfirmButtonHandler;
@end
