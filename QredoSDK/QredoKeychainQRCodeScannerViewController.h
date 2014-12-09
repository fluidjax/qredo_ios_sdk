/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>

@interface QredoKeychainQRCodeScannerViewController : UIViewController
- (instancetype)initWithScanningHandler:(void(^)(NSString *scannedResult, NSError *error))aScanningHandler;
@end
