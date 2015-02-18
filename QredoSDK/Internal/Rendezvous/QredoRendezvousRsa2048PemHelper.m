/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousRsa2048PemHelper.h"
#import "QredoClient.h"
#import "QredoLogging.h"

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

@implementation QredoRendezvousRsa2048PemCreateHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    self = [super initWithFullTag:fullTag
                           crypto:crypto
                   signingHandler:signingHandler
                             type:QredoRendezvousAuthenticationTypeRsa4096Pem
                      keySizeBits:kRsa2048KeyLengthBits
   minimumAuthenticationTagLength:kMinRsa2048AuthenticationTagLength error:error];
    if (self) {
        
    }
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    // TODO: DH - see whether can make a common (parent?) method between create and respond helpers
    return QredoRendezvousAuthenticationTypeRsa2048Pem;
}

- (NSString *)tag
{
    return super.authenticatedRendezvousTag.fullTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    // TODO: DH - see whether can make a common (parent?) method between create and respond helpers
    NSData *emptySignatureData = [super emptySignatureData];
    return [QredoRendezvousAuthSignature rendezvousAuthRSA2048_PEMWithSignature:emptySignatureData];
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    NSData *signatureData = [super signatureForData:data error:error];
    
    // TODO: DH - check for error?
    return [QredoRendezvousAuthSignature rendezvousAuthRSA2048_PEMWithSignature:signatureData];
}

@end

@implementation QredoRendezvousRsa2048PemRespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithFullTag:fullTag
                           crypto:crypto
                             type:QredoRendezvousAuthenticationTypeRsa4096Pem
                      keySizeBits:kRsa2048KeyLengthBits
   minimumAuthenticationTagLength:kMinRsa2048AuthenticationTagLength
                            error:error];
    if (self) {
        
    }
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeRsa2048Pem;
}

- (NSString *)tag
{
    return super.authenticatedRendezvousTag.fullTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    // TODO: DH - see whether can make a common (parent?) method between create and respond helpers
    NSData *emptySignatureData = [super emptySignatureData];
    return [QredoRendezvousAuthSignature rendezvousAuthRSA2048_PEMWithSignature:emptySignatureData];
}

- (BOOL)isValidSignature:(QredoRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error
{
    __block NSData *signatureData = nil;
    [signature ifX509_PEM:^(NSData *signature) {
    } X509_PEM_SELFISGNED:^(NSData *signature) {
    } ED25519:^(NSData *signature) {
    } RSA2048_PEM:^(NSData *signature) {
        signatureData = signature;
    } RSA4096_PEM:^(NSData *signature) {
    } other:^{
    }];
    
    BOOL signatureIsValid = [super isSignatureDataValid:signatureData rendezvousData:rendezvousData];
    
    return signatureIsValid;
}

@end
