/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoSigner.h"

#import "CryptoImplV1.h"

#import "QredoCrypto.h"
#import "QredoErrorCodes.h"

static const int PSS_SALT_LENGTH_IN_BYTES = 32;

@implementation QredoED25519Singer
{
    QredoED25519SigningKey *_signingKey;
}

- (instancetype)initWithSigningKey:(QredoED25519SigningKey *)signingKey
{
    NSAssert(signingKey, @"The signing key must be provided.");
    self = [super init];

    if (!self) return nil;

    _signingKey = signingKey;

    return self;
}

- (NSData *)signData:(NSData *)data error:(NSError **)error
{
    return [[CryptoImplV1 sharedInstance] qredoED25519SignMessage:data withKey:_signingKey error:error];
}

@end

@implementation QredoRSASinger
{
    SecKeyRef _keyRef;
}

- (instancetype)initWithRSAKeyRef:(SecKeyRef)keyRef
{
    NSAssert(keyRef, @"The key reference must be provided.");
    self = [super init];

    if (!self) return nil;

    _keyRef = keyRef;

    return self;
}

- (NSData *)signData:(NSData *)data error:(NSError **)error
{
    @try {
        return [QredoCrypto rsaPssSignMessage:data saltLength:PSS_SALT_LENGTH_IN_BYTES keyRef:_keyRef];
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:@{NSLocalizedDescriptionKey: exception.description}];
        }
        return nil;
    }
}

@end