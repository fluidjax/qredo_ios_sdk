/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "QredoKeychainReceiverQR.h"
#import "QredoKeychainActivityViewController.h"
#import "QredoKeychainQRCodeDisplayViewController.h"
#import "QredoKeychainFingerprintConfirmationViewController.h"



@interface QredoKeychainReceiverQR ()

@property (nonatomic, copy) void(^willCreateRendezvousCancelHandler)();
@property (nonatomic, copy) void(^didReceiveKeychainConfirmationHandler)(BOOL confirmed);

@property (nonatomic, copy) NSString *keychainFingerprint;

@end

@implementation QredoKeychainReceiverQR

- (void)showCreatingRendezvousActivity {
    QredoKeychainActivityViewController *createRenezvousActivityController = [[QredoKeychainActivityViewController alloc] init];
    createRenezvousActivityController.activityTitle = NSLocalizedString(@"Creating rendezvous.", @"");
    createRenezvousActivityController.spinning = YES;
    [self displayChildViewController:createRenezvousActivityController];
}

- (void)showQRCodeForString:(NSString *)qrCodeString {
    QredoKeychainQRCodeDisplayViewController *qrCodeDisplayController = [[QredoKeychainQRCodeDisplayViewController alloc] init];
    qrCodeDisplayController.qrCodeValue = qrCodeString;
    [self displayChildViewController:qrCodeDisplayController];
}

- (void)showTransferingKeyChainActivity {
    QredoKeychainActivityViewController *transferingKeychainActivityController = [[QredoKeychainActivityViewController alloc] init];
    transferingKeychainActivityController.activityTitle = NSLocalizedString(@"Transfering keychain.", @"");
    transferingKeychainActivityController.spinning = YES;
    [self displayChildViewController:transferingKeychainActivityController];
}

- (void)showFingerprintViewControllerWithFingerprint:(NSString *)aFingerprint
                                confirmButtonHandler:(void(^)())aConfirmButtonHandler {
    
    NSString *title = NSLocalizedString(@"Install keychain", @"");
    NSString *fingerprintLineFormat = NSLocalizedString(@"fingerprint: %@", @"");
    NSString *fingerprintLine = [NSString stringWithFormat:fingerprintLineFormat, aFingerprint];
    
    QredoKeychainFingerprintConfirmationViewController *fingerprintViewController
    = [[QredoKeychainFingerprintConfirmationViewController alloc]
       initWithConfirmButtonTitle:NSLocalizedString(@"Install", @"")
       confirmButtonHandler:aConfirmButtonHandler];
    fingerprintViewController.activityTitle = title;
    fingerprintViewController.line1 = fingerprintLine;
    [self displayChildViewController:fingerprintViewController];
    
}

- (void)showInstallingKeyChainActivity {
    QredoKeychainActivityViewController *transferingKeychainActivityController = [[QredoKeychainActivityViewController alloc] init];
    transferingKeychainActivityController.activityTitle = NSLocalizedString(@"Installing keychain.", @"");
    transferingKeychainActivityController.spinning = YES;
    [self displayChildViewController:transferingKeychainActivityController];
}

- (void)showReceivingKeychainActivityViewControllerWithFingerpring:(NSString *)aFingerprint {
    NSString *activityName1 = NSLocalizedString(@"Receiving keychain", @"");
    NSString *activityName2FormattingString = NSLocalizedString(@"fingerprint: %@", @"");
    NSString *activityName2 = [NSString stringWithFormat:activityName2FormattingString, aFingerprint];
    QredoKeychainActivityViewController *activityViewController = [[QredoKeychainActivityViewController alloc] init];
    activityViewController.activityTitle = activityName1;
    activityViewController.line1 = activityName2;
    activityViewController.spinning = YES;
    [self displayChildViewController:activityViewController];
}

- (void)showSuccessConfirmationController {
    [self showDoneButton];
    NSString *title = NSLocalizedString(@"Done", @"");
    NSString *activityName = NSLocalizedString(@"The keychain has been received!", @"");
    QredoKeychainActivityViewController *activityViewController = [[QredoKeychainActivityViewController alloc] init];
    activityViewController.activityTitle = title;
    activityViewController.line1 = activityName;
    [self displayChildViewController:activityViewController];
}

- (void)showFailureConfirmationController {
    [self showDoneButton];
    NSString *activityName = NSLocalizedString(@"The keychain transfer has failed. Please try again later.", @"");
    QredoKeychainActivityViewController *activityViewController = [[QredoKeychainActivityViewController alloc] init];
    activityViewController.activityTitle = activityName;
    [self displayChildViewController:activityViewController];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.willCreateRendezvousCancelHandler) {
        self.willCreateRendezvousCancelHandler();
    }
    self.willCreateRendezvousCancelHandler = nil;
    if (self.didReceiveKeychainConfirmationHandler) {
        self.didReceiveKeychainConfirmationHandler(NO);
    }
    self.didReceiveKeychainConfirmationHandler = nil;
}


#pragma mark QredoKeychainReceiverDelegate

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver willCreateRendezvousWithCancelHandler:(void(^)())cancelHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.willCreateRendezvousCancelHandler = cancelHandler;
        [self presentInRootViewControllerAnimated:YES completion:nil];
        [self showCreatingRendezvousActivity];
    });
}

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didCreateRendezvousWithTag:(NSString*)tag {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.willCreateRendezvousCancelHandler = nil;
        [self showQRCodeForString:tag];
    });
}

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didEstablishConnectionWithFingerprint:(NSString*)fingerPrint {
    self.keychainFingerprint = fingerPrint;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showReceivingKeychainActivityViewControllerWithFingerpring:fingerPrint];
    });
}

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didReceiveKeychainWithConfirmationHandler:(void(^)(BOOL confirmed))confirmationHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.didReceiveKeychainConfirmationHandler = confirmationHandler;
        
        __weak QredoKeychainReceiverQR *weakSelf = self;
        [self showFingerprintViewControllerWithFingerprint:self.keychainFingerprint confirmButtonHandler:^{
            QredoKeychainReceiverQR *localSelf = weakSelf;
            if (localSelf.didReceiveKeychainConfirmationHandler) {
                [self showInstallingKeyChainActivity];
                localSelf.didReceiveKeychainConfirmationHandler(YES);
            }
            localSelf.didReceiveKeychainConfirmationHandler = nil;
        }];
    });
}

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showFailureConfirmationController];
    });
}

- (void)qredoKeychainReceiverDidInstallKeychain:(QredoKeychainReceiver *)receiver {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showSuccessConfirmationController];
    });
}

@end
