/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousX509PemHelper.h"
#import "QredoClient.h"
#import "CryptoImpl.h"
#import "QredoCrypto.h"
#import "QredoCertificateUtils.h"
#import "QredoLogging.h"
#import "QredoAuthenticatedRendezvousTag.h"


@implementation QredoAbstractRendezvousX509PemHelper

// Salt length for RSA PSS signing (related to hash length)
const NSInteger kX509AuthenticatedRendezvousSaltLength = 32;
static const NSUInteger kX509AuthenticatedRendezvousEmptySignatureLength = 256;

// TODO: DH - confirm the minimum length of X.509 authentication tag (i.e. single certificate with RSA 2048 bit Public key) - 2048 bit key must be at least 256 bytes long, unsure how much certificate wrapping adds
static const NSUInteger kMinX509AuthenticationTagLength = 256;

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeX509Pem;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    // Empty Signature is just a placeholder of the correct size for a real signature.
    NSData *emptySignatureData = [NSMutableData dataWithLength:kX509AuthenticatedRendezvousEmptySignatureLength];
    return [QredoRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:emptySignatureData];
}

- (SecKeyRef)getPublicKeyRefFromX509AuthenticationTag:(NSString *)authenticationTag error:(NSError **)error
{
    NSArray *certificateChainRefs = [QredoCertificateUtils getCertificateRefsFromPemCertificates:authenticationTag];
    if (!certificateChainRefs) {
        LogError(@"Could not get any certificate refs. Tag not valid PEM formatted X.509 cert? Authentication tag: %@", authenticationTag);
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        return nil;
    }
    
    NSArray *trustedRootRefs = [self.cryptoImpl getTrustedRootRefs];
    SecKeyRef publicKeyRef = [QredoCertificateUtils validateCertificateChain:certificateChainRefs
                                                         rootCertificateRefs:trustedRootRefs];
    if (!publicKeyRef) {
        LogError(@"Authentication tag (certificate chain) did not validate correctly. Authentication tag: %@", authenticationTag);
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
    }
    
    return publicKeyRef;
}

@end


@interface QredoRendezvousX509PemCreateHelper ()

@property (nonatomic, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@property (nonatomic, assign) SecKeyRef publicKeyRef;
@property (nonatomic, copy) signDataBlock signingHandler;

@end

@implementation QredoRendezvousX509PemCreateHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
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
        
        // Confirm that the authentication tag is a PEM certificate chain which validates correctly
        _publicKeyRef = [self getPublicKeyRefFromX509AuthenticationTag:_authenticatedRendezvousTag.authenticationTag
                                                                 error:error];
        if (!_publicKeyRef || (error && *error)) {
            LogError(@"X.509 authentication tag is invalid.");
            return nil;
        }
        
        _signingHandler = signingHandler;
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
        return [QredoRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:signature];
    }
}

@end


@interface QredoRendezvousX509PemRespondHelper ()

@property (nonatomic, strong) QredoAuthenticatedRendezvousTag *authenticatedRendezvousTag;
@property (nonatomic, assign) SecKeyRef publicKeyRef;

@end

@implementation QredoRendezvousX509PemRespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
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
        
        _publicKeyRef = [self getPublicKeyRefFromX509AuthenticationTag:_authenticatedRendezvousTag.authenticationTag error:error];
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
        signatureData = signature;
    } X509_PEM_SELFISGNED:^(NSData *signature) {
    } ED25519:^(NSData *signature) {
    } RSA2048_PEM:^(NSData *signature) {
    } RSA4096_PEM:^(NSData *signature) {
    } other:^{
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
