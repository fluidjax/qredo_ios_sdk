/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainQRCodeDisplayViewController.h"

@interface QredoKeychainQRCodeDisplayViewController ()
@property (nonatomic) UILabel *instructionsLabel;
@property (nonatomic) UIImageView *qrCodeImageView;
@end

@implementation QredoKeychainQRCodeDisplayViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.numberOfLines = 0;
    label.text = NSLocalizedString(@"Scan this QR Code with the device sending the keychain", @"Message displayed close to the QR Code for the key chain transfer.");
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    self.instructionsLabel = label;
    
    UIImageView *qrCodeImageView = [[UIImageView alloc] init];
    qrCodeImageView.translatesAutoresizingMaskIntoConstraints = NO;
    qrCodeImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:qrCodeImageView];
    self.qrCodeImageView = qrCodeImageView;
    
    UIView *bottomSpacer = [[UIView alloc] init];
    bottomSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bottomSpacer];
    
    id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(label, qrCodeImageView, bottomSpacer, topLayoutGuide, bottomLayoutGuide);
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-[label]-|"
                               options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-(20)-[qrCodeImageView]-(20)-|"
                               options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-[bottomSpacer]-|"
                               options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[topLayoutGuide]-[label(>=40)]-[qrCodeImageView]-[bottomSpacer(==label@700)]-[bottomLayoutGuide]"
                               options:0 metrics:nil views:views]];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateQRCodeImageViewWithQRCodeString:self.qrCodeValue];
    self.instructionsLabel.preferredMaxLayoutWidth = self.view.bounds.size.width-20;
}


- (void)updateQRCodeImageViewWithQRCodeString:(NSString *)aQRCodeString {
    
    if (aQRCodeString) {
        
        CGSize qrCodeImageViewSize = self.qrCodeImageView.bounds.size;
        CGFloat minSideLength = MIN(qrCodeImageViewSize.width, qrCodeImageViewSize.height);
        
        UIImage *qrCodeImage = [self createQRImageForString:aQRCodeString sideLength:minSideLength];
        self.qrCodeImageView.image = qrCodeImage;
        
    } else {
        
        self.qrCodeImageView.image = nil;
        
    }
    
}

- (UIImage *)createQRImageForString:(NSString *)qrString sideLength:(CGFloat)sideLength {
    
    if (sideLength < 1) {
        return nil;
    }
    
    CGFloat screenScale = [UIScreen mainScreen].scale;
    
    CIImage *ciImage = [self createQRImageForString:qrString];
    
    CGAffineTransform transform
    = CGAffineTransformMakeScale(sideLength / [ciImage extent].size.width * screenScale,
                                 sideLength / [ciImage extent].size.height * screenScale);
    ciImage = [ciImage imageByApplyingTransform:transform];
    
    
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:ciImage fromRect:ciImage.extent];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(ciImage.extent.size.width/screenScale, ciImage.extent.size.width/screenScale), YES, screenScale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);

    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    CGImageRelease(cgImage);
    return scaledImage;
    
}

- (CIImage *)createQRImageForString:(NSString *)qrString {
    
    NSData *qrData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:qrData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    return [qrFilter outputImage];
    
}

- (void)setQrCodeValue:(NSString *)qrCodeValue {
    if (_qrCodeValue == qrCodeValue) return;
    _qrCodeValue = qrCodeValue;
    [self updateQRCodeImageViewWithQRCodeString:self.qrCodeValue];
}

@end
