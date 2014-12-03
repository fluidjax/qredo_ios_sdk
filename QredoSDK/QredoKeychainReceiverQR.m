/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "QredoKeychainReceiverQR.h"

@interface QredoKeychainReceiverQR ()
{
    UINavigationController *navigationViewController;
    UIViewController *rootViewController;
}

@end

@implementation QredoKeychainReceiverQR

- (void)qredoKeychainReceiverWillCreateRendezvous:(QredoKeychainReceiver *)receiver
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;

    CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];

    rootViewController = [[UIViewController alloc] init];
    navigationViewController = [[UINavigationController alloc] initWithRootViewController:rootViewController];

    rootViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];

    UIView *rootView = [[UIView alloc] initWithFrame:applicationFrame];
    rootView.backgroundColor = [UIColor whiteColor];

    rootViewController.view = rootView;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = @"Receiving KeyChain";
    [rootView addSubview:label];

    label.translatesAutoresizingMaskIntoConstraints = NO;

    id<UILayoutSupport> topLayoutGuide = rootViewController.topLayoutGuide;
    id<UILayoutSupport> bottomLayoutGuide = rootViewController.bottomLayoutGuide;

    NSDictionary *views = NSDictionaryOfVariableBindings(rootView, label, topLayoutGuide, bottomLayoutGuide);

    [rootView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[label(>=100)]-|" options:0 metrics:nil views:views]];
    [rootView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-[label(>=40)]" options:0 metrics:nil views:views]];

    [label layoutIfNeeded];

    [keyWindow.rootViewController presentViewController:navigationViewController animated:YES completion:nil];
}

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didCreateRendezvousWithTag:(NSString*)tag cancelHandler:(void(^)())cancelHandler
{

}

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didEstablishConnectionWithFingerprint:(NSString*)fingerPrint
{

}

- (void)qredoKeychainReceiverDidReceiveKeychain:(QredoKeychainReceiver *)receiver
{

}

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didFailWithError:(NSError *)error
{

}

- (void)cancel {
    NSLog(@"cancel receiving");
}

@end
