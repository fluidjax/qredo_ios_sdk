/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoCrypto.h"
#import "CryptoImpl.h"

#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"


@interface QredoConversationCrypto :NSObject

-(instancetype)initWithCrypto:(id<CryptoImpl>)crypto;

-(QLFEncryptedConversationItem *)encryptMessage:(QLFConversationMessage *)message bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey;
-(QLFConversationMessage *)decryptMessage:(QLFEncryptedConversationItem *)encryptedMessage bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey error:(NSError **)error;

-(NSData *)conversationMasterKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey yourPublicKey:(QredoDhPublicKey *)yourPublicKey;
-(NSData *)requesterInboundEncryptionKeyWithMasterKey:(NSData *)masterKey;
-(NSData *)requesterInboundAuthenticationKeyWithMasterKey:(NSData *)masterKey;
-(NSData *)requesterInboundQueueSeedWithMasterKey:(NSData *)masterKey;
-(NSData *)responderInboundEncryptionKeyWithMasterKey:(NSData *)masterKey;
-(NSData *)responderInboundAuthenticationKeyWithMasterKey:(NSData *)masterKey;
-(NSData *)responderInboundQueueSeedWithMasterKey:(NSData *)masterKey;
-(QredoQUID *)conversationIdWithMasterKey:(NSData *)masterKey;

@end
