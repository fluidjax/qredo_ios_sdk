/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

// Domain used in NSError
extern NSString *const QredoErrorDomain;


typedef NS_ENUM (NSInteger, QredoErrorCode) {
    QredoErrorCodeUnknown = 1000,
    QredoErrorCodeRemoteOperationFailure,
    QredoErrorCodeAppNotAuthorized,
    QredoErrorCodeMalformedOrTamperedData,
        
    // Vault errors
    QredoErrorCodeVaultUnknown = 2000,
    QredoErrorCodeVaultItemNotFound,
    QredoErrorCodeVaultItemHasBeenDeleted,
    QredoErrorCodeVaultInsufficientParameters,
    
    
    // Rendezvous errors
    QredoErrorCodeRendezvousNotFound = 3001,
    QredoErrorCodeRendezvousInvalidData,
    QredoErrorCodeRendezvousAlreadyExists,
    QredoErrorCodeRendezvousUnknownResponse,
    QredoErrorCodeRendezvousWrongAuthenticationCode,
    QredoErrorCodeRendezvousAccessControlKeyMissing,
    QredoErrorCodeRendezvousAccessControlSignatureGenerationFailed,
    
    // Conversation errors
    QredoErrorCodeConversationUnknown = 4000,
    QredoErrorCodeConversationNotFound,
    QredoErrorCodeConversationInvalidData,
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
    
    
    //LocalIndex errors
    QredoErrorCodeIndexErrorUnknown = 7000,
    QredoErrorCodeIndexItemNotFound,
};



