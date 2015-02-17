/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousRsa2048PemHelper.h"
#import "QredoClient.h"
#import "QredoCrypto.h"
#import "QredoCertificateUtils.h"
#import "QredoLogging.h"
#import "QredoAuthenticatedRendezvousTag.h"
#import "NSData+QredoRandomData.h"

@implementation QredoAbstractRendezvousRsa2048PemHelper

// Salt length for RSA PSS signing (related to hash length)
const NSInteger kRsa2048AuthenticatedRendezvousSaltLength = 32;
static const NSUInteger kRsa2048AuthenticatedRendezvousEmptySignatureLength = 256;

/*
 PEM RSA Public Key is a DER encoded public key with PEM wrapping.
 Actual DER encoding lengths could vary with PKCS#1/X.509, exponent size. Smallest
 would be PKCS#1 which is just 2 integers (2048 bit Modulus and minimum 1 byte Exponent) wrapped in a sequence,
 along with tag/length bytes.  X.509 format would add extra wrapping (approx 20 bytes extra BEFORE base64, meaning
 28 bytes after base64).
 
 PKCS#1 format calcs:
 Modulus = 256 bytes data + 3 bytes length (82 + xxxx length) + 1 byte INTEGER tag = 260 bytes.
 Exponent = 1 byte (min) data + 1 byte length + 1 byte INTEGER tag = 3 bytes.
 Sequence wrapper = Modulus + exponent lengths of data + 3 bytes length + 1 byte tag = 263 + 3 + 1 = 267 bytes.
 
 Base64 encodes 3 bytes as 4 bytes, 267 bytes = 356 bytes as base64 (ignoring any CR/CRLF line-wrapping breaks).
 
 PEM Key header = 27 bytes (inc trailing CR). PEM Key footer = 26 bytes (inc leading and trailling CR)
 
 Total min length of 2048 bit RSA key in PKCS#1 DER + PEM format = 409 bytes. 437 bytes for X.509 format.
*/
static const NSUInteger kMinRsa2048AuthenticationTagLength = 409;

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
    if (!authenticationTag) {
        LogError(@"Authentication tag is nil.");
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagMissing, nil);
        }
        return nil;
    }

    if (!publicKeyIdentifier) {
        LogError(@"Public key identifier is nil.");
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorPublicKeyIdentifierMissing, nil);
        }
        return nil;
    }

    // Public key is PEM encoded 2048-bit RSA key
    SecKeyRef publicKeyRef = nil;
    
    // Convert the Authentication Tag (PEM encoded RSA key) to DER data (PKCS#1 format)
    // Import the DER data into Keychain and get a SecKeyRef out, which gets returned.
    
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

    // Handle possibility of getting X.509 DER encoded Public Key Data - we need it in PKCS#1 format
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyData];

    // Import the PKCS1 DER encoded public key data into Apple Keychain (gets us the SecKeyRef for signing/verify)
    publicKeyRef = [QredoCrypto importPkcs1KeyData:publicKeyPkcs1Data
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
    // Delete any keys we generated or imported (as they should be transitory)
    if (_publicKeyIdentifier) {
        [QredoCrypto deleteKeyInAppleKeychainWithIdentifier:_publicKeyIdentifier];
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