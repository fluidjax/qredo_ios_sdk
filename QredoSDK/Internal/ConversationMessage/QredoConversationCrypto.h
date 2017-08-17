/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoRawCrypto.h"
#import "QredoCryptoImpl.h"

#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"

#include "QredoKeyRef.h"

@interface QredoConversationCrypto :NSObject

-(instancetype)initWithCrypto:(id<QredoCryptoImpl>)crypto;

-(QLFEncryptedConversationItem *)encryptMessage:(QLFConversationMessage *)message
                                        bulkKeyRef:(QredoKeyRef *)bulkKeyRef
                                        authKeyRef:(QredoKeyRef *)authKeyRef;

-(QLFConversationMessage *)decryptMessage:(QLFEncryptedConversationItem *)encryptedMessage
                               bulkKeyRef:(QredoKeyRef *)bulkKeyRef
                            authKeyRef:(QredoKeyRef *)authKeyRef
                                    error:(NSError **)error;

-(QredoKeyRef *)conversationMasterKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                        yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

-(QredoKeyRef *)requesterInboundEncryptionKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(QredoKeyRef *)requesterInboundAuthenticationKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(NSData *)requesterInboundQueueSeedWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;

-(QredoKeyRef *)responderInboundEncryptionKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(QredoKeyRef *)responderInboundAuthenticationKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(NSData *)responderInboundQueueSeedWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(QredoQUID *)conversationIdWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;

@end
