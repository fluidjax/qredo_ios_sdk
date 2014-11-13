/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoErrorCodes_h
#define QredoSDK_QredoErrorCodes_h


// Domain used in NSError
extern NSString *const QredoErrorDomain;


typedef NS_ENUM(NSInteger, QredoErrorCode) {
    QredoErrorCodeUnknown               = -1001,
    QredoErrorCodeRemoteOperationFailure = -1002,

    // Vault errors
    QredoErrorCodeVaultUnknown          = -2000,
    QredoErrorCodeVaultItemNotFound     = -2001,

    // Rendezvous errors
    QredoErrorCodeRendezvousNotFound    = -3001,
    QredoErrorCodeRendezvousInvalidData = -3002,
    QredoErrorCodeRendezvousAlreadyExists = -3003,
    QredoErrorCodeRendezvousUnknownResponse = -3004,
    QredoErrorCodeRendezvousWrongAuthenticationCode = -3005,

    // Conversation errors
    QredoErrorCodeConversationUnknown = -4000,
    QredoErrorCodeConversationNotFound  = -4001,
    QredoErrorCodeConversatioinInvalidData = -4002,
    QredoErrorCodeConversationWrongAuthenticationCode = -4003
};

#endif
