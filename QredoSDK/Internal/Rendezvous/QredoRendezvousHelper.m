/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"


@implementation QredoAbstractRendezvousHelper

- (instancetype)initWithTag:(NSString *)tag crypto:(id<CryptoImpl>)crypto
{
    self = [super init];
    if (self) {
        _originalTag = tag;
        _cryptoImpl = crypto;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
}

@end


