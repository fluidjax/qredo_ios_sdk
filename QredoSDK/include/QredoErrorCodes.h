/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

// Domain used in NSError
extern NSString *const QredoErrorDomain;


typedef NS_ENUM(NSInteger, QredoErrorCode) {
    QredoErrorCodeUnknown = 1000,
    QredoErrorCodeRemoteOperationFailure,
    QredoErrorCodeAppNotAuthorized,

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
    QredoErrorCodeConversationDeleted,


    // Conversation protocol errors
    QredoErrorCodeConversationProtocolUnknown = 5000,
    QredoErrorCodeConversationProtocolWrongState,
    QredoErrorCodeConversationProtocolCancelledByOtherSide,
    QredoErrorCodeConversationProtocolUnexpectedMessageType,
    QredoErrorCodeConversationProtocolReceivedMalformedData,
    QredoErrorCodeConversationProtocolTimeout,
    
    // Keychain errors
    QredoErrorCodeKeychainCouldNotBeFound = 6000,
    QredoErrorCodeKeychainCouldNotBeRetrieved,
    QredoErrorCodeKeychainCouldNotBeSaved,
    QredoErrorCodeKeychainCouldNotBeDelete,
    
};



