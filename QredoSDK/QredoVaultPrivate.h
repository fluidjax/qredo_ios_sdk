/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoVault.h"
#import "QredoQUID.h"
#import "QredoClient.h"

// This file contains private methods. Therefore, it should never be #import'ed in any of the public headers.
// It shall be included only in the implementation files

NSString *const QredoVaultItemMetadataItemTypeTombstone;

@class QredoClient, QredoKeychain, QredoVaultKeys;

@interface QredoVaultItemDescriptor()<NSCopying>
@property (readonly) QLFVaultSequenceValue sequenceValue;

+ (instancetype)vaultItemDescriptorWithSequenceId:(QredoQUID *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QredoQUID *)itemId;
@end


// Opaque Class. Keeping interface only here
@interface QredoVaultHighWatermark()
// key: SequenceId (QredoQUID*), value: SequenceValue (NSNumber*)
// TODO: WARNING NSNumber on 32-bit systems can keep maximum 32-bit integers, but we need 64. Kept NSNumber because in the LF code we use NSNumber right now
@property NSMutableDictionary *sequenceState;
- (NSSet*)vaultSequenceState;
+ (instancetype)watermarkWithSequenceState:(NSDictionary *)sequenceState;
@end

typedef NS_ENUM(NSInteger, QredoVaultItemOrigin)
{
    QredoVaultItemOriginServer,
    QredoVaultItemOriginCache
};

@interface QredoVaultItemMetadata ()

@property QredoVaultItemDescriptor *descriptor;
@property (copy) NSString *dataType;
@property NSDate *created;
@property QredoAccessLevel accessLevel;
@property (copy) NSDictionary *summaryValues; // string -> string | NSNumber | QredoQUID
@property QredoVaultItemOrigin origin;

// private method. the developer should not specify the date
+ (instancetype)vaultItemMetadataWithDataType:(NSString *)dataType accessLevel:(QredoAccessLevel)accessLevel created: (NSDate*)created summaryValues:(NSDictionary *)summaryValues;

@end


@interface QredoVault (Private)

- (QredoQUID *)sequenceId;
- (QredoVaultKeys *)vaultKeys;

- (instancetype)initWithClient:(QredoClient *)client vaultKeys:(QredoVaultKeys *)vaultKeys;

- (QredoQUID *)itemIdWithName:(NSString *)name type:(NSString *)type;
- (QredoQUID *)itemIdWithQUID:(QredoQUID *)quid type:(NSString *)type;


// public method doesn't allow to specify itemId
- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler;

// update a vault item, update the modification date and sequence value
- (void)strictlyUpdateItem:(QredoVaultItem *)vaultItem completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler;


// Cleans only cache. Vault object is still usable after that
- (void)clearCache;

// Destroys all data, including sequenceId record. Vault objects is not supposed to be used after that
- (void)clearAllData;

@end
