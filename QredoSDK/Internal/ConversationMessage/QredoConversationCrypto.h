/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoRawCrypto.h"
#import "QredoCryptoImpl.h"

#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"


@interface QredoConversationCrypto :NSObject

-(instancetype)initWithCrypto:(id<QredoCryptoImpl>)crypto;

-(QLFEncryptedConversationItem *)encryptMessage:(QLFConversationMessage *)message bulkKey:(QredoAESKey *)bulkKey authKey:(QredoKey *)authKey;
-(QLFConversationMessage *)decryptMessage:(QLFEncryptedConversationItem *)encryptedMessage bulkKey:(QredoAESKey *)bulkKey authKey:(QredoKey *)authKey error:(NSError **)error;

-(QredoKey *)conversationMasterKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

-(QredoAESKey *)requesterInboundEncryptionKeyWithMasterKey:(QredoKey *)masterKey;
-(QredoKey *)requesterInboundAuthenticationKeyWithMasterKey:(QredoKey *)masterKey;
-(NSData *)requesterInboundQueueSeedWithMasterKey:(QredoKey *)masterKey;

-(QredoAESKey *)responderInboundEncryptionKeyWithMasterKey:(QredoKey *)masterKey;
-(QredoKey *)responderInboundAuthenticationKeyWithMasterKey:(QredoKey *)masterKey;
-(NSData *)responderInboundQueueSeedWithMasterKey:(QredoKey *)masterKey;
-(QredoQUID *)conversationIdWithMasterKey:(QredoKey *)masterKey;

@end
