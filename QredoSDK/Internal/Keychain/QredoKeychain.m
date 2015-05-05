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

#define SALT_RECOVERY_INFO [@"Zestybus" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_KEYSTORE_KEYS [@"Ferirama" dataUsingEncoding:NSUTF8StringEncoding]

// TODO: DH - replace 'Bioyino' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_CREDENTIAL_AUTHENTICATION [@"Bioyino" dataUsingEncoding:NSUTF8StringEncoding]
// TODO: DH - replace 'Waratel' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_CREDENTIAL_ENCRYPTION [@"Waratel" dataUsingEncoding:NSUTF8StringEncoding]

#define SALT_KEYCHAIN_ENCRYPTION [@"Ukewaiqv" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_KEYCHAIN_AUTHENTICATION [@"Owyurdefip" dataUsingEncoding:NSUTF8StringEncoding]

// TODO: DH - replace 'Goulbap' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_VAULT_KEYS [@"Goulbap" dataUsingEncoding:NSUTF8StringEncoding]

// TODO: DH - replace 'Replitz' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_VAULT_ENCRYPTION_0 [@"Replitz" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_1 [@"Dizoolexa" dataUsingEncoding:NSUTF8StringEncoding]
// TODO: DH - replace 'Aloidia' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_VAULT_ENCRYPTION_2 [@"Aloidia" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_3 [@"Loheckle" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_ENCRYPTION_4 [@"Uliratha" dataUsingEncoding:NSUTF8StringEncoding]

#define SALT_DERIVE_VAULT_AUTHENTICATION_0 [@"Loopnova" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_1 [@"Mogotrevo" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_2 [@"Ethosien" dataUsingEncoding:NSUTF8StringEncoding]

// TODO: DH - replace 'Hioffpo' salt with one >= 8 bytes long as per RFC
#define SALT_DERIVE_VAULT_AUTHENTICATION_3 [@"Hioffpo" dataUsingEncoding:NSUTF8StringEncoding]
#define SALT_DERIVE_VAULT_AUTHENTICATION_4 [@"Yokovich" dataUsingEncoding:NSUTF8StringEncoding]

//static uint8_t zeroBytes32[32] = {0};

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

    return [_masterKey copy];
}


- (void)generateNewKeys
{
    _isInitialized = YES;

//    _masterKey = [NSData dataWithRandomBytesOfLength:32];
    _masterKey = [@"12345678901234567890123456789012" dataUsingEncoding:NSUTF8StringEncoding];
    [self deriveKeys];
}

- (void)deriveKeys
{
    NSData *vaultMasterKey = [QredoVaultCrypto vaultMasterKeyWithUserMasterKey:_masterKey];
    self.systemVaultKeys = [[QredoVaultKeys alloc] initWithVaultKey:[QredoVaultCrypto systemVaultKeyWithVaultMasterKey:vaultMasterKey]];
    self.defaultVaultKeys = [[QredoVaultKeys alloc] initWithVaultKey:[QredoVaultCrypto userVaultKeyWithVaultMasterKey:vaultMasterKey]];
}

@end
