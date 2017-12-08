/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>

@interface QredoCertificate :NSObject
@property (nonatomic,readonly) SecCertificateRef certificate;
+(instancetype)certificateWithSecCertificateRef:(SecCertificateRef)certificate;
@end
