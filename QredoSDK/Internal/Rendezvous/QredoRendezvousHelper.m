/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"


@implementation QredoAbstractRendezvousHelper

- (instancetype)initWithTag:(NSString *)tag crypto:(id<CryptoImpl>)crypto
{
    self = [self init];
    if (self) {
        _originalTag = tag;
        _cryptoImpl = crypto;
    }
    return self;
}

@end


