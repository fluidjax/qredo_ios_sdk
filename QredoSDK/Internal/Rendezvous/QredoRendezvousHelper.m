/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"


@implementation QredoAbstractRendezvousHelper

- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto
{
    self = [super init];
    if (self) {
        _cryptoImpl = crypto;
    }
    return self;
}

@end


