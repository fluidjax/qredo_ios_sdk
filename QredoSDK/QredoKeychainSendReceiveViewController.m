/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainSendReceiveViewController.h"

typedef NS_ENUM(NSUInteger, QredoKeychainSendReceiveViewControllerAnimationType) {
    QredoKeychainSendReceiveViewControllerAnimationTypeNone = 0,
    QredoKeychainSendReceiveViewControllerAnimationTypeBlend
};



@interface QredoKeychainSendReceiveViewController ()
@property (nonatomic) UIViewController *childViewControler;
@property (nonatomic) NSArray *childViewConstraints;
@end

@implementation QredoKeychainSendReceiveViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self showCancelButton];
}

- (void)showCancelButton {
    self.navigationItem.leftBarButtonItem
    = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                    target:self
                                                    action:@selector(cancelOrDoneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)showDoneButton {
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem
    = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                    target:self
                                                    action:@selector(cancelOrDoneButtonPressed:)];
}

- (void)presentInRootViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UINavigationController *navigationViewController = [[UINavigationController alloc] initWithRootViewController:self];
    [keyWindow.rootViewController presentViewController:navigationViewController animated:animated completion:completion];
}

- (void)displayChildViewController:(UIViewController *)aChildController {
    [self displayChildViewController:aChildController
                   withAnimationType:QredoKeychainSendReceiveViewControllerAnimationTypeBlend];
}

- (void)displayChildViewController:(UIViewController *)aChildController
             withAnimationType:(QredoKeychainSendReceiveViewControllerAnimationType)animationType {
    
    switch (animationType) {
        case QredoKeychainSendReceiveViewControllerAnimationTypeBlend:
            [self withBlendBlendDisplayChildController:aChildController];
            break;
            
        case QredoKeychainSendReceiveViewControllerAnimationTypeNone:
            [self withAnimationNoneDisplayChildController:aChildController];
            break;
    }
    
}

- (void)withAnimationNoneDisplayChildController:(UIViewController *)newChildViewController {
    
    UIViewController *oldChildViewController = self.childViewControler;
    NSArray *oldConstraints = self.childViewConstraints;
    NSMutableArray *newConstraints = [NSMutableArray array];
    
    newChildViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [oldChildViewController willMoveToParentViewController:nil];
    
    if (newChildViewController) {
        
        [self addChildViewController:newChildViewController];
        [self.view addSubview:newChildViewController.view];
        
        NSDictionary *constrainedViews = @{@"childView": newChildViewController.view};
        [newConstraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[childView]|" options:0 metrics:nil views:constrainedViews]];
        [newConstraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[childView]|" options:0 metrics:nil views:constrainedViews]];
        
        [self.view addConstraints:newConstraints];
        
        [newChildViewController didMoveToParentViewController:self];
        
    }
    
    if (oldConstraints) {
        [self.view removeConstraints:oldConstraints];
    }
    
    [oldChildViewController.view removeFromSuperview];
    [oldChildViewController removeFromParentViewController];
    
    
    self.childViewControler = newChildViewController;
    self.childViewConstraints = newConstraints;
    
}

- (void)withBlendBlendDisplayChildController:(UIViewController *)newChildViewController {
    
    UIViewController *oldChildViewController = self.childViewControler;
    NSMutableArray *newConstraints = [NSMutableArray array];
    NSArray *oldConstraints = self.childViewConstraints;
    
    newChildViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [oldChildViewController willMoveToParentViewController:nil];
    
    if (newChildViewController) {
        
        newChildViewController.view.alpha = 0;
        
        [self addChildViewController:newChildViewController];
        [self.view addSubview:newChildViewController.view];
        
        NSDictionary *constrainedViews = @{@"childView": newChildViewController.view};
        [newConstraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[childView]|" options:0 metrics:nil views:constrainedViews]];
        [newConstraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[childView]|" options:0 metrics:nil views:constrainedViews]];
        
        [self.view addConstraints:newConstraints];
        
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        
        newChildViewController.view.alpha = 1;
        oldChildViewController.view.alpha = 0;
        
    } completion:^(BOOL finished) {
        
        if (oldConstraints) {
            [self.view removeConstraints:oldConstraints];
        }
        
        [oldChildViewController.view removeFromSuperview];
        [oldChildViewController removeFromParentViewController];

        [newChildViewController didMoveToParentViewController:self];
        
        self.childViewControler = newChildViewController;
        self.childViewConstraints = newConstraints;
        
    }];
    
}

- (void)cancelOrDoneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end


