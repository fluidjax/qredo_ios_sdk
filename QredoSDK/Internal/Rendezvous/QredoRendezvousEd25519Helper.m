/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousEd25519Helper.h"
#import "QredoClient.h"
#import "CryptoImpl.h"
#import "QredoBase58.h"



@implementation QredoAbstractRendezvousEd25519Helper

QredoRendezvousAuthSignature *kEmptySignature = nil;

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeEd25519;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    NSData *emptySignatureData = [self.cryptoImpl qredoED25519EmptySignature];
    return [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:emptySignatureData];
}

@end


@interface QredoRendezvousEd25519CreateHelper () {
    QredoED25519SigningKey *_sk;
}
@property (nonatomic, copy) NSString *prefix;
@end

@implementation QredoRendezvousEd25519CreateHelper

- (instancetype)initWithPrefix:(NSString *)prefix crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        self.prefix = prefix;
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
    NSData *sig = [self.cryptoImpl qredoED25519SignMessage:data withKey:_sk error:error];
    if (!sig) {
        return nil;
    }
    return [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:sig];
}

@end


@interface QredoRendezvousEd25519RespondHelper () {
    QredoED25519VerifyKey *_vk;
}
@property (nonatomic, copy) NSString *fullTag;
@end

@implementation QredoRendezvousEd25519RespondHelper

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        _vk = [self verifyKeyFromTag:self.fullTag error:error];
        if (!_vk) {
            return nil;
        }
        self.fullTag = fullTag;
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
        signatureData = nil;
    } X509_PEM_SELFISGNED:^(NSData *signature) {
        signatureData = nil;
    } ED25519:^(NSData *signature) {
        signatureData = signature;
    } RSA2048_PEM:^(NSData *signature) {
        signatureData = nil;
    } RSA4096_PEM:^(NSData *signature) {
        signatureData = nil;
    } other:^{
        signatureData = nil;
    }];
    
    if ([signatureData length] < 1) {
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorWrongSignatureType, nil);
        return NO;
    }
    
    return [self.cryptoImpl qredoED25519VerifySignature:signatureData ofMessage:rendezvousData verifyKey:_vk error:error];
}

- (QredoED25519VerifyKey *)verifyKeyFromTag:(NSString *)tag error:(NSError **)error
{
    if ([tag length] < 1) {
        updateErrorWithQredoRendezvousHelperError(error, QredoRendezvousHelperErrorMissingTag, nil);
        return nil;
    }
    
    QredoED25519VerifyKey *vk = nil;
    
    NSUInteger prefixPos = [tag rangeOfString:@"@" options:NSBackwardsSearch].location;
    
    NSString *vkString = nil;
    if (prefixPos == NSNotFound) {
        vkString = tag;
    } else {
        vkString = [tag substringFromIndex:prefixPos+1];
    }
    
    NSData *vkData = [QredoBase58 decodeData:vkString error:error];
    if (!vkData) {
        return nil;
    }
    
    vk = [self.cryptoImpl qredoED25519VerifyKeyWithData:vkData error:error];
    return vk;
}

@end



