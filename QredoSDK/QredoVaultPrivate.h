/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoVaultPrivate_h
#define QredoSDK_QredoVaultPrivate_h

#import "QredoVault.h"
#import "QredoQUID.h"

// This file contains private methods. Therefore, it should never be #import'ed in any of the public headers.
// It shall be included only in the implementation files

@class QredoClient;

@interface QredoVault (Private)

- (QredoQUID *)sequenceId;

- (instancetype)initWithClient:(QredoClient *)client vaultId:(QredoQUID *)vaultId;

- (QredoQUID *)itemIdWithName:(NSString *)name type:(NSString *)type;
- (QredoQUID *)itemIdWithQUID:(QredoQUID *)quid type:(NSString *)type;


// public method doesn't allow to specify itemId
- (void)strictlyPutItem:(QredoVaultItem *)vaultItem itemId:(QredoQUID *)itemId completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler;

@end

#endif
