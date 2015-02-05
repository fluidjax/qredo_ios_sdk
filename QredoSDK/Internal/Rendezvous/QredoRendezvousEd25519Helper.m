/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousEd25519Helper.h"
#import "QredoClient.h"
#import "CryptoImpl.h"
#import "QredoBase58.h"
#import "QredoLogging.h"

@implementation QredoAbstractRendezvousEd25519Helper

// Minimum length of Ed25519 authenticated tag when creating = 1 (no prefix, just @)
static const NSUInteger kMinEd25519AuthenticatedRendezvousCreateTagLength = 1;

// TODO: DH - confirm the minimum length of ED25519 authenticated tag (base58 key)
static const NSUInteger kMinEd25519AuthenticatedRendezvousRespondTagLength = 1;

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeEd25519;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    NSData *emptySignatureData = [self.cryptoImpl qredoED25519EmptySignature];
    return [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:emptySignatureData];
}

- (NSString *)stripPrefixFromEd25519FullTag:(NSString *)fullTag creating:(BOOL)creating error:(NSError **)error
{
    if (!fullTag) {
        LogError(@"Nil full tag provided.");
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
        }
        return nil;
    }
    
    // TODO: DH - change to a single class to deal with the prefix and authentication tag parts, including validation
    // Different minimum tag lengths when creating or responding (creating can generate own keys)
    if (creating) {
        // When creating, can either provide no key, or a key. Different length requirements on both.
        if (fullTag.length < kMinEd25519AuthenticatedRendezvousCreateTagLength) {
            LogError(@"Invalid full tag length: %ld. Minimum tag length to create ED25519 Authenticated Rendezvous: %ld",
                     fullTag.length,
                     kMinEd25519AuthenticatedRendezvousCreateTagLength);
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
            }
            return nil;
        }
    }
    else {
        if (fullTag.length < kMinEd25519AuthenticatedRendezvousRespondTagLength) {
            LogError(@"Invalid full tag length: %ld. Minimum tag length to respond ED25519 Authenticated Rendezvous: %ld",
                     fullTag.length,
                     kMinEd25519AuthenticatedRendezvousRespondTagLength);
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
            }
            return nil;
        }
    }
    
    
    return [self stripPrefixFromFullTag:fullTag error:error];
}

- (QredoED25519VerifyKey *)verifyKeyFromAuthenticationTag:(NSString *)authenticationTag error:(NSError **)error
{
    // Verify Key is the authentication tag, once Base58 decoded
    NSData *vkData = [QredoBase58 decodeData:authenticationTag];
    if (!vkData || vkData.length == 0) {
        LogError(@"Base58 decode of authentication tag was nil or 0 length. Authentication Tag: '%@'", authenticationTag);
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
        }
        return nil;
    }
    
    QredoED25519VerifyKey *vk = [self.cryptoImpl qredoED25519VerifyKeyWithData:vkData error:error];
    if (*error) {
        LogError(@"Getting Ed25519 key from authentication data returned error: %@", *error);
        return nil;
    }
    else if (!vk) {
        LogError(@"Nil, Ed25519 verify key returned for authentication tag: '%@'.", authenticationTag);
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        }
        return nil;
    }
    
    return vk;
}

@end


@interface QredoRendezvousEd25519CreateHelper () {
    QredoED25519SigningKey *_sk;
}
@property (nonatomic, copy) NSString *fullTag;
//@property (nonatomic, copy) NSString *authenticationTag;
@property (nonatomic, copy) signDataBlock signingHandler;
@end

@implementation QredoRendezvousEd25519CreateHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        
        if (!fullTag) {
            LogError(@"Full tag is nil.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
            }
            return nil;
        }
        
        NSString *prefix = [self getPrefixFromFullTag:fullTag error:error];
        if (!prefix) {
            LogError(@"getPrefixFromFullTag returned nil prefix.");
            if (error && !*error) {
                // Error wasn't already set
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
            }
            return nil;
        }
        
        NSString *authenticationTag = [self stripPrefixFromEd25519FullTag:fullTag creating:YES error:error];
        if (error && *error) {
            LogError(@"stripPrefixFromEd25519FullTag returned error: %@", *error);
            return nil;
        }
        
        if ([authenticationTag isEqualToString:@""]) {
            // No authentication tag provided, so need to generate own keys and signing handler must be nil
            if (signingHandler) {
                LogError(@"Provided a signing handler (so external keys to be used), but authentication tag (public key) also provided.");
                if (error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorSignatureHandlerIncorrectlyProvided, nil);
                }
                return nil;
            }
            
            // Generate some one-time-use ED25519 keys, and the authentication tag
            _sk = [self.cryptoImpl qredoED25519SigningKey];
            authenticationTag = [QredoBase58 encodeData:_sk.verifyKey.data];
            
            // Generate the full tag now, with the newly generated key
            if (![prefix isEqualToString:@""]) {
                // There is a prefix
                _fullTag = [NSString stringWithFormat:@"%@@%@", prefix, authenticationTag];
            }
            else {
                // No prefix, so full tag is just authentication tag (no preceeding @)
                _fullTag = authenticationTag;
            }
        }
        else {

            // Using externally provided keys, so must validate those keys
            QredoED25519VerifyKey *verifyKey = [self verifyKeyFromAuthenticationTag:authenticationTag error:error];
            if (!verifyKey) {
                // Only set the error, if not already set
                if (!*error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
                }
                LogError(@"Nil verify key was returned by verifyKeyFromAuthenticationTag. Authentication Tag: '%@'. Error: %@", authenticationTag, *error);
                return nil;
            }
            
            // Using externally provided keys, so signing handler must not be nil
            if (!signingHandler) {
                LogError(@"Provided an authentication tag (public key) but signing handler is nil.");
                if (error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorSignatureHandlerMissing, nil);
                }
                return nil;
            }
            
            _fullTag = fullTag;
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
    // We either used the provided full tag, or pre-populated it when generating the keys
    return self.fullTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    return [super emptySignature];
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    if (!data) {
        LogError(@"Data to sign is nil.");
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingDataToSign, nil);
        }
        return nil;
    }
    
    NSData *signature = nil;
    
    if (!_sk) {
        // No signing key generated, so using external signing handler
        signature = self.signingHandler(data);
        if (!signature) {
            LogError(@"Nil signature was returned by signing handler.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorBadSignature, nil);
            }
            return nil;
        }
        
        // As we did not generate the signature, no guarantee it's valid. Verify it before continuing
        BOOL signatureValid = [self.cryptoImpl qredoED25519VerifySignature:signature
                                                                 ofMessage:data
                                                                 verifyKey:_sk.verifyKey
                                                                     error:error];
        
        if (!signatureValid) {
            LogError(@"Signing handler returned signature which didn't validate. Data: %@. Signature: %@", data, signature);
            return nil;
        }
        else {
            return [QredoRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:signature];
        }
    }
    else {
        // Internally generated keys, so sign inside SDK
        signature = [self.cryptoImpl qredoED25519SignMessage:data withKey:_sk error:error];
        if (!signature) {
            // Only set the error, if not already set
            if (!*error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorBadSignature, nil);
            }
            LogError(@"Nil signature was returned by qredoED25519SignMessage. Error: %@", *error);
            return nil;
        }
    }
    
    return [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:signature];
}

@end


@interface QredoRendezvousEd25519RespondHelper () {
    QredoED25519VerifyKey *_vk;
}
@property (nonatomic, copy) NSString *fullTag;
@end

@implementation QredoRendezvousEd25519RespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        if (!fullTag) {
            LogError(@"Full tag is nil.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
            }
            return nil;
        }
        
        if (fullTag.length < 1) {
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
            }
            return nil;
        }
        
        NSString *authenticationTag = [self stripPrefixFromEd25519FullTag:fullTag creating:NO error:error];
        if (error && *error) {
            LogError(@"stripPrefixFromEd25519FullTag returned error: %@", *error);
            return nil;
        }
        
        _vk = [self verifyKeyFromAuthenticationTag:authenticationTag error:error];
        if (!_vk) {
            // Only set the error, if not already set
            if (!*error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
            }
            LogError(@"Nil verify key was returned by verifyKeyFromAuthenticationTag. Authentication Tag: '%@'. Error: %@", authenticationTag, *error);
            return nil;
        }
        
        _fullTag = fullTag;
    }
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    return [super type];
}

- (NSString *)tag
{
    return self.fullTag;
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
    
    if ([signatureData length] < 1) {
        return NO;
    }
    
    return [self.cryptoImpl qredoED25519VerifySignature:signatureData ofMessage:rendezvousData verifyKey:_vk error:error];
}

@end



