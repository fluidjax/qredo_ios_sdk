/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"


@interface QredoED25519SigningKey ()
@property (nonatomic, copy) NSData *seed;
@property (nonatomic, copy) NSData *data;
@property (nonatomic) QredoED25519VerifyKey *verifyKey;
@end

@implementation QredoED25519SigningKey

- (instancetype)initWithSeed:(NSData *)seed keyData:(NSData *)data verifyKey:(QredoED25519VerifyKey *)verifyKey
{
    self = [self init];
    if (self) {
        self.seed = seed;
        self.data = data;
        self.verifyKey = verifyKey;
    }
    return self;
}

- (NSData *)convertKeyToNSData
{
    return _data;
}

@end


