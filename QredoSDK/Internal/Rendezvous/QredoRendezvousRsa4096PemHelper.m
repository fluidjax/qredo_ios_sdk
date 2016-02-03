/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousRsa4096PemHelper.h"
#import "QredoClient.h"
#import "QredoLoggerPrivate.h"

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

- (instancetype)initWithFullTag:(NSString *)fullTag
                         crypto:(id<CryptoImpl>)crypto
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                 signingHandler:(signDataBlock)signingHandler
                          error:(NSError **)error
{
    // TrustedRootPems and CrlPems are unused in RSA authenticated rendezvous

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

- (NSString *)tag
{
    return super.authenticatedRendezvousTag.fullTag;
}

- (QLFRendezvousAuthSignature *)emptySignature
{
    NSData *emptySignatureData = [super emptySignatureData];
    return [QLFRendezvousAuthSignature rendezvousAuthRSA4096_PEMWithSignature:emptySignatureData];
}

- (QLFRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    NSData *signatureData = [super signatureForData:data error:error];
    
    if (!signatureData || (error && *error)) {
        QredoLogError(@"Signature generation unsuccessful.");
        return nil;
    }
    
    return [QLFRendezvousAuthSignature rendezvousAuthRSA4096_PEMWithSignature:signatureData];
}

@end

@implementation QredoRendezvousRsa4096PemRespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag
                         crypto:(id<CryptoImpl>)crypto
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                          error:(NSError **)error
{
    // TrustedRootPems and CrlPems are unused in RSA authenticated rendezvous

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

- (NSString *)tag
{
    return super.authenticatedRendezvousTag.fullTag;
}

- (QLFRendezvousAuthSignature *)emptySignature
{
    NSData *emptySignatureData = [super emptySignatureData];
    return [QLFRendezvousAuthSignature rendezvousAuthRSA4096_PEMWithSignature:emptySignatureData];
}

- (BOOL)isValidSignature:(QLFRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error
{
    __block NSData *signatureData = nil;
    [signature ifRendezvousAuthX509_PEM:^(NSData *signature) {

    } ifRendezvousAuthX509_PEM_SELFSIGNED:^(NSData *signature) {

    } ifRendezvousAuthED25519:^(NSData *signature) {

    } ifRendezvousAuthRSA2048_PEM:^(NSData *signature) {

    } ifRendezvousAuthRSA4096_PEM:^(NSData *signature) {
        signatureData = signature;
    }];
    
    BOOL signatureIsValid = [super isSignatureDataValid:signatureData rendezvousData:rendezvousData];
    
    return signatureIsValid;
}

@end
