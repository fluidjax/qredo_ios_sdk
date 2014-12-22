/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>

@interface UIViewController(Qredo)
- (void)qredo_presentNavigationViewControllerWithViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;
@end

@interface QredoManagerAppRootViewController : UIViewController

- (void)show;
- (void)close;

- (void)presentDefaultViewController;

@end
