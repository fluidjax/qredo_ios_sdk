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
static const NSUInteger kRsa2048AuthenticatedRendezvousEmptySignatureLength = 256;

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
    NSData *emptySignatureData = [NSMutableData dataWithLength:kRsa2048AuthenticatedRendezvousEmptySignatureLength];
    return [QredoRendezvousAuthSignature rendezvousAuthRSA2048_PEMWithSignature:emptySignatureData];
}

- (SecKeyRef)publicKeyRefFromAuthenticationTag:(NSString *)authenticationTag publicKeyIdentifier:(NSString *)publicKeyIdentifier error:(NSError **)error
{
    // TODO: DH - Validate arguments (and use NSError)
    
    // Public key is PEM encoded RSA key (2048 bits)
    SecKeyRef publicKeyRef = nil;
    
    // Convert the Authentication Tag (PEM encoded RSA key) to DER data (PKCS#1 format)
    // Import the DER data into Keychain and get a SecKeyRef out, which gets returned.
    
    // TODO: DH - what happens if this method is called twice (why might it?) - could end up trying to create the key again, despite it already being in keychain, and thus failing? Import could fail if the key exists, or if the identifier already exists (unlikely for random?)

    // TODO: DH - should we attempt to detect X.509 'SubjectPublicKeyInfo' format and convert if necessary? What impact is there of that? Could we end up inadvertently changing the authentication tag (from X.509 'SubjectPublicKeyInfo' to PKCS#1 'RSAPublicKey' format?
    
    // TODO: DH - Validate the data is 2048 bits (may find importKeyData does that - write a test to confirm whether incorrect key length arg is detected against NSData provided)

    // Get the DER formatted public key from the PEM string
    // Note: This only converts from PEM to DER - doesn't validate which DER format it is.
    NSData *publicKeyData = [QredoCertificateUtils convertPemPublicKeyToDer:authenticationTag];
    if (!publicKeyData) {
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        }
        LogError(@"Nil public key was returned by convertPemPublicKeyToDer. Authentication Tag: '%@'", authenticationTag);
        return nil;
    }

    // Import the PKCS1 DER encoded public key data into Apple Keychain (gets us the SecKeyRef for signing/verify)
    publicKeyRef = [QredoCrypto importPkcs1KeyData:publicKeyData
                                     keyLengthBits:kRsa2048KeyLengthBits
                                     keyIdentifier:publicKeyIdentifier
                                         isPrivate:NO];
    if (!publicKeyRef) {
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        }
        LogError(@"Could not import Public Key data (must be PKCS#1 'RSAPublicKey' format, not X.509 'SubjectPublicKeyInfo' format). Authentication Tag: '%@'", authenticationTag);
        return nil;
    }
    
    return publicKeyRef;
}

@end


@interface QredoRendezvousRsa2048PemCreateHelper ()

@property (nonatomic, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@property (nonatomic, copy) NSString *publicKeyIdentifier;
@property (nonatomic, copy) NSString *privateKeyIdentifier;
@property (nonatomic, strong) QredoSecKeyRefPair *keyPairRef; // Used for Internally generated keys
@property (nonatomic, assign) SecKeyRef publicKeyRef; // Used for Externally generated keys
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

            // Generate some one-time-use RSA 2048-bit keys. However, to be able to get the key data (needed to generate the public key PEM for authentication tag) the key must be persisted. So must delete the keys later.
            _keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:kRsa2048KeyLengthBits
                                              publicKeyIdentifier:_publicKeyIdentifier
                                             privateKeyIdentifier:_privateKeyIdentifier
                                           persistInAppleKeychain:YES];
            if (!_keyPairRef) {
                LogError(@"Failed to generate keypair for identifiers: '%@' and '%@'", _publicKeyIdentifier, _privateKeyIdentifier);
                if (error) {
                    *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorKeyGenerationFailed, nil);
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
            _publicKeyRef = [self publicKeyRefFromAuthenticationTag:_authenticatedRendezvousTag.authenticationTag
                                                publicKeyIdentifier:_publicKeyIdentifier
                                                              error:error];
            if (!_publicKeyRef || (error && *error)) {
                LogError(@"Failed to validate/get public key from authentication tag: %@", _authenticatedRendezvousTag.authenticationTag);
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
    }
    return self;
}

- (void)dealloc
{
    // Delete any keys we generated or imported (as they should be transitory)
    if (_publicKeyIdentifier) {
        [QredoCrypto deleteKeyInAppleKeychainWithIdentifier:_publicKeyIdentifier];
    }
    
    if (_privateKeyIdentifier) {
        [QredoCrypto deleteKeyInAppleKeychainWithIdentifier:_privateKeyIdentifier];
    }
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

    NSData *signature = nil;
    
    if (self.keyPairRef) {
        // Internally generated keys, we sign it ourselves
        signature = [QredoCrypto rsaPssSignMessage:data
                                        saltLength:kRsa2048AuthenticatedRendezvousSaltLength
                                            keyRef:self.keyPairRef.privateKeyRef];
        if (!signature) {
            LogError(@"Nil signature was returned by rsaPssSignMessage.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorBadSignature, nil);
            }
            return nil;
        }
    }
    else {
        // Externally generated keys, so use the signing handler
        signature = self.signingHandler(data, self.type);
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
    }
    
    return [QredoRendezvousAuthSignature rendezvousAuthRSA2048_PEMWithSignature:signature];
}

@end


@interface QredoRendezvousRsa2048PemRespondHelper ()

@property (nonatomic, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@property (nonatomic, copy) NSString *publicKeyIdentifier;
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
        
        // Generate a random ID to temporarily (for life of this object) 'name' the keys.
        NSString *keyId = [QredoLogging hexRepresentationOfNSData:[NSData dataWithRandomBytesOfLength:kRandomKeyIdentifierLength]];
        _publicKeyIdentifier = [keyId stringByAppendingString:@".public"];

        _publicKeyRef = [self publicKeyRefFromAuthenticationTag:_authenticatedRendezvousTag.authenticationTag
                                            publicKeyIdentifier:_publicKeyIdentifier
                                                          error:error];
        if (!_publicKeyRef || (error && *error)) {
            LogError(@"Failed to validate/get public key from authentication tag: %@", _authenticatedRendezvousTag.authenticationTag);
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    
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