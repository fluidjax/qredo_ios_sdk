/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

// TODO: DH - check which header files are needed
#import "QredoRendezvousRsa2048PemHelper.h"
#import "QredoClient.h"
#import "CryptoImpl.h"
#import "QredoCrypto.h"
#import "QredoCertificateUtils.h"
#import "QredoLogging.h"
#import "QredoAuthenticatedRendezvousTag.h"
#import "QredoRsaPublicKey.h"
#import "NSData+QredoRandomData.h"

@implementation QredoAbstractRendezvousRsa2048PemHelper

// TODO: DH - confirm the salt length used for RSA 2048 authenticated rendezvous
const NSInteger kRsa2048AuthenticatedRendezvousSaltLength = 8;
//static const NSUInteger kX509AuthenticatedRendezvousEmptySignatureLength = 256;

// TODO: DH - confirm the minimum length of RSA 2048 authentication tag (i.e. single RSA 2048 bit Public key as PEM)
static const NSUInteger kMinRsa2048AuthenticationTagLength = 1;

static const NSUInteger kRsa2048KeyLengthBits = 2048;
static const NSUInteger kRandomKeyIdentifierLength = 32;

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeRsa2048Pem;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    // Empty Signature is just a placeholder of the correct size for a real signature.
    NSData *emptySignatureData = [NSMutableData dataWithLength:kRsa2048AuthenticatedRendezvousSaltLength];
    return [QredoRendezvousAuthSignature rendezvousAuthRSA2048_PEMWithSignature:emptySignatureData];
}

//- (SecKeyRef)getPublicKeyRefFromX509AuthenticationTag:(NSString *)authenticationTag error:(NSError **)error
//{
//    NSArray *certificateChainRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:authenticationTag];
//    
//    NSArray *trustedRootRefs = [self.cryptoImpl getTrustedRootRefs];
//    SecKeyRef publicKeyRef = [QredoCertificateUtils validateCertificateChain:certificateChainRefs
//                                                         rootCertificateRefs:trustedRootRefs];
//    if (!publicKeyRef) {
//        LogError(@"Authentication tag (certificate chain) did not validate correctly. Authentication tag: %@", authenticationTag);
//        if (error) {
//            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
//        }
//    }
//    
//    return publicKeyRef;
//}

- (SecKeyRef)publicKeyRefFromAuthenticationTag:(NSString *)authenticationTag error:(NSError **)error
{
    // Public key is PEM encoded RSA key (2048 bits)
    SecKeyRef publicKeyRef = nil;
    
    // TODO: DH - get public key from authentication tag
    
//    // Verify Key is the authentication tag, once Base58 decoded
//    NSData *vkData = [QredoBase58 decodeData:authenticationTag];
//    if (!vkData || vkData.length == 0) {
//        LogError(@"Base58 decode of authentication tag was nil or 0 length. Authentication Tag: '%@'", authenticationTag);
//        if (error) {
//            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
//        }
//        return nil;
//    }
//    
//    QredoED25519VerifyKey *vk = [self.cryptoImpl qredoED25519VerifyKeyWithData:vkData error:error];
//    if (!vk) {
//        LogError(@"Nil Ed25519 verify key returned for authentication tag: '%@'.", authenticationTag);
//        if (error) {
//            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
//        }
//        return nil;
//    }
    
    return publicKeyRef;
}

@end


@interface QredoRendezvousRsa2048PemCreateHelper ()

@property (nonatomic, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@property (nonatomic, copy) NSString *publicKeyIdentifier;
@property (nonatomic, copy) NSString *privateKeyIdentifier;
@property (nonatomic, assign) SecKeyRef publicKeyRef;
@property (nonatomic, assign) SecKeyRef privateKeyRef;
@property (nonatomic, copy) signDataBlock signingHandler;

@end

@implementation QredoRendezvousRsa2048PemCreateHelper

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
        
        _authenticatedRendezvousTag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:error];
        if (!_authenticatedRendezvousTag || (error && *error)) {
            LogError(@"Failed to split up full tag successfully.");
            return nil;
        }
        
        // Generate a random ID to temporarily (for life of this object) 'name' the keys.
        NSString *keyId = [QredoLogging hexRepresentationOfNSData:[NSData dataWithRandomBytesOfLength:kRandomKeyIdentifierLength]];
        
        // Don't populate the private identifier unless we generated the key ourselves
        _publicKeyIdentifier = [keyId stringByAppendingString:@".public"];

        if ([_authenticatedRendezvousTag.authenticationTag isEqualToString:@""]) {
            // No authentication tag provided, so need to generate own keys and signing handler must be nil
            if (signingHandler) {
                LogError(@"Provided a signing handler (so external keys to be used), but authentication tag (public key) also provided.");
                if (error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorSignatureHandlerIncorrectlyProvided, nil);
                }
                return nil;
            }
            
            _privateKeyIdentifier = [keyId stringByAppendingString:@".private"];

            // Generate some one-time-use RSA 2048-bit keys (so do not persist), and the authentication tag
            BOOL success = [QredoCrypto generateRsaKeyPairOfLength:kRsa2048KeyLengthBits
                                               publicKeyIdentifier:_publicKeyIdentifier
                                              privateKeyIdentifier:_privateKeyIdentifier
                                            persistInAppleKeychain:NO];
            if (!success) {
                LogError(@"Failed to generate keypair for identifiers: '%@' and '%@'", _publicKeyIdentifier, _privateKeyIdentifier);
                if (error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorKeyGenerationFailed, nil);
                }
                return nil;
            }

            // TODO: DH - check whether returning the key ref would work with non-persisted keys?
            
            
            _privateKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:_privateKeyIdentifier];
            if (!_privateKeyRef) {
                LogError(@"Nil SecKeyRef returned for private key ID: %@", _privateKeyIdentifier);
                if (error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorKeyProcessingFailed, nil);
                }
                return nil;
            }
            
            // Get the PEM encoded public key data for use as the authentication tag
            NSString *authenticationTag = [QredoCertificateUtils convertKeyIdentifierToPemKey:_publicKeyIdentifier];

            // Re-generate the Authenticated Rendezvous Tag now we have generated keys
            _authenticatedRendezvousTag = [[QredoAuthenticatedRendezvousTag alloc] initWithPrefix:_authenticatedRendezvousTag.prefix authenticationTag:authenticationTag error:error];
        }
        else {
            
            // Using externally provided keys, so must validate those keys
            
            // Get the DER formatted public key from the PEM string
            NSData *publicKeyData = [QredoCertificateUtils convertPemPublicKeyToDer:_authenticatedRendezvousTag.authenticationTag];
            if (!publicKeyData) {
                if (error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
                }
                LogError(@"Nil public key was returned by publicKeyRefFromAuthenticationTag. Authentication Tag: '%@'",
                         _authenticatedRendezvousTag.authenticationTag);
                return nil;
            }
            
            // TODO: DH - Validate the data is 2048 bits (may find importKeyData does that - write a test to confirm whether incorrect key length arg is detected against NSData provided)
            
            // Import the DER encoded public key data into Apple Keychain (allows us to get the SecKeyRef for signing/verify)
            BOOL success = [QredoCrypto importKeyData:publicKeyData
                                        keyLengthBits:kRsa2048KeyLengthBits
                                        keyIdentifier:_publicKeyIdentifier
                                            isPrivate:NO
                               persistInAppleKeychain:NO];
            if (!success) {
                if (error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
                }
                LogError(@"Could not import DER data. Authentication Tag: '%@'",
                         _authenticatedRendezvousTag.authenticationTag);
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
            
            _signingHandler = signingHandler;
        }
        
        _publicKeyRef = [QredoCrypto getRsaSecKeyReferenceForIdentifier:_publicKeyIdentifier];
        if (!_publicKeyRef) {
            LogError(@"Nil SecKeyRef returned for public key ID: %@", _publicKeyIdentifier);
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorKeyProcessingFailed, nil);
            }
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
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingDataToSign, nil);
        }
        return nil;
    }
    
    NSData *signature = self.signingHandler(data, self.type);
    if (!signature) {
        LogError(@"Nil signature was returned by signing handler.");
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorBadSignature, nil);
        }
        return nil;
    }
    
    // As we did not generate the signature, no guarantee it's valid. Verify it before continuing
    BOOL signatureValid = [QredoCrypto rsaPssVerifySignature:signature
                                                  forMessage:data
                                                  saltLength:kRsa2048AuthenticatedRendezvousSaltLength
                                                      keyRef:self.publicKeyRef];
    
    if (!signatureValid) {
        LogError(@"Signing handler returned signature which didn't validate. Data: %@. Signature: %@", data, signature);
        return nil;
    }
    else {
        return [QredoRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:signature];
    }
}

@end


@interface QredoRendezvousRsa2048PemRespondHelper ()

@property (nonatomic, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@property (nonatomic, assign) SecKeyRef publicKeyRef;

@end

@implementation QredoRendezvousRsa2048PemRespondHelper

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
        
        _authenticatedRendezvousTag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:error];
        if (!_authenticatedRendezvousTag || (error && *error)) {
            LogError(@"Failed to split up full tag successfully.");
            return nil;
        }
        
        if (_authenticatedRendezvousTag.authenticationTag.length < kMinRsa2048AuthenticationTagLength) {
            LogError(@"Invalid authentication tag length: %ld. Minimum tag length for X509 authenticated tag: %ld",
                     fullTag.length,
                     kMinRsa2048AuthenticationTagLength);
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
            }
            return nil;
        }
        
        _publicKeyRef = [self publicKeyRefFromAuthenticationTag:_authenticatedRendezvousTag.authenticationTag error:error];
        if (!_publicKeyRef || (error && *error)) {
            LogError(@"Failed to validate/get public key from authentication tag.");
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
    return self.authenticatedRendezvousTag.fullTag;
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
        signatureData = nil;
    } RSA2048_PEM:^(NSData *signature) {
        signatureData = signature;
    } RSA4096_PEM:^(NSData *signature) {
    } other:^{
        signatureData = nil;
    }];
    
    if ([signatureData length] < 1) {
        return NO;
    }
    
    BOOL signatureIsValid = [QredoCrypto rsaPssVerifySignature:signatureData forMessage:rendezvousData saltLength:kRsa2048AuthenticatedRendezvousSaltLength keyRef:_publicKeyRef];
    
    LogDebug(@"RSA 2048 PEM Authenticated Rendezvous signature valid: %@", signatureIsValid ? @"YES" : @"NO");
    
    return signatureIsValid;
}

@end