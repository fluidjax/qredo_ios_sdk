/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousEd25519Helper.h"
#import "QredoRendezvousHelper_Private.h"
#import "QredoClient.h"
#import "CryptoImpl.h"
#import "QredoBase58.h"


@interface QredoRendezvousEd25519Helper () {
    QredoED25519SigningKey *_sk;
    QredoED25519VerifyKey *_vk;
}
@end


@implementation QredoRendezvousEd25519Helper

QredoRendezvousAuthSignature *kEmptySignature = nil;

+ (void)load
{
    [super load];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kEmptySignature = [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:[NSMutableData dataWithLength:64]];
    });
}

- (void)commonInit
{
    if ([self noTagProvided]) {
        
        _sk = [self.cryptoImpl qredoED25519SigningKey];
        _vk = _sk.verifyKey;
        
    } else {
        
        _sk = nil;
        _vk = [self verifyKeyFromTag:self.originalTag];
        
    }
}

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeEd25519;
}

- (NSString *)tag
{
    NSString *trimedString = [self.originalTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([trimedString length] == 0) {
        return [QredoBase58 encodeData:_vk.data];
    }
    
    if ([trimedString hasSuffix:@"@"]) {
        NSString *encodedVK = [QredoBase58 encodeData:_vk.data];
        return [trimedString stringByAppendingString:encodedVK];
    }
    
    return self.originalTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    return kEmptySignature;
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data
{
    NSAssert(_sk, @"Signing key is unknown");    
    NSData *sig = [self.cryptoImpl qredoED25519SignMessage:data withKey:_sk];
    return [QredoRendezvousAuthSignature rendezvousAuthED25519WithSignature:sig];
}

- (BOOL)isValidSignature:(QredoRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData
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
    
    if (!signatureData) {
        return NO;
    }
    
    return [self.cryptoImpl qredoED25519VerifySignature:signatureData ofMessage:rendezvousData verifyKey:_vk];
}

- (BOOL)noTagProvided
{
    NSString *trimedString = [self.tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [trimedString length] == 0 || [trimedString hasSuffix:@"@"];
}

- (QredoED25519VerifyKey *)verifyKeyFromTag:(NSString *)tag
{
    NSAssert([tag length], @"Malformed tag");
    QredoED25519VerifyKey *vk = nil;
    
    NSUInteger prefixPos = [tag rangeOfString:@"@"].location;
    
    NSString *vkString = nil;
    if (prefixPos == NSNotFound) {
        vkString = tag;
    } else {
        vkString = [tag substringFromIndex:prefixPos+1];
    }
    
    NSData *vkData = [QredoBase58 decodeData:vkString];
    NSAssert([tag length], @"Malformed tag (on decoding");
    vk = [self.cryptoImpl qredoED25519VerifyKeyWithData:vkData];
    
    return vk;
}

@end


