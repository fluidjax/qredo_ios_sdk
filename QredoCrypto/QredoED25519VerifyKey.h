/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKey.h"

@interface QredoED25519VerifyKey : QredoKey
@property (nonatomic, readonly, copy) NSData *data;
- (instancetype)initWithKeyData:(NSData *)data;
@end


