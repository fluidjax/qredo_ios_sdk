/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainActivityViewController.h"

@interface QredoKeychainActivityViewController ()
@property (weak, nonatomic) UILabel *activityNameLabel;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation QredoKeychainActivityViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *containtsView = [[UIView alloc] init];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = self.activityName;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [containtsView addSubview:label];
    self.activityNameLabel = label;
    
    UIActivityIndicatorView *activityIndicatorView
    = [[UIActivityIndicatorView alloc]
       initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    if (_spinning) {
        [activityIndicatorView startAnimating];
        activityIndicatorView.hidden = NO;
    } else {
        [activityIndicatorView stopAnimating];
        activityIndicatorView.hidden = YES;
    }
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [containtsView addSubview:activityIndicatorView];
    self.activityIndicatorView = activityIndicatorView;
    
    containtsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:containtsView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(label, activityIndicatorView);
    
    [containtsView addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"H:|-(10)-[label]-(10)-|"
                              options:0 metrics:nil views:views]];
    [containtsView addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"V:|[label]-[activityIndicatorView]|"
                              options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:containtsView attribute:NSLayoutAttributeCenterX
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.view attribute:NSLayoutAttributeCenterX
                              multiplier:1 constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:containtsView attribute:NSLayoutAttributeCenterY
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.view attribute:NSLayoutAttributeCenterY
                              multiplier:1 constant:0]];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.activityNameLabel.preferredMaxLayoutWidth = self.view.bounds.size.width-20;
}

- (void)setActivityName:(NSString *)activityName {
    if (_activityName == activityName) return;
    _activityName = [activityName copy];
    if ([self isViewLoaded]) {
        self.activityNameLabel.text = _activityName;
    }
}

- (void)setSpinning:(BOOL)spinning {
    if (_spinning == spinning) return;
    _spinning = spinning;
    if (_spinning) {
        [self.activityIndicatorView startAnimating];
    } else {
        [self.activityIndicatorView stopAnimating];
    }
}

@end


