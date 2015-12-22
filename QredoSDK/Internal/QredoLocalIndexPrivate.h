/*
 *  Copyright (c) 2011-2015 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "Qredo.h"
#import "QredoIndexSummaryValues.h"
#import "QredoIndexVaultItemMetadata.h"


@interface QredoLocalIndex : NSObject <QredoVaultObserver>

- (instancetype)initWithVault:(QredoVault *)vault;

/** Put a metadata item into the local Index */
- (void)putMetadata:(QredoVaultItemMetadata *)newMetadata;
- (void)putVaultItem:(QredoVaultItem *)vaultItem;

/** Get a the most recent metadata item (most recent based on sequence number) */
- (QredoVaultItem *)getVaultItemFromIndexWithDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor;
- (QredoVaultItemMetadata *)getMetadataFromIndexWithDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor;

/** Enumerates through all vault items in the local index that match the predicate
    The predicate search is performed on the QredoIndexSummaryValues object.

    eg. [NSPredicate predicateWithFormat:@"key='name' && value.string=='John'"];
        [NSPredicate predicateWithFormat:@"key='name' && value.string=='John'"];

    Value is matched against a sub field depending on specified type.
    Valid types are
            value.string    (an NSString)
            value.date      (as NSDate)
            value.number    (an NSNumber)
            value.data      (an NSData)

 */
- (void)enumerateSearch:(NSPredicate *)predicate
        withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block
        completionHandler:(void (^)(NSError *error))completionHandler;

/** Count of how many metadata items in the index */
- (int)count;

/** Delete all items in the cache */
- (void)purge;


/** Adds the LocalIndex as an observer to new/updated vault ID's sent from the server
    Block is called after each incoming item
 */
- (void)enableSync;
- (void)enableSyncWithBlock:(IncomingMetadataBlock)block;
- (void)removeIndexObserver;
- (BOOL)deleteItem:(QredoVaultItemDescriptor *)vaultItemDescriptor;
- (BOOL)deleteItem:(QredoVaultItemDescriptor *)vaultItemDescriptor error:(NSError*)returnError;
- (void)dump:(NSString *)message;

@end