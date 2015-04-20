/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoCrypto.h"
#import "CryptoImpl.h"

#import "QredoDhPrivateKey.h"
#import "QredoDhPublicKey.h"


@interface QredoConversationCrypto : NSObject

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto;

- (NSData *)encryptMessage:(QLFConversationMessageLF *)message bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey;
- (QLFConversationMessageLF *)decryptMessage:(NSData *)encryptedMessage bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey error:(NSError**)error;

- (NSData *)requesterInboundEncryptionKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                            yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

- (NSData *)requesterInboundAuthenticationKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                                yourPublicKey:(QredoDhPublicKey *)yourPublicKey;


- (NSData *)requesterInboundQueueSeedWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                        yourPublicKey:(QredoDhPublicKey *)yourPublicKey;


- (NSData *)responderInboundEncryptionKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                            yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

- (NSData *)responderInboundAuthenticationKeyWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                                yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

- (NSData *)responderInboundQueueSeedWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                        yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

- (QredoQUID *)conversationIdWithMyPrivateKey:(QredoDhPrivateKey *)myPrivateKey
                                yourPublicKey:(QredoDhPublicKey *)yourPublicKey;

@end
