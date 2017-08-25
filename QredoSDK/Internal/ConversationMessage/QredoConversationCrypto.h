/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoRawCrypto.h"
#include "QredoKeyRef.h"

@interface QredoConversationCrypto :NSObject


-(QLFEncryptedConversationItem *)encryptMessage:(QLFConversationMessage *)message
                                        bulkKeyRef:(QredoKeyRef *)bulkKeyRef
                                        authKeyRef:(QredoKeyRef *)authKeyRef;

-(QLFConversationMessage *)decryptMessage:(QLFEncryptedConversationItem *)encryptedMessage
                               bulkKeyRef:(QredoKeyRef *)bulkKeyRef
                               authKeyRef:(QredoKeyRef *)authKeyRef
                                    error:(NSError **)error;

-(QredoKeyRef *)conversationMasterKeyWithMyPrivateKeyRef:(QredoKeyRef *)myPrivateKeyRef
                                        yourPublicKeyRef:(QredoKeyRef *)yourPublicKeyRef;

-(QredoKeyRef *)requesterInboundEncryptionKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(QredoKeyRef *)requesterInboundAuthenticationKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(QredoKeyRef *)requesterInboundQueueSeedWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;

-(QredoKeyRef *)responderInboundEncryptionKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(QredoKeyRef *)responderInboundAuthenticationKeyWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(QredoKeyRef *)responderInboundQueueSeedWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;
-(QredoQUID *)conversationIdWithMasterKeyRef:(QredoKeyRef *)masterKeyRef;

@end
