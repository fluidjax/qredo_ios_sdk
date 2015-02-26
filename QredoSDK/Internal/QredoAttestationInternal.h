/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>


extern NSString *const QredoAttestationErrorDomain;
extern NSString *const QredoAttestationPreviousErrorKey;


typedef NS_ENUM(NSUInteger, QredoAttestationErrorCode) {
    QredoAttestationErrorCodeUnknown = 0,
    
    QredoAttestationErrorCodeUnexpectedMessageType,
    QredoAttestationErrorCodePresentationMessageDoesNotHaveValue,
    QredoAttestationErrorCodePresentationMessageHasCorruptValue,
    QredoAttestationErrorCodePresentationTimeout,
    
    QredoAttestationErrorCodeAuthenticationFailed,
    QredoAttestationErrorCodeAuthenticationTimeout,
    
    QredoAttestationErrorCodeConversationBetweenRelientPartyAndCalaimantCoudNotBeCanceled,
    
    
};


void updateQredoClaimantAttestationProtocolError(NSError **error,
                                                 QredoAttestationErrorCode errorCode,
                                                 NSDictionary *userInfo);


