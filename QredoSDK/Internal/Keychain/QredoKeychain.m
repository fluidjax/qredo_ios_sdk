/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychain.h"
#import "CryptoImplV1.h"
#import "QredoCrypto.h"
#import "QredoErrorCodes.h"
#import <CommonCrypto/CommonCrypto.h>
#import "NSData+QredoRandomData.h"
#import "QredoVaultCrypto.h"

@interface QredoKeychain ()
{
    BOOL _isInitialized;

    NSData *_masterKey;

    CryptoImplV1 *_crypto;
}

@end

@implementation QredoKeychain

- (void)initialize {
    _crypto = [CryptoImplV1 new];
}

- (instancetype)initWithOperatorInfo:(QLFOperatorInfo *)operatorInfo {
    self = [super init];
    if (self) {
        [self initialize];
        _isInitialized = NO;
        _operatorInfo = operatorInfo;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)serializedData
{
    self = [super init];

    [self initialize];

    _isInitialized = YES;

    _masterKey = [serializedData copy];

    [self deriveKeys];

    return self;
}

- (NSData *)data
{
    if (!_isInitialized) return nil;

    return _masterKey;
}


- (void)generateNewKeys
{
    _isInitialized = YES;

    _masterKey = [QredoCrypto secureRandomWithSize:32];

    // Uncomment this line for testing cross-platform vault without keychain transporter
//    _masterKey = [@"12345678901234567890123456789012" dataUsingEncoding:NSUTF8StringEncoding];
    [self deriveKeys];
}

- (void)deriveKeys
{
    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:_masterKey];
    self.systemVaultKeys = [[QredoVaultKeys alloc] initWithVaultKey:[QredoVaultCrypto systemVaultKeyWithVaultMasterKey:vaultMasterKey]];
    self.defaultVaultKeys = [[QredoVaultKeys alloc] initWithVaultKey:[QredoVaultCrypto userVaultKeyWithVaultMasterKey:vaultMasterKey]];
}

@end
