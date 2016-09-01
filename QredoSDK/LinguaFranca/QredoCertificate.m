/* HEADER GOES HERE */
#import "QredoCertificate.h"

@interface QredoCertificate()
@end


@implementation QredoCertificate
{
    SecCertificateRef _certificate;
}

@dynamic certificate;

- (instancetype)init
{
    self = [super init];
    NSAssert(FALSE, @"QredoCertificate can not be initialized with init without arguments. Please use one of the other init methods");
    self = nil;
    return self;
}

- (instancetype)initWithSecCertificateRef:(SecCertificateRef)certificate
{
    self = [super init];
    if (self) {
        _certificate = certificate;
        if (!_certificate) {
            NSAssert(FALSE, @"QredoCertificate must be initialized with a certificate.");
            self = nil;
            return self;
        }
        CFRetain(_certificate);
    }
    return self;
}

+ (instancetype)certificateWithSecCertificateRef:(SecCertificateRef)certificate
{
    return [[self alloc] initWithSecCertificateRef:certificate];
}

- (void)dealloc
{
    if (_certificate) {
        CFRelease(_certificate);
    }
}

- (SecCertificateRef)certificate
{
    return _certificate;
}

@end


