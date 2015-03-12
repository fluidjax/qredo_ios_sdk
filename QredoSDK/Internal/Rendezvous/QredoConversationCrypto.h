/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoCrypto.h"
#import "CryptoImpl.h"

@interface QredoConversationCrypto : NSObject

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto;

- (NSData *)encryptMessage:(QLFConversationMessageLF *)message bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey;
- (QLFConversationMessageLF *)decryptMessage:(NSData *)encryptedMessage bulkKey:(NSData *)bulkKey authKey:(NSData *)authKey error:(NSError**)error;

@end
