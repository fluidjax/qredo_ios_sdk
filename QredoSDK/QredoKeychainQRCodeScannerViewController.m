/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainQRCodeScannerViewController.h"
#import <AVFoundation/AVFoundation.h>


static NSString *const QredoKeychainQRCodeTransporterErrorDomain = @"QredoKeychainQRCodeTransporterErrorDomain";

typedef NS_ENUM(NSUInteger, QredoKeychainQRCodeTransporterError) {
    QredoKeychainQRCodeTransporterErrorUnknown = 0,
    QredoKeychainQRCodeTransporterErrorCouldNotInitiateAVFoundationComponents,
};


AVCaptureVideoOrientation videoOrientationWithInterfaceOrientation(UIInterfaceOrientation interfaceOrientation);

@interface QredoKeychainQRCodeScannerViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic) UIView *cameraView;
@property (nonatomic) AVCaptureDevice *defaultDevice;
@property (nonatomic) AVCaptureDeviceInput *defaultDeviceInput;
@property (nonatomic) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, copy) void(^scanningHandler)(NSString *scannedResult, NSError *error);

@end

@implementation QredoKeychainQRCodeScannerViewController

- (instancetype)initWithScanningHandler:(void(^)(NSString *scannedResult, NSError *error))aScanningHandler
{
    self = [super init];
    if (self) {
        self.scanningHandler = aScanningHandler;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *cameraView = [[UIView alloc] init];
    cameraView.translatesAutoresizingMaskIntoConstraints = NO;
    cameraView.clipsToBounds = YES;
    [self.view addSubview:cameraView];
    self.cameraView = cameraView;
    
    id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(topLayoutGuide, cameraView, bottomLayoutGuide);

    [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|[cameraView]|"
                                   options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[topLayoutGuide][cameraView][bottomLayoutGuide]"
                                   options:0 metrics:nil views:views]];

    
    [self setupAVFoundationObjectsWithCameraView:cameraView];
    
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.previewLayer.connection.videoOrientation = videoOrientationWithInterfaceOrientation(toInterfaceOrientation);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.cameraView.layer.bounds;
    bounds.origin = CGPointZero;
    self.previewLayer.bounds =  bounds;
    self.previewLayer.position = CGPointMake(bounds.size.width/2.0f, bounds.size.height/2.0f);
}


- (void)setupAVFoundationObjectsWithCameraView:(UIView *)cameraView {
    
    self.defaultDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (self.defaultDevice) {
        
        self.defaultDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.defaultDevice error:nil];
        self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        self.session = [[AVCaptureSession alloc] init];
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        
        [self.session addOutput:self.metadataOutput];
        [self.session addInput:self.defaultDeviceInput];
        
        [self.metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        if ([[self.metadataOutput availableMetadataObjectTypes] containsObject:AVMetadataObjectTypeQRCode]) {
            [self.metadataOutput setMetadataObjectTypes:@[ AVMetadataObjectTypeQRCode ]];
        }
        [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        if ([self.previewLayer.connection isVideoOrientationSupported]) {
            self.previewLayer.connection.videoOrientation = videoOrientationWithInterfaceOrientation([UIApplication sharedApplication].statusBarOrientation);
        }

        [cameraView.layer insertSublayer:self.previewLayer atIndex:0];
        
        [self.view setNeedsLayout];
        
    } else {
        
        if (self.scanningHandler) {
            NSError *error = [NSError errorWithDomain:QredoKeychainQRCodeTransporterErrorDomain
                                                 code:QredoKeychainQRCodeTransporterErrorCouldNotInitiateAVFoundationComponents
                                             userInfo:nil];
            self.scanningHandler(nil, error);
        }
        
    }
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    for(AVMetadataObject *current in metadataObjects) {
        if ([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]]
            && [current.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            
            [self.session stopRunning];
            
            NSString *scannedResult = [(AVMetadataMachineReadableCodeObject *) current stringValue];
            if (self.scanningHandler) {
                self.scanningHandler(scannedResult, nil);
            }
            
            break;
        }
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end


AVCaptureVideoOrientation videoOrientationWithInterfaceOrientation(UIInterfaceOrientation interfaceOrientation) {

    switch (interfaceOrientation) {
        case UIInterfaceOrientationUnknown:
            return AVCaptureVideoOrientationPortrait;
            
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;

        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;

        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
    }
}


