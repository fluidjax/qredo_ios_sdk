/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

// Domain used in NSError
extern NSString *const QredoCryptoErrorDomain;

typedef NS_ENUM(NSInteger, QredoCryptoErrorCode) {
    QredoCryptoErrorCodeUnknown = 1000,
    QredoCryptoErrorCodeNilArgument,
    QredoCryptoErrorCodePublicKeyIncorrectFormat,
    QredoCryptoErrorCodePublicKeyInvalid,
    QredoCryptoErrorCodeCertificateIsNotValid,
    QredoCryptoErrorCodeOpenSslMemoryAllocationFailure,
    QredoCryptoErrorCodeOpenSslCertificateReadFailure,
    QredoCryptoErrorCodeOpenSslStackPushFailure,
    QredoCryptoErrorCodeOpenSslFailedToGetPublicKey,
    
};

@interface QredoCryptoError : NSObject

+ (void)populateError:(NSError **)error errorCode:(NSInteger)errorCode description:(NSString *)description;
+ (void)throwArgExceptionIf:(BOOL)condition reason:(NSString *)reason;

@end
