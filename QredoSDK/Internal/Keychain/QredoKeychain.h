/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "CryptoImpl.h"

NS_ENUM(NSInteger, QredoCredentialType) {
    QredoCredentialTypeNoCredential = 0,
    QredoCredentialTypePIN = 1,
    QredoCredentialTypePattern = 2,
    QredoCredentialTypeFingerprint = 3,
    QredoCredentialTypePassword = 4,
    QredoCredentialTypePassphrase = 5,
    QredoCredentialTypeRandomBytes = 6
};

@interface QredoKeychain : NSObject

@property QLFOperatorInfo *operatorInfo;

- (instancetype)initWithOperatorInfo:(QLFOperatorInfo *)operatorInfo;

// used in tests only
- (instancetype)initWithOperatorInfo:(QLFOperatorInfo *)operatorInfo vaultId:(QredoQUID*)vaultId authenticationKey:(NSData*)authenticationKey bulkKey:(NSData*)bulkKey;
- (instancetype)initWithData:(NSData *)serializedData;

- (NSData *)data;
- (void)setVaultAuthKey:(NSData *)authKey bulkKey:(NSData *)bulkKey; // for testing
- (void)generateNewKeys;

- (void)setVaultId:(QredoQUID*)newVaultId; // TODO: temporary!
- (QredoQUID *)vaultId;
- (QredoED25519SigningKey *)vaultSigningKey;

- (QLFVaultKeyPair *)vaultKeys;

@end
