/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface QredoCertificate :NSObject
@property (nonatomic,readonly) SecCertificateRef certificate;
+(instancetype)certificateWithSecCertificateRef:(SecCertificateRef)certificate;
@end
