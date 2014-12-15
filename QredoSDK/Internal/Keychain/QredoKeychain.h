/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoClient.h"

@interface QredoKeychain : NSObject

- (instancetype)initWithOperatorInfo:(QredoOperatorInfo *)operatorInfo
                             vaultId:(QredoQUID *)vaultId
                   authenticationKey:(NSData *)authenticationKey
                             bulkKey:(NSData *)bulkKey;
- (instancetype)initWithData:(NSData *)serializedData;

- (NSData *)data;
- (void)setVaultAuthKey:(NSData *)authKey bulkKey:(NSData *)bulkKey; // for testing
- (void)generateNewKeys;

- (void)setVaultId:(QredoQUID*)newVaultId; // TODO temporary!
- (QredoQUID *)vaultId;

- (QredoVaultKeyPair *)vaultKeys;
- (NSData *)vaultBulkKeyForAccessLevel:(int)accessLevel credential:(NSData *)credential;
- (NSData *)vaultAuthKeyForAccessLevel:(int)accessLevel credential:(NSData *)credential;

@end
