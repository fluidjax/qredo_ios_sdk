/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainSenderQR.h"
#import "QredoKeychainQRCodeScannerViewController.h"
#import "QredoKeychainFingerprintConfirmationViewController.h"
#import "QredoKeychainActivityViewController.h"
#import "Qredo.h"

@interface QredoKeychainSenderQR ()
@property (nonatomic, copy) BOOL(^discoverRendezvousCompletionHandler)(NSString *rendezvousTag);
@property (nonatomic, copy) void(^discoverRendezvousCancelHandler)();
@property (nonatomic, copy) void(^sendConfirmationHandler)(BOOL confirmed);
@end

@implementation QredoKeychainSenderQR

- (void)showQRCodeSacannerWithScanningHandler:(void(^)(NSString *scannedResult, NSError *error))aScanningHandler {
    QredoKeychainQRCodeScannerViewController *qrCodeScannerViewController
    = [[QredoKeychainQRCodeScannerViewController alloc]
       initWithScanningHandler:aScanningHandler];
    [self displayChildViewController:qrCodeScannerViewController];
}

- (void)showFingerprintConfirmationViewControllerWithFngerprint:(NSString *)aFingerprint
                                         deviceName:(NSString *)aDeviceName
                               confirmButtonHandler:(void(^)())aConfirmButtonHandler {
    

    NSString *title = NSLocalizedString(@"Send keychain", @"");
    NSString *instructions = NSLocalizedString(@"make sure that the receiving device displays", @"");
    NSString *fingerprintFormat = NSLocalizedString(@"fingerprint: %@", @"");
    NSString *fingerprint = [NSString stringWithFormat:fingerprintFormat, aFingerprint];

    QredoKeychainFingerprintConfirmationViewController *fingerprintViewController
    = [[QredoKeychainFingerprintConfirmationViewController alloc]
       initWithConfirmButtonTitle:NSLocalizedString(@"Send", @"")
       confirmButtonHandler:aConfirmButtonHandler];
    
    fingerprintViewController.activityTitle = title;
    fingerprintViewController.line1 = instructions;
    fingerprintViewController.line2 = fingerprint;
    
    [self displayChildViewController:fingerprintViewController];
    
}

- (void)showSendingKeychainActivityViewControllerWithFingerpring:(NSString *)aFingerprint {
    NSString *title = NSLocalizedString(@"Sending keychain", @"");
    NSString *fingerprintLineFormattingString = NSLocalizedString(@"fingerprint: %@", @"");
    NSString *fingerprintLine = [NSString stringWithFormat:fingerprintLineFormattingString, aFingerprint];
    QredoKeychainActivityViewController *activityViewController = [[QredoKeychainActivityViewController alloc] init];
    activityViewController.activityTitle = title;
    activityViewController.line1 = fingerprintLine;
    activityViewController.spinning = YES;
    [self displayChildViewController:activityViewController];
}

- (void)showSuccessConfirmationController {
    [self showDoneButton];
    NSString *title = NSLocalizedString(@"Done", @"");
    NSString *activityName = NSLocalizedString(@"The keychain has been sent!", @"");
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


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [QredoClient authorizeWithConversationTypes:@[] vaultDataTypes:@[] completionHandler:^(QredoClient *client, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                self.keychainSender = [[QredoKeychainSender alloc] initWithClient:client delegate:self];
                [self.keychainSender startWithCompletionHandler:self.completionHandler];
            } else {
                // TODO [GR]: Implement error handling
            }
        });
    }];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.discoverRendezvousCancelHandler) {
        self.discoverRendezvousCancelHandler();
        self.discoverRendezvousCancelHandler = nil;
    }
    
    self.discoverRendezvousCompletionHandler = nil;
    
    if (self.sendConfirmationHandler) {
        self.sendConfirmationHandler(NO);
        self.sendConfirmationHandler = nil;
    }
}



#pragma mark QredoKeychainSenderDelegate

- (void)qredoKeychainSenderDiscoverRendezvous:(QredoKeychainSender *)sender completionHander:(BOOL(^)(NSString *rendezvousTag))completionHandler cancelHandler:(void(^)())cancelHandler {
    
    self.discoverRendezvousCancelHandler = cancelHandler;
    self.discoverRendezvousCompletionHandler = completionHandler;
    
    __weak QredoKeychainSenderQR *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showQRCodeSacannerWithScanningHandler:^(NSString *scannedResult, NSError *error) {
            
            QredoKeychainSenderQR *localSelf = weakSelf;
            
            if (error) {
                if (localSelf.discoverRendezvousCancelHandler) {
                    localSelf.discoverRendezvousCancelHandler();
                }
            } else {
                if (localSelf.discoverRendezvousCompletionHandler) {
                    if (!localSelf.discoverRendezvousCompletionHandler(scannedResult) ){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showFailureConfirmationController];
                        });
                    }
                }
            }
            
            localSelf.discoverRendezvousCancelHandler = nil;
            localSelf.discoverRendezvousCompletionHandler = nil;
            
        }];
    });
    
}

- (void)qredoKeychainSender:(QredoKeychainSender *)sender didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showFailureConfirmationController];
    });
}

- (void)qredoKeychainSender:(QredoKeychainSender *)sender didEstablishConnectionWithDevice:(QredoDeviceInfo *)deviceInfo fingerprint:(NSString *)fingerprint confirmationHandler:(void(^)(BOOL confirmed))confirmationHandler {
    self.sendConfirmationHandler = confirmationHandler;
    __weak QredoKeychainSenderQR *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showFingerprintConfirmationViewControllerWithFngerprint:fingerprint deviceName:deviceInfo.name confirmButtonHandler:^{
            QredoKeychainSenderQR *localSelf = weakSelf;
            if (localSelf.sendConfirmationHandler) {
                [localSelf showSendingKeychainActivityViewControllerWithFingerpring:fingerprint];
                localSelf.sendConfirmationHandler(YES);
            }
            localSelf.sendConfirmationHandler = nil;
        }];
    });
}

- (void)qredoKeychainSenderDidFinishSending:(QredoKeychainSender *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showSuccessConfirmationController];
    });
}

@end


