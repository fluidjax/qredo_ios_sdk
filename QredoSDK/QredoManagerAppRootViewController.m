/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoManagerAppRootViewController.h"
#import "QredoWelcomeViewController.h"
#import "UIColor+Qredo.h"

@implementation UIViewController(Qredo)
- (void)qredo_presentNavigationViewControllerWithViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewControllerToPresent];
    navigationController.view.backgroundColor = [UIColor qredoPrimaryBackgroundColor];
    navigationController.view.tintColor = [UIColor qredoPrimaryTintColor];
    [self presentViewController:navigationController animated:flag completion:completion];
}
@end



@interface QredoManagerAppRootViewController ()

@end

@implementation QredoManagerAppRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor qredoPrimaryBackgroundColor];
    
    UILabel *logoLabel = [[UILabel alloc] init];
    logoLabel.backgroundColor = [UIColor qredoPrimaryTintColor];
    logoLabel.text = @"Q";
    logoLabel.textAlignment = NSTextAlignmentCenter;
    logoLabel.font = [UIFont boldSystemFontOfSize:240];
    logoLabel.textColor = [UIColor qredoPrimaryBackgroundColor];
    
    logoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:logoLabel];
    
    
    id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(logoLabel, topLayoutGuide, bottomLayoutGuide);
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[logoLabel]|"
                               options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[topLayoutGuide][logoLabel][bottomLayoutGuide]"
                               options:0 metrics:nil views:views]];

}

- (void)show {
    [[UIApplication sharedApplication].keyWindow.rootViewController
     presentViewController:self animated:YES completion:^{
         QredoWelcomeViewController *welcomeViewController = [[QredoWelcomeViewController alloc] init];
         [self qredo_presentNavigationViewControllerWithViewController:welcomeViewController animated:YES completion:nil];
     }];

}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
