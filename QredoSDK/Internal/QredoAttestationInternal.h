/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>


extern NSString *const QredoAttestationErrorDomain;


typedef NS_ENUM(NSUInteger, QredoAttestationErrorCode) {
    QredoAttestationErrorCodeUnknown = 0,
    
    QredoAttestationErrorCodeUnexpectedMessageType,
    QredoAttestationErrorCodePresentationMessageDoesNotHaveValue,
    QredoAttestationErrorCodePresentationMessageHasCorruptValue,
    
    QredoAttestationErrorCodeAuthenticationFailed,
    
    
};


void updateQredoClaimantAttestationProtocolError(NSError **error,
                                                 QredoAttestationErrorCode errorCode,
                                                 NSDictionary *userInfo);


