/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousEd25519Helper.h"
#import "QredoRendezvousHelper_Private.h"
#import "QredoClient.h"

@implementation QredoRendezvousEd25519Helper

- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeEd25519;
}

- (NSString *)tag
{
    // TODO [GR]: Implement this.
    return nil;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    // TODO [GR]: Implement this.
    return nil;
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data
{
    // TODO [GR]: Implement this.
    return nil;
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
    
    // TODO [GR]: Implement this.
    return NO;
}

@end


