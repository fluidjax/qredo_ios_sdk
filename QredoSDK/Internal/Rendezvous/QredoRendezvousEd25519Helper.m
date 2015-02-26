/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousEd25519Helper.h"
#import "QredoClient.h"
#import "CryptoImpl.h"
#import "QredoBase58.h"
#import "QredoLogging.h"
#import "QredoAuthenticatedRendezvousTag.h"

@implementation QredoAbstractRendezvousEd25519Helper

// Ed25519 verify key is 32 bytes. Having tested base58 encoding of 32 bytes (10m encodings), will be between 42 and 44 bytes
static const NSUInteger kMinEd25519AuthenticationTagLength = 42;
static const NSUInteger kMaxEd25519AuthenticationTagLength = 44;

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeEd25519;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    NSData *emptySignatureData = [self.cryptoImpl qredoED25519EmptySignature];
    return [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:emptySignatureData];
}

- (QredoED25519VerifyKey *)verifyKeyFromAuthenticationTag:(NSString *)authenticationTag error:(NSError **)error
{
    // Verify Key is the authentication tag, once Base58 decoded
    NSData *vkData = [QredoBase58 decodeData:authenticationTag error:error];
    if (!vkData || vkData.length == 0) {
        LogError(@"Base58 decode of authentication tag was nil or 0 length. Authentication Tag: '%@'.", authenticationTag);
        if (error && *error) {
            LogError(@"Base58 decode returned NSError: %@", *error);
        }
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMalformedTag, nil);
        return nil;
    }
    
    QredoED25519VerifyKey *vk = [self.cryptoImpl qredoED25519VerifyKeyWithData:vkData error:error];
    if (!vk) {
        LogError(@"Nil Ed25519 verify key returned for authentication tag: '%@'.", authenticationTag);
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        return nil;
    }
    
    return vk;
}

@end


@interface QredoRendezvousEd25519CreateHelper ()

@property (nonatomic, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@property (nonatomic, strong) QredoED25519SigningKey *signingKey; // Only used for internally generated keys
@property (nonatomic, strong) QredoED25519VerifyKey *verifyKey; // Only used for externally generated keys
@property (nonatomic, copy) signDataBlock signingHandler;
@end

@implementation QredoRendezvousEd25519CreateHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        
        if (!fullTag) {
            LogError(@"Full tag is nil.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        _authenticatedRendezvousTag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:error];
        if (!_authenticatedRendezvousTag || (error && *error)) {
            LogError(@"Failed to split up full tag successfully.");
            return nil;
        }
        
        if ([_authenticatedRendezvousTag.authenticationTag isEqualToString:@""]) {
            // No authentication tag provided, so need to generate own keys and signing handler must be nil
            if (signingHandler) {
                LogError(@"Provided a signing handler (so external keys to be used), but authentication tag (public key) also provided.");
                updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorSignatureHandlerIncorrectlyProvided, nil);
                return nil;
            }
            
            // Generate some one-time-use ED25519 keys, and the authentication tag
            _signingKey = [self.cryptoImpl qredoED25519SigningKey];
            NSString *authenticationTag = [QredoBase58 encodeData:_signingKey.verifyKey.data];
            
            // Re-generate the Authenticated Rendezvous Tag now we have generated keys
            _authenticatedRendezvousTag = [[QredoAuthenticatedRendezvousTag alloc] initWithPrefix:_authenticatedRendezvousTag.prefix authenticationTag:authenticationTag error:error];
        }
        else {

            // Using externally provided keys, so must validate the authentication tag is valid key
            _verifyKey = [self verifyKeyFromAuthenticationTag:_authenticatedRendezvousTag.authenticationTag error:error];
            if (!_verifyKey) {
                // Only set the error, if not already set
                if (error && !*error) {
                    updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
                }
                LogError(@"Nil verify key was returned by verifyKeyFromAuthenticationTag. Authentication Tag: '%@'",
                         _authenticatedRendezvousTag.authenticationTag);
                return nil;
            }
            
            // Using externally provided keys, so signing handler must not be nil
            if (!signingHandler) {
                LogError(@"Provided an authentication tag (public key) but signing handler is nil.");
                updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorSignatureHandlerMissing, nil);
                return nil;
            }
            
            _signingHandler = signingHandler;
        }
    }
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    return [super type];
}

- (NSString *)tag
{
    return self.authenticatedRendezvousTag.fullTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    return [super emptySignature];
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    if (!data) {
        LogError(@"Data to sign is nil.");
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingDataToSign, nil);
        return nil;
    }
    
    NSData *signature = nil;
    
    if (!self.signingKey) {
        // No signing key generated, so using external signing handler
        signature = self.signingHandler(data, self.type);
        if (!signature) {
            LogError(@"Nil signature was returned by signing handler.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorBadSignature, nil);
            return nil;
        }
        
        // As we did not generate the signature, no guarantee it's valid. Verify it before continuing
        BOOL signatureValid = [self.cryptoImpl qredoED25519VerifySignature:signature
                                                                 ofMessage:data
                                                                 verifyKey:self.verifyKey
                                                                     error:error];
        
        if (!signatureValid) {
            LogError(@"Signing handler returned signature which didn't validate. Data: %@. Signature: %@", data, signature);
            return nil;
        }
        else {
            return [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:signature];
        }
    }
    else {
        // Internally generated keys, so sign inside SDK
        signature = [self.cryptoImpl qredoED25519SignMessage:data withKey:self.signingKey error:error];
        if (!signature) {
            // Only set the error, if not already set
            if (error && !*error) {
                updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorBadSignature, nil);
            }
            LogError(@"Nil signature was returned by qredoED25519SignMessage");
            return nil;
        }
    }
    
    return [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:signature];
}

@end


@interface QredoRendezvousEd25519RespondHelper () {
    QredoED25519VerifyKey *_vk;
}

@property (nonatomic, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@end

@implementation QredoRendezvousEd25519RespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        if (!fullTag) {
            LogError(@"Full tag is nil.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        _authenticatedRendezvousTag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:error];
        if (!_authenticatedRendezvousTag || (error && *error)) {
            LogError(@"Failed to split up full tag successfully.");
            return nil;
        }

        if (_authenticatedRendezvousTag.authenticationTag.length < kMinEd25519AuthenticationTagLength) {
            LogError(@"Invalid authentication tag length: %ld. Minimum tag length for Ed25519 authentication tag: %ld",
                     fullTag.length,
                     kMinEd25519AuthenticationTagLength);
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
            return nil;
        }

        if (_authenticatedRendezvousTag.authenticationTag.length > kMaxEd25519AuthenticationTagLength) {
            LogError(@"Invalid authentication tag length: %ld. Maximum tag length for Ed25519 authentication tag: %ld",
                     fullTag.length,
                     kMaxEd25519AuthenticationTagLength);
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
            return nil;
        }
        
        _vk = [self verifyKeyFromAuthenticationTag:_authenticatedRendezvousTag.authenticationTag error:error];
        if (!_vk) {
            // Only set the error, if not already set
            if (error && !*error) {
                updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMalformedTag, nil);
            }
            LogError(@"Nil verify key was returned by verifyKeyFromAuthenticationTag. Authentication Tag: '%@'",
                     _authenticatedRendezvousTag.authenticationTag);
            return nil;
        }
    }
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    return [super type];
}

- (NSString *)tag
{
    return self.authenticatedRendezvousTag.authenticationTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    return [super emptySignature];
}

- (BOOL)isValidSignature:(QredoRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error
{
    __block NSData *signatureData = nil;
    [signature ifX509_PEM:^(NSData *signature) {
        signatureData = nil;
    } X509_PEM_SELFISGNED:^(NSData *signature) {
        signatureData = nil;
    } ED25519:^(NSData *signature) {
        signatureData = signature;
    } RSA2048_PEM:^(NSData *signature) {
        signatureData = nil;
    } RSA4096_PEM:^(NSData *signature) {
        signatureData = nil;
    } other:^{
        signatureData = nil;
    }];
    
    BOOL signatureIsValid = [self.cryptoImpl qredoED25519VerifySignature:signatureData ofMessage:rendezvousData verifyKey:_vk error:error];
    LogDebug(@"Ed25519 Authenticated Rendezvous signature valid: %@", signatureIsValid ? @"YES" : @"NO");

    return signatureIsValid;
}

@end



