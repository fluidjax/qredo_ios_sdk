/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoMainViewController.h"
#import "QredoSettingsViewController.h"
#import "QredoManagerAppRootViewController.h"
#import "UIColor+Qredo.h"

@interface QredoMainViewController ()

@end

@implementation QredoMainViewController


- (instancetype)init {
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Qredo", @"");
    
    self.view.backgroundColor = [UIColor qredoPrimaryBackgroundColor];
    self.view.tintColor = [UIColor qredoPrimaryTintColor];
    
    UIBarButtonItem *doneButton
    = [[UIBarButtonItem alloc]
       initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone
       target:self action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    
    UIBarButtonItem *addDeviceButton
    = [[UIBarButtonItem alloc]
       initWithTitle:NSLocalizedString(@"Add device", @"") style:UIBarButtonItemStylePlain
       target:self action:@selector(addDeviceButtonPressed)];
    
    UIBarButtonItem *flexibleSpace
    = [[UIBarButtonItem alloc]
       initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
       target:nil action:nil];
    
    UIBarButtonItem *settingsButton
    = [[UIBarButtonItem alloc]
       initWithTitle:NSLocalizedString(@"Settings", @"") style:UIBarButtonItemStylePlain
       target:self action:@selector(settingsButtonPressed)];
    
    self.toolbarItems = @[addDeviceButton, flexibleSpace, settingsButton];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
}

- (void)doneButtonPressed {
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        if ([presentingViewController respondsToSelector:@selector(close)]) {
            [presentingViewController performSelector:@selector(close)];
        }
    }];
}

- (void)addDeviceButtonPressed {
    
}

- (void)settingsButtonPressed {
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        QredoSettingsViewController *qredoSettingsViewController = [[QredoSettingsViewController alloc] init];
        [presentingViewController qredo_presentNavigationViewControllerWithViewController:qredoSettingsViewController animated:YES completion:nil];
    }];
}

@end
