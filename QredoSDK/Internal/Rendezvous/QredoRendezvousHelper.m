/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper_Private.h"
#import "QredoLogger.h"

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

void updateErrorWithQredoRendezvousHelperError(NSError **error,
                                               QredoRendezvousHelperError errorCode,
                                               NSDictionary *userInfo)

{
    if (error) {
        *error = [NSError errorWithDomain:QredoRendezvousHelperErrorDomain code:errorCode userInfo:userInfo];
    }
}
