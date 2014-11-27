/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

#ifndef QredoSDK_QredoErrorCodes_h
#define QredoSDK_QredoErrorCodes_h


// Domain used in NSError
extern NSString *const QredoErrorDomain;


typedef NS_ENUM(NSInteger, QredoErrorCode) {
    
    QredoErrorCodeUnknown = 1000,
    QredoErrorCodeRemoteOperationFailure,

    // Vault errors
    QredoErrorCodeVaultUnknown = 2000,
    QredoErrorCodeVaultItemNotFound,
    QredoErrorCodeVaultItemHasBeenDeleted,
    
    // Rendezvous errors
    QredoErrorCodeRendezvousNotFound = 3001,
    QredoErrorCodeRendezvousInvalidData,
    QredoErrorCodeRendezvousAlreadyExists,
    QredoErrorCodeRendezvousUnknownResponse,
    QredoErrorCodeRendezvousWrongAuthenticationCode,

    // Conversation errors
    QredoErrorCodeConversationUnknown = 4000,
    QredoErrorCodeConversationNotFound,
    QredoErrorCodeConversatioinInvalidData,
    QredoErrorCodeConversationWrongAuthenticationCode,
};

#endif
