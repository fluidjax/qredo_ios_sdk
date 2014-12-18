/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>



@interface QredoKeychainSendReceiveViewController : UIViewController
- (void)presentInRootViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)displayChildViewController:(UIViewController *)aChildController;
- (void)showCancelButton;
- (void)showDoneButton;
@end
