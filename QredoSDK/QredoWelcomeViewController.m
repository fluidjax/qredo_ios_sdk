/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoWelcomeViewController.h"
#import "QredoMainViewController.h"
#import "QredoManagerAppRootViewController.h"
#import "UIColor+Qredo.h"
#import "UIButton+Qredo.h"

@interface QredoWelcomeViewController ()
@end

@implementation QredoWelcomeViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor qredoPrimaryBackgroundColor];
    self.view.tintColor = [UIColor qredoPrimaryTintColor];

    UILabel *logoLabel = [[UILabel alloc] init];
    logoLabel.text = @"Q";
    logoLabel.textAlignment = NSTextAlignmentCenter;
    logoLabel.font = [UIFont boldSystemFontOfSize:240];
    logoLabel.textColor = self.view.tintColor;
    logoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:logoLabel];
    
    UIView *buttonContainerView = [[UIView alloc] init];
    buttonContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonContainerView];
    
    UIButton *newUserButton = [UIButton qredoButton];
    NSString *newUserButtonTitle = NSLocalizedString(@"I am a new user", @"");
    [newUserButton setTitle:newUserButtonTitle forState:UIControlStateNormal];
    [newUserButton addTarget:self action:@selector(newUserButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    newUserButton.titleLabel.numberOfLines = 0;
    newUserButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    newUserButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonContainerView addSubview:newUserButton];
    
    UIButton *importKeychainButton = [UIButton qredoButton];
    NSString *importKeychainButtonTitle = NSLocalizedString(@"Install my keychain from another device", @"");
    [importKeychainButton setTitle:importKeychainButtonTitle forState:UIControlStateNormal];
    [importKeychainButton addTarget:self action:@selector(importKeychainButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    importKeychainButton.titleLabel.numberOfLines = 0;
    importKeychainButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    importKeychainButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonContainerView addSubview:importKeychainButton];
    
    id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(logoLabel, buttonContainerView, newUserButton, importKeychainButton, topLayoutGuide, bottomLayoutGuide);
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-[logoLabel]-|"
                               options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-[buttonContainerView]-|"
                               options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[topLayoutGuide]-[logoLabel]-[buttonContainerView]-[bottomLayoutGuide]"
                               options:0 metrics:nil views:views]];
    
    [buttonContainerView addConstraints:[NSLayoutConstraint
                                         constraintsWithVisualFormat:@"H:|[newUserButton]|"
                                         options:0 metrics:nil views:views]];
    [buttonContainerView addConstraints:[NSLayoutConstraint
                                         constraintsWithVisualFormat:@"H:|[importKeychainButton]|"
                                         options:0 metrics:nil views:views]];
    [buttonContainerView addConstraints:[NSLayoutConstraint
                                         constraintsWithVisualFormat:@"V:|-[newUserButton(==88)]-[importKeychainButton(==88)]|"
                                         options:0 metrics:nil views:views]];
    

}

- (void)newUserButtonPressed {
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        QredoMainViewController *mainViewController = [[QredoMainViewController alloc] init];
        [presentingViewController qredo_presentNavigationViewControllerWithViewController:mainViewController animated:YES completion:nil];
    }];
}

- (void)importKeychainButtonPressed {
    //UIViewController *presentingViewController = self.presentedViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
