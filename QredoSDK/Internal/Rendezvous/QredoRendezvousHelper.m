/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"
#import "QredoLogging.h"

@implementation QredoAbstractRendezvousHelper

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto
{
    self = [super init];
    if (self) {
        NSAssert(crypto, @"A crypto implementation has not been provided.");
        _cryptoImpl = crypto;
    }
    return self;
}

@end

NSError *qredoRendezvousHelperError(QredoRendezvousHelperError errorCode, NSDictionary *userInfo)
{
    return [NSError errorWithDomain:QredoRendezvousHelperErrorDomain code:errorCode userInfo:userInfo];
}
