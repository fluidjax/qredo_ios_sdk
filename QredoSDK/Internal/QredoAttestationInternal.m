/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoAttestationInternal.h"


NSString *const QredoAttestationErrorDomain = @"QredoAttestationErrorDomain";
NSString *const QredoAttestationPreviousErrorKey = @"QredoAttestationPreviousErrorKey";


void updateQredoClaimantAttestationProtocolError(NSError **error,
                                                 QredoAttestationErrorCode errorCode,
                                                 NSDictionary *userInfo)
{
    if (error) {
        *error = [NSError errorWithDomain:QredoAttestationErrorDomain code:errorCode userInfo:userInfo];
    }
}
