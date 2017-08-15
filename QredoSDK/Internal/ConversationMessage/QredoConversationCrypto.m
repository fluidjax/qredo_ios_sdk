/* HEADER GOES HERE */
#import <CommonCrypto/CommonDigest.h>
#import "QredoConversationCrypto.h"
#import "QredoClient.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoErrorCodes.h"
#import "QredoQUIDPrivate.h"
#import "QredoRawCrypto.h"
#import "QredoBulkEncKey.h"


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


-(QLFEncryptedConversationItem *)encryptMessage:(QLFConversationMessage *)message bulkKey:(QredoBulkEncKey *)bulkKey authKey:(QredoKey *)authKey{
    NSData *serializedMessage =
    [QredoPrimitiveMarshallers marshalObject:message
                                  marshaller:[QLFConversationMessage marshaller]];
    
    
    NSData *encryptedMessage = [_crypto encryptBulk:bulkKey plaintext:serializedMessage];
    
    
    NSData *serializedEncryptedMessage = [QredoPrimitiveMarshallers marshalObject:encryptedMessage
                                                                      marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]];
    
    NSData *auth = [_crypto getAuthCodeWithKey:authKey data:serializedEncryptedMessage];
    return [QLFEncryptedConversationItem encryptedConversationItemWithEncryptedMessage:serializedEncryptedMessage
                                                                              authCode:auth];
}


-(QLFConversationMessage *)decryptMessage:(QLFEncryptedConversationItem *)encryptedMessage bulkKey:(QredoBulkEncKey *)bulkKey authKey:(QredoKey *)authKey error:(NSError **)error {
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
    
   
    NSData *decryptedMessageData = [_crypto decryptBulk:bulkKey ciphertext:deserializedEncryptedData];
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


-(QredoKey *)conversationMasterKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                    yourPublicKey:(QredoDhPublicKey *)yourPublicKey {
    return [_crypto getDiffieHellmanMasterKeyWithMyPrivateKey:myPrivateKey yourPublicKey:yourPublicKey];
}


-(QredoBulkEncKey *)requesterInboundEncryptionKeyWithMasterKey:(QredoKey *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:[masterKey bytes]
                                            salt:SALT_REQUESTER_INBOUND_ENCKEY];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return [[QredoBulkEncKey alloc] initWithData:okm];
}


-(QredoKey *)requesterInboundAuthenticationKeyWithMasterKey:(QredoKey *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:[masterKey bytes]
                                            salt:SALT_REQUESTER_INBOUND_AUTHKEY];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return [[QredoKey alloc] initWithData:okm];
}


-(NSData *)requesterInboundQueueSeedWithMasterKey:(QredoKey *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:[masterKey bytes]
                                            salt:SALT_REQUESTER_INBOUND_QUEUE];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


-(QredoBulkEncKey *)responderInboundEncryptionKeyWithMasterKey:(QredoKey *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:[masterKey bytes]
                                            salt:SALT_RESPONDER_INBOUND_ENCKEY];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return [[QredoBulkEncKey alloc] initWithData:okm];
}


-(QredoKey *)responderInboundAuthenticationKeyWithMasterKey:(QredoKey *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:[masterKey bytes]
                                            salt:SALT_RESPONDER_INBOUND_AUTHKEY];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return [[QredoKey alloc] initWithData:okm];
}


-(NSData *)responderInboundQueueSeedWithMasterKey:(QredoKey *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:[masterKey bytes]
                                            salt:SALT_RESPONDER_INBOUND_QUEUE];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return okm;
}


-(QredoQUID *)conversationIdWithMasterKey:(QredoKey *)masterKey {
    NSData *prk = [QredoRawCrypto hkdfSha256Extract:[masterKey bytes]
                                            salt:SALT_CONVERSATION_ID];
    NSData *okm = [QredoRawCrypto hkdfSha256Expand:prk
                                           info:[NSData data]
                                   outputLength:CC_SHA256_DIGEST_LENGTH];
    return [[QredoQUID alloc] initWithQUIDData:okm];
}


@end
