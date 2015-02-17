/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousRsa4096PemHelper.h"
#import "QredoClient.h"
#import "QredoLogging.h"

/*
 PEM RSA Public Key is a DER encoded public key with PEM wrapping.
 Actual DER encoding lengths could vary with PKCS#1/X.509, exponent size. Smallest
 would be PKCS#1 which is just 2 integers (4096 bit Modulus and minimum 1 byte Exponent) wrapped in a sequence,
 along with tag/length bytes.  X.509 format would add extra wrapping (approx 20 bytes extra BEFORE base64, meaning
 28 bytes after base64).
 
 PKCS#1 format calcs:
 Modulus = 512 bytes data + 3 bytes length (82 + xxxx length) + 1 byte INTEGER tag = 516 bytes.
 Exponent = 1 byte (min) data + 1 byte length + 1 byte INTEGER tag = 3 bytes.
 Sequence wrapper = Modulus + exponent lengths of data + 3 bytes length + 1 byte tag = 519 + 3 + 1 = 523 bytes.
 
 Base64 encodes 3 bytes as 4 bytes, 523 bytes = 700 bytes as base64 (ignoring any CR/CRLF line-wrapping breaks).
 
 PEM Key header = 27 bytes (inc trailing CR). PEM Key footer = 26 bytes (inc leading and trailling CR)
 
 Total min length of 4096 bit RSA key in PKCS#1 DER + PEM format = 753 bytes. 781 bytes for X.509 format.
 */
static const NSUInteger kMinRsa4096AuthenticationTagLength = 753;

static const NSUInteger kRsa4096KeyLengthBits = 4096;

@implementation QredoRendezvousRsa4096PemCreateHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    self = [super initWithFullTag:fullTag
                           crypto:crypto
                   signingHandler:signingHandler
                             type:QredoRendezvousAuthenticationTypeRsa4096Pem
                      keySizeBits:kRsa4096KeyLengthBits
   minimumAuthenticationTagLength:kMinRsa4096AuthenticationTagLength error:error];
    if (self) {

    }
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    // TODO: DH - see whether can make a common (parent?) method between create and respond helpers
    return QredoRendezvousAuthenticationTypeRsa4096Pem;
}

- (NSString *)tag
{
    return super.authenticatedRendezvousTag.fullTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    // TODO: DH - see whether can make a common (parent?) method between create and respond helpers
    NSData *emptySignatureData = [super emptySignatureData];
    return [QredoRendezvousAuthSignature rendezvousAuthRSA4096_PEMWithSignature:emptySignatureData];
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    NSData *signatureData = [super signatureForData:data error:error];

    // TODO: DH - check for error?
    return [QredoRendezvousAuthSignature rendezvousAuthRSA4096_PEMWithSignature:signatureData];
}

@end

@implementation QredoRendezvousRsa4096PemRespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithFullTag:fullTag
                           crypto:crypto
                             type:QredoRendezvousAuthenticationTypeRsa4096Pem
                      keySizeBits:kRsa4096KeyLengthBits
   minimumAuthenticationTagLength:kMinRsa4096AuthenticationTagLength
                            error:error];
    if (self) {

    }
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeRsa4096Pem;
}

- (NSString *)tag
{
    return super.authenticatedRendezvousTag.fullTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    // TODO: DH - see whether can make a common (parent?) method between create and respond helpers
    NSData *emptySignatureData = [super emptySignatureData];
    return [QredoRendezvousAuthSignature rendezvousAuthRSA4096_PEMWithSignature:emptySignatureData];
}

- (BOOL)isValidSignature:(QredoRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error
{
    __block NSData *signatureData = nil;
    [signature ifX509_PEM:^(NSData *signature) {
    } X509_PEM_SELFISGNED:^(NSData *signature) {
    } ED25519:^(NSData *signature) {
    } RSA2048_PEM:^(NSData *signature) {
    } RSA4096_PEM:^(NSData *signature) {
        signatureData = signature;
    } other:^{
    }];
    
    BOOL signatureIsValid = [super isSignatureDataValid:signatureData rendezvousData:rendezvousData];
    
    return signatureIsValid;
}

@end
