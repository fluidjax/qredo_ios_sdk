/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoVault.h"
#import "QredoQUID.h"
#import "QredoClient.h"

// This file contains private methods. Therefore, it should never be #import'ed in any of the public headers.
// It shall be included only in the implementation files

@class QredoClient, QredoKeychain;

@interface QredoVaultItemDescriptor()<NSCopying>
@property (readonly) QLFVaultSequenceValue sequenceValue;
@end


@interface QredoVault (Private)

- (QredoQUID *)sequenceId;
- (QredoKeychain *)qredoKeychain;

- (instancetype)initWithClient:(QredoClient *)client qredoKeychain:(QredoKeychain *)qredoKeychan;
- (instancetype)initWithClient:(QredoClient *)client qredoKeychain:(QredoKeychain *)qredoKeychan vaultId:(QredoQUID*)vaultId;
- (instancetype)initWithClient:(QredoClient *)client qredoKeychain:(QredoKeychain *)qredoKeychan signingKeySeed:(NSData *)signingKeySeed;

- (QredoQUID *)itemIdWithName:(NSString *)name type:(NSString *)type;
- (QredoQUID *)itemIdWithQUID:(QredoQUID *)quid type:(NSString *)type;


// public method doesn't allow to specify itemId
- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem itemId:(QredoQUID *)itemId completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler;

@end
