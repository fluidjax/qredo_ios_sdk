/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoClient.h"

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

@property QredoOperatorInfo *operatorInfo;

- (instancetype)initWithOperatorInfo:(QredoOperatorInfo *)operatorInfo;
- (instancetype)initWithData:(NSData *)serializedData;

- (NSData *)data;
- (void)setVaultAuthKey:(NSData *)authKey bulkKey:(NSData *)bulkKey; // for testing
- (void)generateNewKeys;

- (void)setVaultId:(QredoQUID*)newVaultId; // TODO temporary!
- (QredoQUID *)vaultId;

- (QredoVaultKeyPair *)vaultKeys;
@end
