/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainConfirmationViewController.h"

@interface QredoKeychainConfirmationViewController ()
@property (nonatomic, copy) NSString *activityName;
@property (nonatomic) UILabel *activityNameLabel;
@end

@implementation QredoKeychainConfirmationViewController

- (instancetype)initWithActivityName:(NSString *)anActivityName
{
    self = [super init];
    if (self) {
        self.activityName = anActivityName;
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *activityNameLabel = [[UILabel alloc] init];
    activityNameLabel.textAlignment = NSTextAlignmentCenter;
    activityNameLabel.numberOfLines = 0;
    activityNameLabel.text = self.activityName;
    activityNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:activityNameLabel];
    self.activityNameLabel = activityNameLabel;
    
    id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;

    NSDictionary *views = NSDictionaryOfVariableBindings(topLayoutGuide, activityNameLabel, bottomLayoutGuide);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[activityNameLabel]-(10)-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][activityNameLabel][bottomLayoutGuide]" options:0 metrics:nil views:views]];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.activityNameLabel.preferredMaxLayoutWidth = self.view.bounds.size.width-20;
}


@end
