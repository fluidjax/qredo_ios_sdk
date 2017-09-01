/* HEADER GOES HERE */
#import <CommonCrypto/CommonDigest.h>
#import "QredoConversationCrypto.h"
#import "QredoClient.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoErrorCodes.h"
#import "QredoQUIDPrivate.h"
#import "QredoCryptoRaw.h"
#import "QredoKeyRef.h"
#import "QredoCryptoKeychain.h"

#define SALT_REQUESTER_INBOUND_ENCKEY  [@"iJ8LLVtLlt2tzlXz" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_REQUESTER_INBOUND_AUTHKEY [@"7KySh0dMToM9IyzR" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_RESPONDER_INBOUND_ENCKEY  [@"BbSe15geLqnWW5Vb" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_RESPONDER_INBOUND_AUTHKEY [@"8i6DD1mbFMv4oG9I" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_REQUESTER_INBOUND_QUEUE   [@"eeK3hieyengahp3A" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_RESPONDER_INBOUND_QUEUE   [@"Wo6ahjata4tae5ij" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_ID           [@"0HvoEAAzECt71nYp" dataUsingEncoding:NSUTF8StringEncoding]

@interface QredoConversationCrypto (){

}

@end

@implementation QredoConversationCrypto



-(QLFEncryptedConversationItem *)encryptMessage:(QLFConversationMessage *)message
                                        bulkKeyRef:(QredoKeyRef *)bulkKeyRef
                                        authKeyRef:(QredoKeyRef *)authKeyRef{
    NSData *serializedMessage =  [QredoPrimitiveMarshallers marshalObject:message marshaller:[QLFConversationMessage marshaller]];
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
    
    NSData *encryptedMessage = [keychain encryptBulk:bulkKeyRef plaintext:serializedMessage];
    
    NSData *serializedEncryptedMessage = [QredoPrimitiveMarshallers marshalObject:encryptedMessage
                                                                      marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]];
    
    NSData *auth = [keychain authenticate:authKeyRef data:serializedEncryptedMessage];
    return [QLFEncryptedConversationItem encryptedConversationItemWithEncryptedMessage:serializedEncryptedMessage
                                                                              authCode:auth];
}


-(QLFConversationMessage *)decryptMessage:(QLFEncryptedConversationItem *)encryptedMessage
                                  bulkKeyRef:(QredoKeyRef *)bulkKeyRef
                                  authKeyRef:(QredoKeyRef *)authKeyRef
                                    error:(NSError **)error {
    
    
    BOOL verified = [[QredoCryptoKeychain sharedQredoCryptoKeychain] verify:authKeyRef
                                data:encryptedMessage.encryptedMessage
                           signature:encryptedMessage.authCode];
    if (!verified){
        if (error){
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationWrongAuthenticationCode
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Authentication code doesn't match" }];
        }
        return nil;
    }
    
    NSData *encryptedData = encryptedMessage.encryptedMessage;
    NSData *deserializedEncryptedData = [QredoPrimitiveMarshallers unmarshalObject:encryptedData
                                                                      unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]];
    
   
    NSData *decryptedMessageData = [[QredoCryptoKeychain sharedQredoCryptoKeychain] decryptBulk:bulkKeyRef
                                                                                     ciphertext:deserializedEncryptedData];
    
    @try {
        return [QredoPrimitiveMarshallers unmarshalObject:decryptedMessageData
                                             unmarshaller:[QLFConversationMessage unmarshaller]];
    } @catch (NSException *exception){
        if (error){
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationInvalidData
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Failed to parse data" }];
        }
        return nil;
    }
}


-(QredoKeyRef *)conversationMasterKeyWithMyPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef
                                        yourPublicKeyRef:(QredoKeyRef *)yourPublicKeyRef {
    return [[QredoCryptoKeychain sharedQredoCryptoKeychain] generateDiffieHellmanMasterKeyWithMyPrivateKeyRef:myPrivateKeyRef
                                                                                        yourPublicKeyRef:yourPublicKeyRef];
}


-(QredoKeyRef *)requesterInboundEncryptionKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    return [[QredoCryptoKeychain sharedQredoCryptoKeychain] deriveKeyRef:masterKeyRef
                                                                    salt:SALT_REQUESTER_INBOUND_ENCKEY info:[NSData data]];
}


-(QredoKeyRef *)requesterInboundAuthenticationKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    return [[QredoCryptoKeychain sharedQredoCryptoKeychain] deriveKeyRef:masterKeyRef
                                                                    salt:SALT_REQUESTER_INBOUND_AUTHKEY info:[NSData data]];
}


-(QredoKeyRef *)requesterInboundQueueSeedWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    return [[QredoCryptoKeychain sharedQredoCryptoKeychain] deriveKeyRef:masterKeyRef
                                                                 salt:SALT_REQUESTER_INBOUND_QUEUE info:[NSData data]];
}


-(QredoKeyRef *)responderInboundEncryptionKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    return [[QredoCryptoKeychain sharedQredoCryptoKeychain] deriveKeyRef:masterKeyRef
                                                                    salt:SALT_RESPONDER_INBOUND_ENCKEY info:[NSData data]];

}


-(QredoKeyRef *)responderInboundAuthenticationKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    return [[QredoCryptoKeychain sharedQredoCryptoKeychain] deriveKeyRef:masterKeyRef
                                                                    salt:SALT_RESPONDER_INBOUND_AUTHKEY info:[NSData data]];
}


-(QredoKeyRef *)responderInboundQueueSeedWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    return [[QredoCryptoKeychain sharedQredoCryptoKeychain] deriveKeyRef:masterKeyRef
                                                                 salt:SALT_RESPONDER_INBOUND_QUEUE info:[NSData data]];
}


-(QredoQUID *)conversationIdWithMasterKeyRef:(QredoKeyRef *)masterKeyRef {
    QredoCryptoKeychain *keychain = [QredoCryptoKeychain sharedQredoCryptoKeychain];
    QredoKeyRef *keyRef = [keychain deriveKeyRef:masterKeyRef salt:SALT_CONVERSATION_ID info:[NSData data]];
    return [keychain keyRefToQUID:keyRef];
}


@end
