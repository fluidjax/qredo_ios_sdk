/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainActivityViewController.h"

@interface QredoKeychainActivityViewController ()
@property (weak, nonatomic) UILabel *activityTitleLabel;
@property (weak, nonatomic) UILabel *line1Label;
@property (weak, nonatomic) UILabel *line2Label;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation QredoKeychainActivityViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;

    UIView *labelContainerView = [[UIView alloc] init];
    labelContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:labelContainerView];

    UIView *activityIndicatorContainerView = [[UIView alloc] init];
    activityIndicatorContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:activityIndicatorContainerView];

    NSDictionary *conatainerViews = NSDictionaryOfVariableBindings(topLayoutGuide, labelContainerView, activityIndicatorContainerView, bottomLayoutGuide);
    
    [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-[labelContainerView]-|"
                                   options:0 metrics:nil views:conatainerViews]];
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-[activityIndicatorContainerView]-|"
                               options:0 metrics:nil views:conatainerViews]];

    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[topLayoutGuide]-[labelContainerView]-[activityIndicatorContainerView(==labelContainerView)]-[bottomLayoutGuide]|"
                               options:0 metrics:nil views:conatainerViews]];
    
    
    
    UIView *labelsTopSpacer = [[UIView alloc] init];
    labelsTopSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    [labelContainerView addSubview:labelsTopSpacer];
    
    UILabel *activityTitleLabel = [[UILabel alloc] init];
    activityTitleLabel.font = [UIFont systemFontOfSize:25];
    activityTitleLabel.numberOfLines = 0;
    activityTitleLabel.textAlignment = NSTextAlignmentCenter;
    activityTitleLabel.text = self.activityTitle;
    activityTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [labelContainerView addSubview:activityTitleLabel];
    self.activityTitleLabel = activityTitleLabel;
    
    UILabel *line1Label = [[UILabel alloc] init];
    line1Label.numberOfLines = 0;
    line1Label.textAlignment = NSTextAlignmentCenter;
    line1Label.text = self.line1;
    line1Label.translatesAutoresizingMaskIntoConstraints = NO;
    [labelContainerView addSubview:line1Label];
    self.line1Label = line1Label;
    
    UILabel *line2Label = [[UILabel alloc] init];
    line2Label.numberOfLines = 0;
    line2Label.textAlignment = NSTextAlignmentCenter;
    line2Label.text = self.line2;
    line2Label.translatesAutoresizingMaskIntoConstraints = NO;
    [labelContainerView addSubview:line2Label];
    self.line2Label = line2Label;
    
    UIView *labelsBottomSpacer = [[UIView alloc] init];
    labelsBottomSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    [labelContainerView addSubview:labelsBottomSpacer];
    
    NSDictionary *labels = NSDictionaryOfVariableBindings(labelsTopSpacer, activityTitleLabel, line1Label, line2Label, labelsBottomSpacer);
    
    [labelContainerView addConstraints:[NSLayoutConstraint
                                        constraintsWithVisualFormat:@"H:|-[labelsTopSpacer]-|"
                                        options:0 metrics:nil views:labels]];
    [labelContainerView addConstraints:[NSLayoutConstraint
                                        constraintsWithVisualFormat:@"H:|-[activityTitleLabel]-|"
                                        options:0 metrics:nil views:labels]];
    [labelContainerView addConstraints:[NSLayoutConstraint
                                        constraintsWithVisualFormat:@"H:|-[line1Label]-|"
                                        options:0 metrics:nil views:labels]];
    [labelContainerView addConstraints:[NSLayoutConstraint
                                        constraintsWithVisualFormat:@"H:|-[line2Label]-|"
                                        options:0 metrics:nil views:labels]];
    [labelContainerView addConstraints:[NSLayoutConstraint
                                        constraintsWithVisualFormat:@"H:|-[labelsBottomSpacer]-|"
                                        options:0 metrics:nil views:labels]];
    [labelContainerView addConstraints:[NSLayoutConstraint
                                        constraintsWithVisualFormat:@"V:|[labelsTopSpacer][activityTitleLabel]-[line1Label][line2Label][labelsBottomSpacer(==labelsTopSpacer)]|"
                                        options:0 metrics:nil views:labels]];

    
    
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
    [activityIndicatorContainerView addSubview:activityIndicatorView];
    self.activityIndicatorView = activityIndicatorView;

    
    [activityIndicatorContainerView addConstraint:[NSLayoutConstraint
                              constraintWithItem:activityIndicatorContainerView attribute:NSLayoutAttributeCenterX
                              relatedBy:NSLayoutRelationEqual
                              toItem:activityIndicatorView attribute:NSLayoutAttributeCenterX
                              multiplier:1 constant:0]];
    
    [activityIndicatorContainerView addConstraint:[NSLayoutConstraint
                              constraintWithItem:activityIndicatorContainerView attribute:NSLayoutAttributeCenterY
                              relatedBy:NSLayoutRelationEqual
                              toItem:activityIndicatorView attribute:NSLayoutAttributeCenterY
                              multiplier:1 constant:0]];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat preferedWidth = self.view.bounds.size.width-20;
    self.activityTitleLabel.preferredMaxLayoutWidth = preferedWidth;
    self.line1Label.preferredMaxLayoutWidth = preferedWidth;
    self.line2Label.preferredMaxLayoutWidth = preferedWidth;
}

- (void)setActivityTitle:(NSString *)activityName1 {
    if (_activityTitle == activityName1) return;
    _activityTitle = [activityName1 copy];
    if ([self isViewLoaded]) {
        self.activityTitleLabel.text = _activityTitle;
    }
}

- (void)setLine1:(NSString *)line1 {
    if (_line1 == line1) return;
    _line1 = [line1 copy];
    if ([self isViewLoaded]) {
        self.line1Label.text = _line1;
    }
}

- (void)setLine2:(NSString *)line2 {
    if (_line2 == line2) return;
    _line2 = [line2 copy];
    if ([self isViewLoaded]) {
        self.line2Label.text = _line2;
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


