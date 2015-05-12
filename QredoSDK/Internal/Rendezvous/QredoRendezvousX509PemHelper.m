/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousX509PemHelper.h"
#import "QredoClient.h"
#import "CryptoImpl.h"
#import "QredoCrypto.h"
#import "QredoCertificateUtils.h"
#import "QredoOpenSSLCertificateUtils.h"
#import "QredoLogging.h"
#import "QredoAuthenticatedRendezvousTag.h"
#import "NSData+QredoRandomData.h"

@interface QredoAbstractRendezvousX509PemHelper ()

@property (nonatomic) NSArray *trustedRootRefs;
@property (nonatomic) NSArray *trustedRootPems;
@property (nonatomic) NSArray *crlPems;

@end

@implementation QredoAbstractRendezvousX509PemHelper

// Salt length for RSA PSS signing (related to hash length)
const NSInteger kX509AuthenticatedRendezvousSaltLength = 32;
static const NSUInteger kX509AuthenticatedRendezvousEmptySignatureLength = 256;
static const NSUInteger kRandomKeyIdentifierLength = 32;

// TODO: DH - confirm the minimum length of X.509 authentication tag (i.e. single certificate with RSA 2048 bit Public key) - 2048 bit key must be at least 256 bytes long, unsure how much certificate wrapping adds
static const NSUInteger kMinX509AuthenticationTagLength = 256;

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto
               trustedRootPems:(NSArray *)trustedRootPems
                       crlPems:(NSArray *)crlPems
                         error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        
        // TrustedRootPems is required for X.509 PEM authenticated rendezvous
        _trustedRootPems = [[NSArray alloc] initWithArray:trustedRootPems copyItems:YES];
        
        // CrlPems is required for X.509 PEM authenticated rendezvous
        _crlPems = [[NSArray alloc] initWithArray:crlPems copyItems:YES];

        // Convert from PEM to SecCertificateRefs
        _trustedRootRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificatesArray:trustedRootPems];
        if (!_trustedRootRefs) {
            LogError(@"Could not convert trusted root PEM certificates into SecCertificateRefs.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorTrustedRootsInvalid, nil);
            return nil;
        }
    }
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeX509Pem;
}

- (QLFRendezvousAuthSignature *)emptySignature
{
    // Empty Signature is just a placeholder of the correct size for a real signature.
    NSData *emptySignatureData = [NSMutableData dataWithLength:kX509AuthenticatedRendezvousEmptySignatureLength];
    return [QLFRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:emptySignatureData];
}

- (SecKeyRef)getPublicKeyRefFromX509AuthenticationTag:(NSString *)authenticationTag
                                  publicKeyIdentifier:(NSString *)publicKeyIdentifier
                                                error:(NSError **)error
{
    NSArray *pemCertificateStrings = [QredoCertificateUtils splitPemCertificateChain:authenticationTag];
    if (!pemCertificateStrings) {
        LogError(@"PEM cert split returned nil array.");
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        return nil;
    }
    else if (pemCertificateStrings.count <= 0) {
        LogError(@"PEM cert split returned 0 certificates in array.");
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        return nil;
    }

    // Subject certificate is first PEM certificate found
    NSString *subjectPemCertificate = pemCertificateStrings[0];
    
    // Chain (intermediate) certificates are not always present
    NSArray *chainPemCertificates = [[NSArray alloc] init];

    if (pemCertificateStrings.count > 0) {
        // Make copy of chain certificates and then remove first entry (subject cert)
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:pemCertificateStrings];
        [tempArray removeObjectAtIndex:0];
        chainPemCertificates = [tempArray copy];
    }

    LogDebug(@"Certificate chain contains %lu intermediate certificates", (unsigned long)chainPemCertificates.count);
    
    // Validate chain using OpenSSL, but still need a SecKeyRef to allow use of existing RSA routines (e.g. signing)
    BOOL certificateIsValid = [QredoOpenSSLCertificateUtils validateCertificate:subjectPemCertificate
                                                           skipRevocationChecks:NO
                                                           chainPemCertificates:chainPemCertificates
                                                            rootPemCertificates:self.trustedRootPems
                                                                        pemCrls:self.crlPems
                                                                          error:error];
    
    SecKeyRef publicKeyRef = nil;
    if (certificateIsValid) {
        publicKeyRef = [QredoOpenSSLCertificateUtils getPublicKeyRefFromPemCertificate:subjectPemCertificate
                                                                   publicKeyIdentifier:publicKeyIdentifier
                                                                                 error:error];
        
        if (!publicKeyRef) {
            LogError(@"Could not import Public Key data from X.509 certificate. Authentication Tag: '%@'", authenticationTag);
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
            return nil;
        }
    }

    return publicKeyRef;
}

@end


@interface QredoRendezvousX509PemCreateHelper ()

// TODO: DH - look at moving these 2 properties into the QredoAbstractRendezvousX509PemHelper as common to Create and Response helpers
@property (nonatomic) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@property (nonatomic, copy) NSString *publicKeyIdentifier;
@property (nonatomic) SecKeyRef publicKeyRef;
@property (nonatomic, copy) signDataBlock signingHandler;

@end

@implementation QredoRendezvousX509PemCreateHelper

- (instancetype)initWithFullTag:(NSString *)fullTag
                         crypto:(id<CryptoImpl>)crypto
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                 signingHandler:(signDataBlock)signingHandler
                          error:(NSError **)error
{
    self = [super initWithCrypto:crypto trustedRootPems:trustedRootPems crlPems:crlPems error:error];
    if (self) {
        
        if (!fullTag) {
            LogError(@"Full tag is nil.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }

        if (fullTag.length < 1) {
            LogError(@"Full tag length is 0.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        // Signing handler is mandatory for X.509 certs (cannot generate these internally)
        if (!signingHandler)
        {
            LogError(@"No signing handler provided. Mandatory for X.509 authenticated rendezvous as can only use externally generated keys.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorSignatureHandlerMissing, nil);
            return nil;
        }
        
        _authenticatedRendezvousTag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:error];
        if (!_authenticatedRendezvousTag || (error && *error)) {
            LogError(@"Failed to split up full tag successfully.");
            return nil;
        }

        if ([_authenticatedRendezvousTag.authenticationTag isEqualToString:@""]) {
            LogError(@"Empty authentication tag. X.509 authenticated rendezcous can only use externally generated keys.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagMissing, nil);
            return nil;
        }
        
        // Generate a random ID to temporarily (for life of this object) 'name' the keys.
        NSString *keyId = [QredoLogging hexRepresentationOfNSData:[NSData dataWithRandomBytesOfLength:kRandomKeyIdentifierLength]];
        _publicKeyIdentifier = [keyId stringByAppendingString:@".public"];

        // Confirm that the authentication tag is a PEM certificate chain which validates correctly
        _publicKeyRef = [self getPublicKeyRefFromX509AuthenticationTag:_authenticatedRendezvousTag.authenticationTag
                                                   publicKeyIdentifier:_publicKeyIdentifier
                                                                 error:error];
        if (!_publicKeyRef || (error && *error)) {
            LogError(@"X.509 authentication tag is invalid.");
            return nil;
        }
        
        _signingHandler = signingHandler;
    }
    return self;
}

- (void)dealloc
{
    // Delete any keys we imported (as they should be transitory)
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

- (QLFRendezvousAuthSignature *)emptySignature
{
    return [super emptySignature];
}

- (QLFRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    if (!data) {
        LogError(@"Data to sign is nil.");
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingDataToSign, nil);
        return nil;
    }
    
    NSData *signature = self.signingHandler(data, self.type);
    if (!signature) {
        LogError(@"Nil signature was returned by signing handler.");
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorBadSignature, nil);
        return nil;
    }
    
    // As we did not generate the signature, no guarantee it's valid. Verify it before continuing
    BOOL signatureValid = [QredoCrypto rsaPssVerifySignature:signature
                                                  forMessage:data
                                                  saltLength:kX509AuthenticatedRendezvousSaltLength
                                                      keyRef:self.publicKeyRef];
    
    if (!signatureValid) {
        LogError(@"Signing handler returned signature which didn't validate. Data: %@. Signature: %@", data, signature);
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorBadSignature, nil);
        return nil;
    }
    else {
        return [QLFRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:signature];
    }
}

@end

@interface QredoRendezvousX509PemRespondHelper ()

// TODO: DH - look at moving these 2 properties into the QredoAbstractRendezvousX509PemHelper as common to Create and Response helpers
@property (nonatomic) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@property (nonatomic, copy) NSString *publicKeyIdentifier;
@property (nonatomic) SecKeyRef publicKeyRef;

@end

@implementation QredoRendezvousX509PemRespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag
                         crypto:(id<CryptoImpl>)crypto
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                          error:(NSError **)error
{
    self = [super initWithCrypto:crypto trustedRootPems:trustedRootPems crlPems:crlPems error:error];
    if (self) {
        
        if (!fullTag) {
            LogError(@"Full tag is nil.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        if (fullTag.length < 1) {
            LogError(@"Full tag length is 0.");
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
            return nil;
        }
        
        _authenticatedRendezvousTag = [[QredoAuthenticatedRendezvousTag alloc] initWithFullTag:fullTag error:error];
        if (!_authenticatedRendezvousTag || (error && *error)) {
            LogError(@"Failed to split up full tag successfully.");
            return nil;
        }
        
        if (_authenticatedRendezvousTag.authenticationTag.length < kMinX509AuthenticationTagLength) {
            LogError(@"Invalid authentication tag length: %lu. Minimum tag length for X509 authentication tag: %lu",
                     (unsigned long)fullTag.length,
                     (unsigned long)kMinX509AuthenticationTagLength);
            updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
            return nil;
        }
        
        // Generate a random ID to temporarily (for life of this object) 'name' the keys.
        NSString *keyId = [QredoLogging hexRepresentationOfNSData:[NSData dataWithRandomBytesOfLength:kRandomKeyIdentifierLength]];
        _publicKeyIdentifier = [keyId stringByAppendingString:@".public"];

        _publicKeyRef = [self getPublicKeyRefFromX509AuthenticationTag:_authenticatedRendezvousTag.authenticationTag
                                                   publicKeyIdentifier:_publicKeyIdentifier
                                                                 error:error];
        if (!_publicKeyRef || (error && *error)) {
            LogError(@"Failed to validate/get public key from authentication tag.");
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    // Delete any keys we imported (as they should be transitory)
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

- (QLFRendezvousAuthSignature *)emptySignature
{
    return [super emptySignature];
}

- (BOOL)isValidSignature:(QLFRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error
{
    __block NSData *signatureData = nil;

    [signature ifRendezvousAuthX509_PEM:^(NSData *signature) {
        signatureData = signature;
    } ifRendezvousAuthX509_PEM_SELFSIGNED:^(NSData *signature) {
    } ifRendezvousAuthED25519:^(NSData *signature) {
    } ifRendezvousAuthRSA2048_PEM:^(NSData *signature) {
    } ifRendezvousAuthRSA4096_PEM:^(NSData *signature) {
    }];
    
    if (!signatureData) {
        return NO;
    }
    
    if (!rendezvousData) {
        return NO;
    }

    if ([signatureData length] < 1) {
        return NO;
    }
    
    BOOL signatureIsValid = [QredoCrypto rsaPssVerifySignature:signatureData forMessage:rendezvousData saltLength:kX509AuthenticatedRendezvousSaltLength keyRef:_publicKeyRef];
    
    LogDebug(@"X.509 Authenticated Rendezvous signature valid: %@", signatureIsValid ? @"YES" : @"NO");
    
    return signatureIsValid;
}

@end
