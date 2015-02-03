/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousAnonymousHelper.h"
#import "QredoRendezvousHelper_Private.h"



@interface QredoRendezvousAnonymousHelper ()
@property (nonatomic, copy) NSString *originalTag;
@end

@implementation QredoRendezvousAnonymousHelper

- (instancetype)initWithPrefix:(NSString *)prefix crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        self.originalTag = prefix;
    }
    return self;
}

- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error
{
    self = [super initWithCrypto:crypto];
    if (self) {
        self.originalTag = fullTag;
    }
    return self;
}


- (QredoRendezvousAuthenticationType)type
{
    return QredoRendezvousAuthenticationTypeAnonymous;
}

- (NSString *)tag
{
    return self.originalTag;
}

- (QredoRendezvousAuthSignature *)emptySignature
{
    return nil;
}

- (QredoRendezvousAuthSignature *)signatureWithData:(NSData *)data error:(NSError **)error
{
    return nil;
}

- (BOOL)isValidSignature:(QredoRendezvousAuthSignature *)signature rendezvousData:(NSData *)rendezvousData error:(NSError **)error
{
    return YES;
}

@end


