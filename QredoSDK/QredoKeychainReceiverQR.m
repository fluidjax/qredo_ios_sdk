/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "QredoKeychainReceiverQR.h"
#import "QredoKeychainActivityViewController.h"
#import "QredoKeychainQRCodeDisplayViewController.h"
#import "QredoKeychainFingerprintConfirmationViewController.h"
#import "QredoKeychainConfirmationViewController.h"



@interface QredoKeychainReceiverQR ()

@property (nonatomic, copy) void(^willCreateRendezvousCancelHandler)();
@property (nonatomic, copy) void(^didReceiveKeychainConfirmationHandler)(BOOL confirmed);

@end

@implementation QredoKeychainReceiverQR

- (void)showCreatingRendezvousActivity {
    QredoKeychainActivityViewController *createRenezvousActivityController = [[QredoKeychainActivityViewController alloc] init];
    createRenezvousActivityController.activityName = NSLocalizedString(@"Creating rendezvous.", @"");
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
    transferingKeychainActivityController.activityName = NSLocalizedString(@"Transfering keychain.", @"");
    transferingKeychainActivityController.spinning = YES;
    [self displayChildViewController:transferingKeychainActivityController];
}

- (void)showFingerprintViewControllerWithFingerprint:(NSString *)aFingerprint
                                confirmButtonHandler:(void(^)())aConfirmButtonHandler {
    
    QredoKeychainFingerprintConfirmationViewController *fingerprintViewController
    = [[QredoKeychainFingerprintConfirmationViewController alloc]
       initWithFingerprint:aFingerprint
       deviceName:nil
       confirmButtonTitle:NSLocalizedString(@"Install keychain", @"")
       confirmButtonHandler:aConfirmButtonHandler];
    
    [self displayChildViewController:fingerprintViewController];
    
}

- (void)showInstallingKeyChainActivity {
    QredoKeychainActivityViewController *transferingKeychainActivityController = [[QredoKeychainActivityViewController alloc] init];
    transferingKeychainActivityController.activityName = NSLocalizedString(@"Installing keychain.", @"");
    transferingKeychainActivityController.spinning = YES;
    [self displayChildViewController:transferingKeychainActivityController];
}

- (void)showReceivingKeychainActivityViewControllerWithFingerpring:(NSString *)aFingerprint {
    NSString *activityNameFormattingString = NSLocalizedString(@"Sending keychain with fingerprint: %@", @"");
    NSString *activityName = [NSString stringWithFormat:activityNameFormattingString, aFingerprint];
    QredoKeychainActivityViewController *activityViewController = [[QredoKeychainActivityViewController alloc] init];
    activityViewController.activityName = activityName;
    activityViewController.spinning = YES;
    [self displayChildViewController:activityViewController];
}

- (void)showSuccessConfirmationController {
    [self showDoneButton];
    NSString *activityName = NSLocalizedString(@"The keychain has been received.", @"");
    QredoKeychainConfirmationViewController *confirmationViewController
    = [[QredoKeychainConfirmationViewController alloc] initWithActivityName:activityName];
    [self displayChildViewController:confirmationViewController];
}

- (void)showFailureConfirmationController {
    [self showDoneButton];
    NSString *activityName = NSLocalizedString(@"The keychain transfer has failed. Please try again later.", @"");
    QredoKeychainConfirmationViewController *confirmationViewController
    = [[QredoKeychainConfirmationViewController alloc] initWithActivityName:activityName];
    [self displayChildViewController:confirmationViewController];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showReceivingKeychainActivityViewControllerWithFingerpring:fingerPrint];
    });
}

- (void)qredoKeychainReceiver:(QredoKeychainReceiver *)receiver didReceiveKeychainWithConfirmationHandler:(void(^)(BOOL confirmed))confirmationHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.didReceiveKeychainConfirmationHandler = confirmationHandler;
        
        __weak QredoKeychainReceiverQR *weakSelf = self;
        [self showFingerprintViewControllerWithFingerprint:@"" confirmButtonHandler:^{
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
