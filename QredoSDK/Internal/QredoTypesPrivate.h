/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

@interface QredoObjectRef ()

@property QredoVaultItemDescriptor *vaultItemDescriptor;
@property (readwrite) NSData *data;

- (instancetype)initWithVaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor vault:(QredoVault *)vault;

@end