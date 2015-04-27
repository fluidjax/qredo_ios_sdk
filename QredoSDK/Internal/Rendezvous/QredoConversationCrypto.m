/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoConversationCrypto.h"
#import "QredoClient.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoErrorCodes.h"

#import <CommonCrypto/CommonCrypto.h>

#define SALT_REQUESTER_INBOUND_ENCKEY [@"iJ8LLVtLlt2tzlXz" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_REQUESTER_INBOUND_AUTHKEY [@"7KySh0dMToM9IyzR" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_RESPONDER_INBOUND_ENCKEY [@"BbSe15geLqnWW5Vb" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_RESPONDER_INBOUND_AUTHKEY [@"8i6DD1mbFMv4oG9I" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_REQUESTER_INBOUND_QUEUE [@"eeK3hieyengahp3A" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_RESPONDER_INBOUND_QUEUE [@"Wo6ahjata4tae5ij" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_ID [@"0HvoEAAzECt71nYp" dataUsingEncoding:NSUTF8StringEncoding]

@interface QredoConversationCrypto ()
{
    id<CryptoImpl> _crypto;
}

@end

@implementation QredoConversationCrypto

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto
{
    NSAssert(crypto, @"crypto should not be nil");
    
    self = [super init];
    if (!self) return nil;
    
    _crypto = crypto;
    
    return self;
}

- (NSData *)encryptMessage:(QLFConversationMessageLF *)message bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey
{
    NSMutableData* result = [NSMutableData data];
    
    NSData *serializedMessage =
        [QredoPrimitiveMarshallers marshalObject:message
                                      marshaller:[QLFConversationMessageLF marshaller]];

    
    NSData *encryptedMessage = [_crypto encryptWithKey:bulkKey data:serializedMessage];

    NSData *serialiedEncryptedMessage =
        [QredoPrimitiveMarshallers marshalObject:encryptedMessage
                                      marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]];
    
    NSData * auth = [_crypto getAuthCodeWithKey:authKey data:serialiedEncryptedMessage];
    
    [result appendData:serialiedEncryptedMessage];
    [result appendData:auth];
    
    return [result copy]; // return non-mutable copy
}

- (QLFConversationMessageLF *)decryptMessage:(NSData *)encryptedMessage bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey error:(NSError**)error
{
    // verify auth code
    
    BOOL verified = [_crypto verifyAuthCodeWithKey:authKey data:encryptedMessage];
    
    if (!verified) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationWrongAuthenticationCode
                                     userInfo:@{NSLocalizedDescriptionKey: @"Authentication code doesn't match"}];
        }
        return nil;
    }

    NSData *encryptedData = [encryptedMessage subdataWithRange:NSMakeRange(0, encryptedMessage.length - CC_SHA256_DIGEST_LENGTH)];


    NSData *deserializedEncryptedData = [QredoPrimitiveMarshallers unmarshalObject:encryptedData
                                                                      unmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]];


    NSData *decryptedMessageData = [_crypto decryptWithKey:bulkKey data:deserializedEncryptedData];

    
    return [QredoPrimitiveMarshallers unmarshalObject:decryptedMessageData unmarshaller:[QLFConversationMessageLF unmarshaller]];
}

- (NSData *)conversationMasterKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                    yourPublicKey:(QredoDhPublicKey *)yourPublicKey
{
    return [_crypto getDiffieHellmanMasterKeyWithMyPrivateKey:myPrivateKey yourPublicKey:yourPublicKey];
}

- (NSData *)requesterInboundEncryptionKeyWithMasterKey:(NSData *)masterKey
{
    return [QredoCrypto hkdfSha256WithSalt:SALT_REQUESTER_INBOUND_ENCKEY initialKeyMaterial:masterKey info:nil];
}

- (NSData *)requesterInboundAuthenticationKeyWithMasterKey:(NSData *)masterKey
{
    return [QredoCrypto hkdfSha256WithSalt:SALT_REQUESTER_INBOUND_AUTHKEY initialKeyMaterial:masterKey info:nil];
}


- (NSData *)requesterInboundQueueSeedWithMasterKey:(NSData *)masterKey
{
    return [QredoCrypto hkdfSha256WithSalt:SALT_REQUESTER_INBOUND_QUEUE initialKeyMaterial:masterKey info:nil];
}


- (NSData *)responderInboundEncryptionKeyWithMasterKey:(NSData *)masterKey
{
    return [QredoCrypto hkdfSha256WithSalt:SALT_RESPONDER_INBOUND_ENCKEY initialKeyMaterial:masterKey info:nil];
}

- (NSData *)responderInboundAuthenticationKeyWithMasterKey:(NSData *)masterKey
{
    return [QredoCrypto hkdfSha256WithSalt:SALT_RESPONDER_INBOUND_AUTHKEY initialKeyMaterial:masterKey info:nil];
}

- (NSData *)responderInboundQueueSeedWithMasterKey:(NSData *)masterKey
{
    return [QredoCrypto hkdfSha256WithSalt:SALT_RESPONDER_INBOUND_QUEUE initialKeyMaterial:masterKey info:nil];
}

- (QredoQUID *)conversationIdWithMasterKey:(NSData *)masterKey
{
    NSData *conversationIdData = [QredoCrypto hkdfSha256WithSalt:SALT_CONVERSATION_ID initialKeyMaterial:masterKey info:nil];
    return [[QredoQUID alloc] initWithQUIDData:conversationIdData];
}

@end
