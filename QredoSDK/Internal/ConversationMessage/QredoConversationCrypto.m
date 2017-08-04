/* HEADER GOES HERE */
#import <CommonCrypto/CommonDigest.h>
#import "QredoConversationCrypto.h"
#import "QredoClient.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoErrorCodes.h"
#import "QredoQUIDPrivate.h"
#import "QredoRawCrypto.h"

#define SALT_REQUESTER_INBOUND_ENCKEY  [@"iJ8LLVtLlt2tzlXz" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_REQUESTER_INBOUND_AUTHKEY [@"7KySh0dMToM9IyzR" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_RESPONDER_INBOUND_ENCKEY  [@"BbSe15geLqnWW5Vb" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_RESPONDER_INBOUND_AUTHKEY [@"8i6DD1mbFMv4oG9I" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_REQUESTER_INBOUND_QUEUE   [@"eeK3hieyengahp3A" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_RESPONDER_INBOUND_QUEUE   [@"Wo6ahjata4tae5ij" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_CONVERSATION_ID           [@"0HvoEAAzECt71nYp" dataUsingEncoding:NSUTF8StringEncoding]

@interface QredoConversationCrypto (){
    id<QredoCryptoImpl> _crypto;
}

@end

@implementation QredoConversationCrypto

-(instancetype)initWithCrypto:(id<QredoCryptoImpl>)crypto{
    NSAssert(crypto,@"crypto should not be nil");
    self = [super init];
    if (self){
        _crypto = crypto;
    }
    return self;
}


-(QLFEncryptedConversationItem *)encryptMessage:(QLFConversationMessage *)message bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey{
    NSData *serializedMessage =
    [QredoPrimitiveMarshallers marshalObject:message
                                  marshaller:[QLFConversationMessage marshaller]];
    
    NSData *encryptedMessage = [_crypto encryptWithKey:bulkKey data:serializedMessage iv:nil];
    NSData *serialiedEncryptedMessage = [QredoPrimitiveMarshallers marshalObject:encryptedMessage
                                                                      marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]];
    
    NSData *auth = [_crypto getAuthCodeWithKey:authKey data:serialiedEncryptedMessage];
    return [QLFEncryptedConversationItem encryptedConversationItemWithEncryptedMessage:serialiedEncryptedMessage
                                                                              authCode:auth];
}


-(QLFConversationMessage *)decryptMessage:(QLFEncryptedConversationItem *)encryptedMessage bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey error:(NSError **)error {
    BOOL verified = [_crypto verifyAuthCodeWithKey:authKey
                                              data:encryptedMessage.encryptedMessage
                                               mac:encryptedMessage.authCode];
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
    NSData *decryptedMessageData = [_crypto decryptWithKey:bulkKey data:deserializedEncryptedData];
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


-(NSData *)conversationMasterKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                   yourPublicKey:(QredoDhPublicKey *)yourPublicKey {
    return [_crypto getDiffieHellmanMasterKeyWithMyPrivateKey:myPrivateKey yourPublicKey:yourPublicKey];
}


-(NSData *)requesterInboundEncryptionKeyWithMasterKey:(NSData *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:SALT_REQUESTER_INBOUND_ENCKEY];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


-(NSData *)requesterInboundAuthenticationKeyWithMasterKey:(NSData *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:SALT_REQUESTER_INBOUND_AUTHKEY];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


-(NSData *)requesterInboundQueueSeedWithMasterKey:(NSData *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:SALT_REQUESTER_INBOUND_QUEUE];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


-(NSData *)responderInboundEncryptionKeyWithMasterKey:(NSData *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:SALT_RESPONDER_INBOUND_ENCKEY];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


-(NSData *)responderInboundAuthenticationKeyWithMasterKey:(NSData *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:SALT_RESPONDER_INBOUND_AUTHKEY];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


-(NSData *)responderInboundQueueSeedWithMasterKey:(NSData *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:SALT_RESPONDER_INBOUND_QUEUE];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


-(QredoQUID *)conversationIdWithMasterKey:(NSData *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:masterKey
                                            salt:SALT_CONVERSATION_ID];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return [[QredoQUID alloc] initWithQUIDData:okm];
}


@end
