/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainFingerprintConfirmationViewController.h"

@interface QredoKeychainFingerprintConfirmationViewController ()

@property (nonatomic, copy) NSString *confirmButtonTitle;
@property (nonatomic, copy) void(^confirmButtonHandler)();

@end

@implementation QredoKeychainFingerprintConfirmationViewController

- (instancetype)init
{
    NSAssert(FALSE, @"Class %@ can not be initialized with init. Please use initWithFingerprint:confirmButtonTitle:confirmButtonHandler:", NSStringFromClass([self class]));
    return nil;
}

- (instancetype)initWithConfirmButtonTitle:(NSString *)aConfirmButtonTitle
                      confirmButtonHandler:(void(^)())aConfirmButtonHandler {
    
    self = [super init];
    if (self) {
        self.confirmButtonTitle = aConfirmButtonTitle;
        self.confirmButtonHandler = aConfirmButtonHandler;
    }
    
    return self;
    
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *confirmationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmationButton addTarget:self action:@selector(confirmationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [confirmationButton setTitle:self.confirmButtonTitle forState:UIControlStateNormal];
    confirmationButton.backgroundColor = [UIColor blueColor];
    confirmationButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:confirmationButton];

    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(confirmationButton, bottomLayoutGuide);

    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[confirmationButton]|"
                               options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[confirmationButton(==40)][bottomLayoutGuide]"
                               options:0 metrics:nil views:views]];
    
}

- (void)confirmationButtonPressed:(id)sender {
    if (self.confirmButtonHandler) {
        self.confirmButtonHandler();
    }
}

@end


