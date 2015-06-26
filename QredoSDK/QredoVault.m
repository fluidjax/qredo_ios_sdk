/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoVaultSequenceCache.h"

#import "NSDictionary+QUIDSerialization.h"
#import "NSDictionary+IndexableSet.h"
#import "QredoVaultCrypto.h"
#import "QredoCrypto.h"
#import "QredoLogging.h"
#import "QredoKeychain.h"

#import "QredoUpdateListener.h"

#import "QredoObserverList.h"

#import "QredoVaultServerAccess.h"

// Cache
#import <PINCache/PINCache.h>
#import "QredoVaultItem+Cache.h"

NSString *const QredoVaultOptionSequenceId = @"com.qredo.vault.sequence.id.";
NSString *const QredoVaultOptionHighWatermark = @"com.qredo.vault.hwm";

static NSString *const QredoVaultItemMetadataItemDateCreated = @"_created";
static NSString *const QredoVaultItemMetadataItemDateModified = @"_modified";
static NSString *const QredoVaultItemMetadataItemVersion = @"_v";

NSString *const QredoVaultItemMetadataItemTypeTombstone = @"\u220E"; // U+220E END OF PROOF, https://github.com/Qredo/design-docs/wiki/Vault-Item-Tombstone
static NSString *const QredoVaultItemMetadataItemTypeRendezvous = @"com.qredo.rendezvous";
static NSString *const QredoVaultItemMetadataItemTypeConversation = @"com.qredo.conversation";

static const double kQredoVaultUpdateInterval = 1.0; // seconds

@interface PINDiskCache (Private)

+(BOOL)moveItemAtURLToTrash:(NSURL *)itemURL;

@end

@interface QredoVault () <QredoUpdateListenerDataSource, QredoUpdateListenerDelegate>
{
    QredoVaultKeys *_vaultKeys;
    QredoQUID *_sequenceId;

    QredoVaultHighWatermark *_highwatermark;
    
    QredoObserverList *_observers;

    QredoVaultCrypto *_vaultCrypto;
    QredoVaultSequenceCache *_vaultSequenceCache;

    QredoVaultServerAccess *_vaultServerAccess;

    dispatch_queue_t _queue;

    QredoUpdateListener *_updateListener;

    PINCache *_cacheItems;
    PINCache *_cacheHeaders;
}

- (void)saveState;
- (void)loadState;
- (void)clearState;

@end

@implementation QredoVault (Private)

- (QredoVaultKeys *)vaultKeys
{
    return _vaultKeys;
}

- (QredoQUID *)sequenceId
{
    return _sequenceId;
}

- (instancetype)initWithClient:(QredoClient *)client vaultKeys:(QredoVaultKeys *)vaultKeys
{
    if (!client || !vaultKeys) return nil;
    self = [super init];
    if (!self) return nil;

    _vaultKeys = vaultKeys;
    _highwatermark = QredoVaultHighWatermarkOrigin;
    
    _observers = [[QredoObserverList alloc] init];

    _queue = dispatch_queue_create("com.qredo.vault.updates", nil);

    [self loadState];

    if (!_sequenceId) {
        _sequenceId = [QredoQUID QUID];
        [self saveState];
    }

    _updateListener = [[QredoUpdateListener alloc] init];
    _updateListener.delegate = self;
    _updateListener.dataSource = self;
    _updateListener.pollInterval = kQredoVaultUpdateInterval;

    _vaultCrypto = [QredoVaultCrypto vaultCryptoWithBulkKey:vaultKeys.encryptionKey
                                          authenticationKey:vaultKeys.authenticationKey];

    _vaultSequenceCache = [QredoVaultSequenceCache instance];

    _vaultServerAccess = [[QredoVaultServerAccess alloc] initWithClient:client
                                                            vaultCrypto:_vaultCrypto
                                                             sequenceId:_sequenceId
                                                              vaultKeys:_vaultKeys
                                                     vaultSequenceCache:_vaultSequenceCache
                                                       enumerationQueue:_queue];

    _cacheItems = [[PINCache alloc] initWithName:[_vaultKeys.vaultId.QUIDString stringByAppendingString:@".items"]];
    _cacheHeaders = [[PINCache alloc] initWithName:[_vaultKeys.vaultId.QUIDString stringByAppendingString:@".headers"]];
    
    return self;
}

- (QredoQUID *)itemIdWithName:(NSString *)name type:(NSString *)type
{
    NSString *constructedName = [NSString stringWithFormat:@"%@.%@@%@", [self.vaultId QUIDString], name, type];
    NSData *hash = [QredoCrypto sha256:[constructedName dataUsingEncoding:NSUTF8StringEncoding]];
    return [[QredoQUID alloc] initWithQUIDData:hash];
}

- (QredoQUID *)itemIdWithQUID:(QredoQUID *)quid type:(NSString *)type
{
    return [self itemIdWithName:[quid QUIDString] type:type];
}

- (void)putUpdateOrDeleteItem:(QredoVaultItem *)vaultItem
                       itemId:(QredoQUID*)itemId
                     dataType:(NSString *)dataType
                summaryValues:(NSDictionary *)summaryValues
            completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{

    [_vaultServerAccess putUpdateOrDeleteItem:vaultItem
                                       itemId:itemId
                                     dataType:dataType
                                summaryValues:summaryValues
                            completionHandler:^(QredoVaultItemMetadata *newItemMetadata, QLFEncryptedVaultItem *encryptedVaultItem, NSError *error)
    {
        QredoMutableVaultItemMetadata *newMetadata = [vaultItem.metadata mutableCopy];
        newMetadata.origin = QredoVaultItemOriginServer;
        newMetadata.descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:_sequenceId
                                                                               sequenceValue:newItemMetadata.descriptor.sequenceValue
                                                                                      itemId:itemId];

        [self cacheEncryptedVaultItem:encryptedVaultItem
                       itemDescriptor:newMetadata.descriptor
                    completionHandler:^(NSError *error)
         {
             completionHandler(newMetadata, nil);
         }];
    }];
}

- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem
         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    QredoQUID *itemId = [QredoQUID QUID];
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    newSummaryValues[QredoVaultItemMetadataItemDateCreated] = [NSDate date];
    [self putUpdateOrDeleteItem:vaultItem
                         itemId:itemId
                       dataType:metadata.dataType
                  summaryValues:newSummaryValues
              completionHandler:completionHandler];
}

- (void)strictlyUpdateItem:(QredoVaultItem *)vaultItem
         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    QredoQUID *itemId = metadata.descriptor.itemId;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    newSummaryValues[QredoVaultItemMetadataItemDateModified] = [NSDate date];
    newSummaryValues[QredoVaultItemMetadataItemVersion] = @(metadata.descriptor.sequenceValue);
    [self putUpdateOrDeleteItem:vaultItem
                         itemId:itemId
                       dataType:metadata.dataType
                  summaryValues:newSummaryValues
              completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         if (newItemMetadata) {
             [self removeBodyFromCacheWithVaultItemDescriptor:vaultItem.metadata.descriptor
                                            completionHandler:^(NSError *error)
             {
                 completionHandler(newItemMetadata, error);
             }];
         } else {
             completionHandler(newItemMetadata, error);
         }
     }];
}

#pragma mark Cache

- (void)clearCache
{
    [_cacheHeaders removeAllObjects];
    [_cacheItems removeAllObjects];

    // [PINDiskCache removeAllObjects] removes folders with all its contents, but then it creates a new empty one.
    // These lines make sure that folder is removed entirely.
    [PINDiskCache moveItemAtURLToTrash:_cacheHeaders.diskCache.cacheURL];
    [PINDiskCache moveItemAtURLToTrash:_cacheItems.diskCache.cacheURL];
    [PINDiskCache emptyTrash];
}

- (void)clearAllData
{
    [self clearCache];
    [self clearState];
    [_vaultSequenceCache clear];
}

- (void)cacheEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)encryptedVaultItemHeader
                 itemDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                    completionHandler:(void (^)(NSError *error))completionHandler
{
    [_cacheHeaders setObject:encryptedVaultItemHeader
                      forKey:itemDescriptor.cacheKey
                       block:^(PINCache *cache, NSString *key, id __nullable object) {
        completionHandler(nil);
    }];

}


- (void)cacheEncryptedVaultItem:(QLFEncryptedVaultItem *)encryptedVaultItem
                 itemDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
              completionHandler:(void (^)(NSError *error))completionHandler
{
    [self cacheEncryptedVaultItemHeader:encryptedVaultItem.header
                         itemDescriptor:itemDescriptor
                      completionHandler:^(NSError *error)
    {
        [_cacheItems setObject:encryptedVaultItem
                        forKey:itemDescriptor.cacheKey
                         block:^(PINCache *cache, NSString *key, id __nullable object)
        {
            completionHandler(nil);
        }];
    }];
}

- (void)removeBodyFromCacheWithVaultItemDescriptor:(QredoVaultItemDescriptor *)descriptor
                                 completionHandler:(void (^)(NSError *error))completionHandler
{
    [_cacheItems removeObjectForKey:descriptor.cacheKey
                              block:^(PINCache *cache, NSString *key, id __nullable object)
     {
         completionHandler(nil);
     }];
}

@end

@implementation QredoVault

- (QredoQUID *)vaultId
{
    return _vaultKeys.vaultId;
}

- (void)getItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
            completionHandler:(void(^)(QredoVaultItem *vaultItem, NSError *error))completionHandler
{
    [_cacheItems objectForKey:itemDescriptor.cacheKey
                        block:^(PINCache *cache, NSString *key, id __nullable object)
    {
        if (object && [object isKindOfClass:[QLFEncryptedVaultItem class]]) {
            QLFEncryptedVaultItem *encryptedVaultItem = (QLFEncryptedVaultItem *)object;

            [_vaultCrypto decryptEncryptedVaultItem:encryptedVaultItem
                                             origin:QredoVaultItemOriginCache
                                  completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
            {
                // in case if cache entry is corrupted
                if (!vaultItem) {
                    [_vaultServerAccess getItemWithDescriptor:itemDescriptor completionHandler:completionHandler];
                } else {
                    completionHandler(vaultItem, error);
                }
            }];

        } else {
            [_vaultServerAccess getItemWithDescriptor:itemDescriptor completionHandler:completionHandler];
        }
    }];
}

- (void)getItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                    completionHandler:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, NSError *error))completionHandler
{
    [_cacheHeaders objectForKey:itemDescriptor.cacheKey
                        block:^(PINCache *cache, NSString *key, id __nullable object)
     {
         if (object && [object isKindOfClass:[QLFEncryptedVaultItemHeader class]]) {
             QLFEncryptedVaultItemHeader *encryptedVaultItemHeader = (QLFEncryptedVaultItemHeader *)object;

             [_vaultCrypto decryptEncryptedVaultItemHeader:encryptedVaultItemHeader
                                                    origin:QredoVaultItemOriginCache
                                         completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata, NSError *error)
              {
                  // in case if cache entry is corrupted
                  if (!vaultItemMetadata) {
                      [_vaultServerAccess getItemMetadataWithDescriptor:itemDescriptor completionHandler:completionHandler];
                  } else {
                      completionHandler(vaultItemMetadata, error);
                  }
              }];

         } else {
             [_vaultServerAccess getItemMetadataWithDescriptor:itemDescriptor completionHandler:completionHandler];
         }
     }];
}

- (void)addVaultObserver:(id<QredoVaultObserver>)observer
{
    QredoUpdateListener *updateListener = _updateListener;
    [_observers addObserver:observer];
    if (!updateListener.isListening) {
        [updateListener startListening];
    }
}

- (void)removeVaultObserver:(id<QredoVaultObserver>)observer
{
    QredoUpdateListener *updateListener = _updateListener;
    QredoObserverList *observers = _observers;
    [_observers removeObserver:observer];
    if ([observers count] < 1 && !_updateListener.isListening) {
        [updateListener stopListening];
    }
}

- (void)notifyObservers:(void(^)(id<QredoVaultObserver> observer))notificationBlock
{
    [_observers notifyObservers:notificationBlock];
}
     
     

- (void)resetWatermark
{
    _highwatermark = nil;
    [self saveState];
}

- (void)putItem:(QredoVaultItem *)vaultItem
completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    BOOL isNewItemFromDateCreated = vaultItem.metadata.summaryValues[QredoVaultItemMetadataItemDateCreated] == nil;
    BOOL isNewItemFromDescriptor = vaultItem.metadata.descriptor == nil;
    
    NSAssert(isNewItemFromDateCreated == isNewItemFromDescriptor, @"Can not determine whether the item is newely created or not.");
    
    if (isNewItemFromDateCreated) {
        [self strictlyPutNewItem:vaultItem completionHandler:completionHandler];
    }
    else {
        [self strictlyUpdateItem:vaultItem completionHandler:completionHandler];
    }
}

- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                       completionHandler:(void(^)(NSError *error))completionHandler
{
    [self enumerateVaultItemsUsingBlock:block since:QredoVaultHighWatermarkOrigin completionHandler:completionHandler];
}

- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                                since:(QredoVaultHighWatermark*)sinceWatermark
                    completionHandler:(void(^)(NSError *error))completionHandler
{
    dispatch_async(_queue, ^{
        [_vaultServerAccess enumerateVaultItemsUsingBlock:block completionHandler:completionHandler watermarkHandler:nil since:sinceWatermark consolidatingResults:YES];
    });
}

- (void)deleteItem:(QredoVaultItemMetadata *)metadata completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler
{
    QredoQUID *itemId = metadata.descriptor.itemId;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionary];
    newSummaryValues[QredoVaultItemMetadataItemDateCreated] = metadata.summaryValues[QredoVaultItemMetadataItemDateCreated];
    newSummaryValues[QredoVaultItemMetadataItemDateModified] = [NSDate date];
    newSummaryValues[QredoVaultItemMetadataItemVersion] = @(metadata.descriptor.sequenceValue); // TODO: not working for int64
    [self putUpdateOrDeleteItem:[QredoVaultItem vaultItemWithMetadata:metadata value:[NSData data]]
                         itemId:itemId
                       dataType:QredoVaultItemMetadataItemTypeTombstone
                  summaryValues:newSummaryValues
              completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         if (newItemMetadata) {
             [self removeBodyFromCacheWithVaultItemDescriptor:metadata.descriptor
                                            completionHandler:^(NSError *cacheError)
              {
                  completionHandler(newItemMetadata.descriptor, error);
              }];
         } else {
             completionHandler(nil, error);
         }
     }];
}

- (QredoVaultHighWatermark *)highWatermark
{
    return _highwatermark;
}

- (NSString *)sequenceIdKeyForDefaults
{
    return [QredoVaultOptionSequenceId stringByAppendingString:[_vaultKeys.vaultId QUIDString]];
}

- (NSString *)hwmKeyForDefaults
{
    return [QredoVaultOptionHighWatermark stringByAppendingString:[_vaultKeys.vaultId QUIDString]];
}

- (void)clearState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults removeObjectForKey:self.sequenceIdKeyForDefaults];
    [defaults removeObjectForKey:self.hwmKeyForDefaults];
    [defaults synchronize];
}

- (void)saveState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:[_sequenceId data] forKey:self.sequenceIdKeyForDefaults];

    if (_highwatermark) {
        [defaults setObject:[_highwatermark.sequenceState quidToStringDictionary] forKey:self.hwmKeyForDefaults];
    } else {
        [defaults removeObjectForKey:self.hwmKeyForDefaults];
    }
    [defaults synchronize];
}

- (void)loadState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSData *sequenceIdData = [defaults objectForKey:self.sequenceIdKeyForDefaults];

    if (sequenceIdData) {
        _sequenceId = [[QredoQUID alloc] initWithQUIDData:sequenceIdData];
    }

    NSDictionary* sequenceState = [defaults objectForKey:self.hwmKeyForDefaults];
    if (sequenceState) {
        _highwatermark = [QredoVaultHighWatermark watermarkWithSequenceState:[sequenceState stringToQuidDictionary]];
    } else {
        _highwatermark = nil;
    }
}

#pragma mark -
#pragma mark Qredo Update Listener - Data Source

- (BOOL)qredoUpdateListenerDoesSupportMultiResponseQuery:(QredoUpdateListener *)updateListener
{
    return NO;
}

#pragma mark Qredo Update Listener - Delegate

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener pollWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    [_vaultServerAccess enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        [_updateListener processSingleItem:vaultItemMetadata sequenceValue:@(vaultItemMetadata.descriptor.sequenceValue)];
    } completionHandler:completionHandler
                       watermarkHandler:^(QredoVaultHighWatermark *watermark)
    {
        self->_highwatermark = watermark;
        [self saveState];
    } since:self.highWatermark consolidatingResults:NO];
}

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener processSingleItem:(id)item
{
    QredoVaultItemMetadata *vaultItemMetadata = (QredoVaultItemMetadata *)item;

    [self notifyObservers:^(id<QredoVaultObserver> observer) {
        if ([observer respondsToSelector:@selector(qredoVault:didReceiveVaultItemMetadata:)]) {
            [observer qredoVault:self didReceiveVaultItemMetadata:vaultItemMetadata];
        }
    }];
}

@end
