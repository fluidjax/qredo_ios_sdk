/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousX509PemHelper.h"
#import "QredoClient.h"
#import "CryptoImpl.h"
#import "QredoBase58.h"
#import "QredoCrypto.h"
#import "QredoCertificateUtils.h"
#import "QredoLogging.h"


@implementation QredoAbstractRendezvousX509PemHelper

// TODO: DH - confirm the minimum length of X.509 authenticated tag (i.e. single certificate with RSA 2048 bit Public key)
static const NSUInteger kMinX509AuthenticatedRendezvousTagLength = 1;

// TODO: DH - confirm the salt length used for authenticated rendezvous
// TODO: DH - how to provide the salt length to the signingCallback, so know what salt size should be?
static const NSUInteger kX509AuthenticatedRendezvousSaltLength = 8;
static const NSUInteger kX509AuthenticatedRendezvousEmptySignatureLength = 256;

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
    
    SecKeyRef publicKeyRef = [QredoCertificateUtils validateCertificateChain:certificateChainRefs rootCertificateRefs:[self.cryptoImpl getTrustedRootRefs]];
    if (!publicKeyRef) {
        LogError(@"Authentication tag (certificate chain) did not validate correctly. Authentication tag: %@", authenticationTag);
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorAuthenticationTagInvalid, nil);
        }
    }
    
    return publicKeyRef;
}

- (NSString *)stripPrefixFromX509FullTag:(NSString *)fullTag error:(NSError **)error
{
    if (!fullTag) {
        LogError(@"Nil full tag provided.");
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
        }
        return nil;
    }
    
    if (fullTag.length <= kMinX509AuthenticatedRendezvousTagLength) {
        LogError(@"Invalid full tag length: %ld. Minimum tag length for X509 Authenticated Rendezvous: %ld",
                 fullTag.length,
                 kMinX509AuthenticatedRendezvousTagLength);
        if (error) {
            *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMalformedTag, nil);
        }
        return nil;
    }
    
    return [self stripPrefixFromFullTag:fullTag error:error];
}

@end


@interface QredoRendezvousX509PemCreateHelper ()

@property (nonatomic, copy) NSString *fullTag;
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
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
            }
            return nil;
        }

        // Signing handler is mandatory for X.509 certs (cannot generate these internally)
        if (!signingHandler)
        {
            LogError(@"No signing handler provided. Mandatory for X.509 authenticated rendezvous as can only use externally generated keys.");
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorSignatureHandlerMissing, nil);
            }
            return nil;
        }

        _fullTag = fullTag;
        
        NSString *authenticationTag = [self stripPrefixFromX509FullTag:fullTag error:error];
        if (*error) {
            LogError(@"Stripping prefix returned error: %@", *error);
            return nil;
        }
        else if (!authenticationTag || [authenticationTag isEqualToString:@""]) {
            LogError(@"Nil, or empty authentication tag returned: '%@'.  Full tag: '%@'.", authenticationTag, fullTag);
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
            }
            return nil;
        }
        
        // Confirm that the authentication tag is a PEM certificate chain which validates correctly
        _publicKeyRef = [self getPublicKeyRefFromX509AuthenticationTag:authenticationTag error:error];
        if (*error || !_publicKeyRef) {
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
    // For X.509, we do not generate any keys and the full tag has to be provided during creation, so just return that
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
    
    NSData *signature = self.signingHandler(data);
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
                                                  saltLength:kX509AuthenticatedRendezvousSaltLength
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


@interface QredoRendezvousX509PemRespondHelper ()

@property (nonatomic, copy) NSString *fullTag;
@property (nonatomic, assign) SecKeyRef publicKeyRef;

@end

@implementation QredoRendezvousX509PemRespondHelper

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
        
        _fullTag = fullTag;
        
        NSString *authenticationTag = [self stripPrefixFromFullTag:self.fullTag error:error];
        // TODO: DH - Check error result
        
        _publicKeyRef = [self getPublicKeyRefFromX509AuthenticationTag:authenticationTag error:error];
        // TODO: DH - check error result/ref returned
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
        signatureData = signature;
    } X509_PEM_SELFISGNED:^(NSData *signature) {
        signatureData = nil;
    } ED25519:^(NSData *signature) {
        signatureData = nil;
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
    
    BOOL signatureIsValid = [QredoCrypto rsaPssVerifySignature:signatureData forMessage:rendezvousData saltLength:kX509AuthenticatedRendezvousSaltLength keyRef:_publicKeyRef];
    
    return signatureIsValid;
}

@end
