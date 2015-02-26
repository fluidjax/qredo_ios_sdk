/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousRsaPemCommonHelper.h"
#import "QredoClient.h"
#import "QredoCrypto.h"
#import "QredoCertificateUtils.h"
#import "QredoLogging.h"
#import "NSData+QredoRandomData.h"

@implementation QredoAbstractRendezvousRsaPemHelper

// Salt length for RSA PSS signing of authenticated rendezvous (related to hash length, we use SHA256)
const NSInteger kRsaAuthenticatedRendezvousSaltLength = 32;

static const NSUInteger kRandomKeyIdentifierLength = 32;

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto type:(QredoRendezvousAuthenticationType)type keySizeBits:(NSUInteger)keySizeBits minimumAuthenticationTagLength:(NSUInteger)minimumAuthenticationTagLength
{
    self = [super initWithCrypto:crypto];
    if (self) {
        _type = type;
        _keySizeBits = keySizeBits;
        _minimumAuthenticationTagLength = minimumAuthenticationTagLength;
    }
    return self;
}

- (NSData *)emptySignatureData
{
    // Empty Signature is just a placeholder of the correct size for a real signature, which for RSA is equal to key size (in bits)
    NSData *emptySignatureData = [NSMutableData dataWithLength:self.keySizeBits / 8];
    return emptySignatureData;
}

- (SecKeyRef)publicKeyRefFromAuthenticationTag:(NSString *)authenticationTag publicKeyIdentifier:(NSString *)publicKeyIdentifier error:(NSError **)error
{
    if (!authenticationTag) {
        LogError(@"Authentication tag is nil.");
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagMissing, nil);
        return nil;
    }
    
    if (!publicKeyIdentifier) {
        LogError(@"Public key identifier is nil.");
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorPublicKeyIdentifierMissing, nil);
        return nil;
    }
    
    // Public key is PEM encoded RSA key
    SecKeyRef publicKeyRef = nil;
    
    // Convert the Authentication Tag (PEM encoded RSA key) to DER data (PKCS#1 format)
    // Import the DER data into Keychain and get a SecKeyRef out, which gets returned.
    
    // TODO: DH - How to validate the key is expected length? Apple doesn't expose that info?
    
    // Get the DER formatted public key from the PEM string
    // Note: This only converts from PEM to DER - doesn't validate which DER format it is.
    NSData *publicKeyData = [QredoCertificateUtils convertPemPublicKeyToDer:authenticationTag];
    if (!publicKeyData) {
        LogError(@"Nil public key was returned by convertPemPublicKeyToDer. Authentication Tag: '%@'", authenticationTag);
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        return nil;
    }
    
    // Handle possibility of getting X.509 DER encoded Public Key Data - we need it in PKCS#1 format
    NSData *publicKeyPkcs1Data = [QredoCertificateUtils getPkcs1PublicKeyDataFromUnknownPublicKeyData:publicKeyData];
    
    // Import the PKCS1 DER encoded public key data into Apple Keychain (gets us the SecKeyRef for signing/verify)
    publicKeyRef = [QredoCrypto importPkcs1KeyData:publicKeyPkcs1Data
                                     keyLengthBits:self.keySizeBits
                                     keyIdentifier:publicKeyIdentifier
                                         isPrivate:NO];
    if (!publicKeyRef) {
        LogError(@"Could not import Public Key data (must be PKCS#1 'RSAPublicKey' format, not X.509 'SubjectPublicKeyInfo' format). Authentication Tag: '%@'", authenticationTag);
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        return nil;
    }
    
    return publicKeyRef;
}

@end


@interface QredoRendezvousRsaPemCreateHelper ()

@property (nonatomic, copy) NSString *publicKeyIdentifier;
@property (nonatomic, copy) NSString *privateKeyIdentifier;
@property (nonatomic, strong) QredoSecKeyRefPair *keyPairRef; // Used for Internally generated keys
@property (nonatomic, assign) SecKeyRef publicKeyRef; // Used for Externally generated keys
@property (nonatomic, copy) signDataBlock signingHandler;

@end

@implementation QredoRendezvousRsaPemCreateHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler type:(QredoRendezvousAuthenticationType)type keySizeBits:(NSUInteger)keySizeBits minimumAuthenticationTagLength:(NSUInteger)minimumAuthenticationTagLength error:(NSError **)error
{
    self = [super initWithCrypto:crypto
                            type:type
                     keySizeBits:keySizeBits
  minimumAuthenticationTagLength:minimumAuthenticationTagLength];
    if (self) {
        
        if (!fullTag) {
            LogError(@"Full tag is nil.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        if (fullTag.length < 1) {
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
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
                updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorSignatureHandlerIncorrectlyProvided, nil);
                return nil;
            }
            
            _privateKeyIdentifier = [keyId stringByAppendingString:@".private"];
            
            // Generate some one-time-use RSA keys. However, to be able to get the key data (needed to generate the public key PEM for authentication tag) the key must be persisted. So must delete the keys later.
            _keyPairRef = [QredoCrypto generateRsaKeyPairOfLength:self.keySizeBits
                                              publicKeyIdentifier:_publicKeyIdentifier
                                             privateKeyIdentifier:_privateKeyIdentifier
                                           persistInAppleKeychain:YES];
            if (!_keyPairRef) {
                LogError(@"Failed to generate keypair for identifiers: '%@' and '%@'", _publicKeyIdentifier, _privateKeyIdentifier);
                updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorKeyGenerationFailed, nil);
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
                updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorSignatureHandlerMissing, nil);
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

- (NSData *)signatureForData:(NSData *)data error:(NSError **)error
{
    if (!data) {
        LogError(@"Data to sign is nil.");
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingDataToSign, nil);
        return nil;
    }
    
    // TODO: DH - Can signature length be used to validate key lengths? Bit late though after creating the helper

    NSData *signature = nil;
    
    if (self.keyPairRef) {
        // Internally generated keys, we sign it ourselves
        signature = [QredoCrypto rsaPssSignMessage:data
                                        saltLength:kRsaAuthenticatedRendezvousSaltLength
                                            keyRef:self.keyPairRef.privateKeyRef];
        if (!signature) {
            LogError(@"Nil signature was returned by rsaPssSignMessage.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorBadSignature, nil);
            return nil;
        }
    }
    else {
        // Externally generated keys, so use the signing handler
        signature = self.signingHandler(data, self.type);
        if (!signature) {
            LogError(@"Nil signature was returned by signing handler.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorBadSignature, nil);
            return nil;
        }
        
        // As we did not generate the signature, no guarantee it's valid. Verify it before continuing
        BOOL signatureValid = [QredoCrypto rsaPssVerifySignature:signature
                                                      forMessage:data
                                                      saltLength:kRsaAuthenticatedRendezvousSaltLength
                                                          keyRef:self.publicKeyRef];
        
        if (!signatureValid) {
            LogError(@"Signing handler returned signature which didn't validate. Data: %@. Signature: %@", data, signature);
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorBadSignature, nil);
            return nil;
        }
    }
    
    return signature;
}

@end


@interface QredoRendezvousRsaPemRespondHelper ()

@property (nonatomic, copy) NSString *publicKeyIdentifier;
@property (nonatomic, assign) SecKeyRef publicKeyRef;

@end

@implementation QredoRendezvousRsaPemRespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto type:(QredoRendezvousAuthenticationType)type keySizeBits:(NSUInteger)keySizeBits minimumAuthenticationTagLength:(NSUInteger)minimumAuthenticationTagLength error:(NSError **)error
{
    self = [super initWithCrypto:crypto
                            type:type
                     keySizeBits:keySizeBits
  minimumAuthenticationTagLength:minimumAuthenticationTagLength];
    if (self) {
        if (!fullTag) {
            LogError(@"Full tag is nil.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        if (fullTag.length < 1) {
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        _authenticatedRendezvousTag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:error];
        if (!_authenticatedRendezvousTag || (error && *error)) {
            LogError(@"Failed to split up full tag successfully.");
            return nil;
        }
        
        if (_authenticatedRendezvousTag.authenticationTag.length < super.minimumAuthenticationTagLength) {
            LogError(@"Invalid authentication tag length: %ld. Minimum tag length for %ld-bit RSA authenticated tag: %ld",
                     fullTag.length,
                     super.keySizeBits,
                     super.minimumAuthenticationTagLength);
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
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

- (BOOL)isSignatureDataValid:(NSData *)signatureData rendezvousData:(NSData *)rendezvousData
{
    if (!signatureData) {
        return NO;
    }
    
    if (signatureData.length < 1) {
        return NO;
    }
    
    if (!rendezvousData) {
        return NO;
    }
    
    // TODO: DH - Can signature length be used to validate key lengths? Bit late though after creating the helper

    BOOL signatureIsValid = [QredoCrypto rsaPssVerifySignature:signatureData forMessage:rendezvousData saltLength:kRsaAuthenticatedRendezvousSaltLength keyRef:_publicKeyRef];
    
    LogDebug(@"RSA %ld-bit PEM Authenticated Rendezvous signature valid: %@",
             self.keySizeBits,
             signatureIsValid ? @"YES" : @"NO");
    
    return signatureIsValid;
}

@end