/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import <Foundation/Foundation.h>

@interface QredoCertificate : NSObject
@property (nonatomic, readonly) SecCertificateRef certificate;
+ (instancetype)certificateWithSecCertificateRef:(SecCertificateRef)certificate;
@end

