/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "Qredo.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"


@implementation QredoVaultItem
+ (instancetype)vaultItemWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value
{
    return [[QredoVaultItem alloc] initWithMetadata:metadata value:value];
}

- (instancetype)initWithMetadata:(QredoVaultItemMetadata *)metadata value:(NSData *)value
{
    self = [super init];
    if (!self) return nil;
    _metadata = metadata;
    _value = value;

    return self;
}
@end