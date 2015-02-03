/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousX509PemHelper.h"
#import "QredoClient.h"
#import "CryptoImpl.h"
#import "QredoBase58.h"


@implementation QredoAbstractRendezvousX509PemHelper

// TODO: DH - Removed as apparently unused
//QredoRendezvousAuthSignature *kEmptySignature = nil;

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeX509Pem;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    // TODO: DH - replace ED25519
    NSData *emptySignatureData = [self.cryptoImpl qredoED25519EmptySignature];
    return [QredoRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:emptySignatureData];
}

@end


@interface QredoRendezvousX509PemCreateHelper () {
    // TODO: DH - replace ED25519
    QredoED25519SigningKey *_sk;
}
@property (nonatomic, copy) NSString *prefix;
// TODO: DH - add property for blocks
@end

@implementation QredoRendezvousX509PemCreateHelper

- (instancetype)initWithPrefix:(NSString *)prefix crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        self.prefix = prefix;
        // TODO: DH - replace ED25519
        _sk = [self.cryptoImpl qredoED25519SigningKey];
    }
    return self;
}

- (QredoRendezvousAuthenticationType)type
{
    return [super type];
}

- (NSString *)tag
{
    NSString *trimmedPrefix = [self.prefix stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *encodedVK = [QredoBase58 encodeData:_sk.verifyKey.data];
    
    if ([trimmedPrefix length] == 0) {
        return encodedVK;
    }
    
    if ([trimmedPrefix hasSuffix:@"@"]) {
        return [trimmedPrefix stringByAppendingString:encodedVK];
    }
    
    // TODO [GR]: Discuss this appending of '@' with hugh and the rest.
    return [NSString stringWithFormat:@"%@@%@", trimmedPrefix, encodedVK];
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    return [super emptySignature];
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    NSAssert(_sk, @"Signing key is unknown");
    // TODO: DH - replace ED25519
    NSData *sig = [self.cryptoImpl qredoED25519SignMessage:data withKey:_sk error:error];
    if (!sig) {
        return nil;
    }
    // TODO: DH - replace ED25519
    return [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:sig];
}

@end


@interface QredoRendezvousX509PemRespondHelper () {
    // TODO: DH - replace ED25519
    QredoED25519VerifyKey *_vk;
}
@property (nonatomic, copy) NSString *fullTag;
@end

@implementation QredoRendezvousX509PemRespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        if ([fullTag length] < 1) {
            if (error) {
                *error = qredoRendezvousHelperError(QredoRendezvousHelperErrorMissingTag, nil);
            }
            return nil;
        }
        self.fullTag = fullTag;
        _vk = [self verifyKeyFromTag:self.fullTag error:error];
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
    
    // TODO: DH - replace ED25519
    return [self.cryptoImpl qredoED25519VerifySignature:signatureData ofMessage:rendezvousData verifyKey:_vk error:error];
}

// TODO: DH - replace ED25519
- (QredoED25519VerifyKey *)verifyKeyFromTag:(NSString *)tag error:(NSError **)error
{
    // TODO [GR]: The code in this method should return errors through the **error rather than assert
    
    NSAssert([tag length], @"Malformed tag");
    // TODO: DH - replace ED25519
    QredoED25519VerifyKey *vk = nil;
    
    NSUInteger prefixPos = [tag rangeOfString:@"@" options:NSBackwardsSearch].location;
    
    NSString *vkString = nil;
    if (prefixPos == NSNotFound) {
        vkString = tag;
    } else {
        vkString = [tag substringFromIndex:prefixPos+1];
    }
    
    NSData *vkData = [QredoBase58 decodeData:vkString];
    NSAssert([vkData length], @"Malformed tag (on decoding)");
    
    // TODO: DH - replace ED25519
    vk = [self.cryptoImpl qredoED25519VerifyKeyWithData:vkData error:error];
    return vk;
}

@end
