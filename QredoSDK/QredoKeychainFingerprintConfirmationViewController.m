/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainFingerprintConfirmationViewController.h"

@interface QredoKeychainFingerprintConfirmationViewController ()

@property (nonatomic) UILabel *fingerprintLabel;
@property (nonatomic) UILabel *deviceNameLabel;

@property (nonatomic, copy) NSString *fingerprint;
@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, copy) NSString *confirmButtonTitle;
@property (nonatomic, copy) void(^confirmButtonHandler)();

@end

@implementation QredoKeychainFingerprintConfirmationViewController

- (instancetype)init
{
    NSAssert(FALSE, @"Class %@ can not be initialized with init. Please use initWithFingerprint:confirmButtonTitle:confirmButtonHandler:", NSStringFromClass([self class]));
    return nil;
}

- (instancetype)initWithFingerprint:(NSString *)aFingerprint
                         deviceName:(NSString *)aDeviceName
                 confirmButtonTitle:(NSString *)aConfirmButtonTitle
               confirmButtonHandler:(void(^)())aConfirmButtonHandler {
    
    self = [super init];
    if (self) {
        self.fingerprint = aFingerprint;
        self.deviceName = aDeviceName;
        self.confirmButtonTitle = aConfirmButtonTitle;
        self.confirmButtonHandler = aConfirmButtonHandler;
    }
    
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *topSpacer = [[UIView alloc] init];
    topSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:topSpacer];
    
    UIView *containtsView = [[UIView alloc] init];
    
    UILabel *fingerPrintLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    fingerPrintLabel.text = self.fingerprint;
    fingerPrintLabel.textAlignment = NSTextAlignmentCenter;
    fingerPrintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [containtsView addSubview:fingerPrintLabel];
    self.fingerprintLabel = fingerPrintLabel;
    
    UILabel *deviceNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    deviceNameLabel.text = self.deviceName;
    deviceNameLabel.textAlignment = NSTextAlignmentCenter;
    deviceNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [containtsView addSubview:deviceNameLabel];
    self.fingerprintLabel = deviceNameLabel;
    
    containtsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:containtsView];
    
    UIView *bottomSpacer = [[UIView alloc] init];
    bottomSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bottomSpacer];
    
    UIButton *confirmationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmationButton addTarget:self action:@selector(confirmationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [confirmationButton setTitle:NSLocalizedString(@"OK", @"Button on the fingerprint confirmation view.") forState:UIControlStateNormal];
    confirmationButton.backgroundColor = [UIColor blueColor];
    confirmationButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:confirmationButton];
    
    
    id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;

    NSDictionary *views = NSDictionaryOfVariableBindings(topLayoutGuide, topSpacer, containtsView, fingerPrintLabel, deviceNameLabel, bottomSpacer, confirmationButton, bottomLayoutGuide);
    
    [containtsView addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|[fingerPrintLabel(>=100)]|"
                                   options:0 metrics:nil views:views]];
    [containtsView addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|[deviceNameLabel(>=100)]|"
                                   options:0 metrics:nil views:views]];
    [containtsView addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|[fingerPrintLabel(>=40)]-[deviceNameLabel(>=40)]|"
                                   options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-[topSpacer]-|"
                                   options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-[containtsView]-|"
                                   options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-[bottomSpacer]-|"
                                   options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|[confirmationButton]|"
                                   options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[topLayoutGuide]-[topSpacer][containtsView][bottomSpacer(==topSpacer)]-[confirmationButton(==40)][bottomLayoutGuide]"
                                   options:0 metrics:nil views:views]];
    
}

- (void)confirmationButtonPressed:(id)sender {
    if (self.confirmButtonHandler) {
        self.confirmButtonHandler();
    }
}

@end


