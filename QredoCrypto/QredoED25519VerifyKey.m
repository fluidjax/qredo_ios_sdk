/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoED25519VerifyKey.h"


@interface QredoED25519VerifyKey ()
@property (nonatomic, copy) NSData *data;
@end

@implementation QredoED25519VerifyKey

- (instancetype)initWithKeyData:(NSData *)data
{
    self = [self init];
    if (self) {
        self.data = data;
    }
    return self;
}

- (NSData *)convertKeyToNSData
{
    return _data;
}

@end
