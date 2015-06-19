/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "Qredo.h"
#import "QredoPrivate.h"

#import "NSDictionary+QUIDSerialization.h"
#import "NSDictionary+IndexableSet.h"
#import "QredoVaultCrypto.h"
#import "QredoVaultSequenceCache.h"
#import "QredoCrypto.h"
#import "QredoLogging.h"
#import "QredoKeychain.h"

#import "QredoUpdateListener.h"

#import "QLFOwnershipSignature+FactoryMethods.h"
#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"
#import "QredoSigner.h"
#import "QredoObserverList.h"


NSString *const QredoVaultOptionSequenceId = @"com.qredo.vault.sequence.id.";
NSString *const QredoVaultOptionHighWatermark = @"com.qredo.vault.hwm";

static NSString *const QredoVaultItemMetadataItemDateCreated = @"_created";
static NSString *const QredoVaultItemMetadataItemDateModified = @"_modified";
static NSString *const QredoVaultItemMetadataItemVersion = @"_v";

static NSString *const QredoVaultItemMetadataItemTypeTombstone = @"\u220E"; // U+220E END OF PROOF, https://github.com/Qredo/design-docs/wiki/Vault-Item-Tombstone
static NSString *const QredoVaultItemMetadataItemTypeRendezvous = @"com.qredo.rendezvous";
static NSString *const QredoVaultItemMetadataItemTypeConversation = @"com.qredo.conversation";

static const double kQredoVaultUpdateInterval = 1.0; // seconds

@interface QredoVault () <QredoUpdateListenerDataSource, QredoUpdateListenerDelegate>
{
    QredoClient *_client;
    QredoVaultKeys *_vaultKeys;
    QredoQUID *_sequenceId;

    QredoVaultHighWatermark *_highwatermark;
    
    QredoObserverList *_observers;


    QLFVault *_vault;
    QredoVaultCrypto *_vaultCrypto;
    QredoVaultSequenceCache *_vaultSequenceCache;

    dispatch_queue_t _queue;

    QredoUpdateListener *_updateListener;
}

- (void)saveState;
- (void)loadState;

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

    _client = client;
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

    _vault = [QLFVault vaultWithServiceInvoker:_client.serviceInvoker];
    _vaultSequenceCache = [QredoVaultSequenceCache instance];

    _vaultCrypto = [QredoVaultCrypto vaultCryptoWithBulkKey:vaultKeys.encryptionKey
                                          authenticationKey:vaultKeys.authenticationKey];
    
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
                       itemId:(QredoQUID*)itemId dataType:(NSString *)dataType
                summaryValues:(NSDictionary *)summaryValues
            completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{

    QLFVaultSequenceValue newSequenceValue = [_vaultSequenceCache nextSequenceValue];

    QredoVaultItemMetadata *metadata = vaultItem.metadata;

    QLFVaultItemRef *vaultItemDescriptor =
    [QLFVaultItemRef vaultItemRefWithVaultId:_vaultKeys.vaultId
                                  sequenceId:_sequenceId
                               sequenceValue:newSequenceValue
                                      itemId:itemId];

    QLFVaultItemMetadata *vaultItemMetaDataLF =
    [QLFVaultItemMetadata vaultItemMetadataWithDataType:dataType
                                                 values:[summaryValues indexableSet]];

    QLFEncryptedVaultItemHeader *encryptedVaultItemHeader =
    [_vaultCrypto encryptVaultItemHeaderWithItemRef:vaultItemDescriptor
                                           metadata:vaultItemMetaDataLF];

    QLFEncryptedVaultItem *encryptedVaultItem = [_vaultCrypto encryptVaultItemWithBody:vaultItem.value
                                                              encryptedVaultItemHeader:encryptedVaultItemHeader];

    NSError *error = nil;

    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureWithSigner:[[QredoED25519Singer alloc] initWithSigningKey:_vaultKeys.ownershipKeyPair]
                                            operationType:[QLFOperationType operationCreate]
                                                     data:encryptedVaultItem
                                                    error:&error];

    if (error) {
        completionHandler(nil, error);
        return;
    }
    
    [_vault putItemWithItem:encryptedVaultItem
                  signature:ownershipSignature
          completionHandler:^void(BOOL result, NSError *error)
     {
         if (result && !error) {
             [_vaultSequenceCache setItemSequence:itemId
                                       sequenceId:_sequenceId
                                    sequenceValue:newSequenceValue];
             
             
             QredoMutableVaultItemMetadata *newMetadata = [metadata mutableCopy];
             newMetadata.descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:_sequenceId
                                                                                    sequenceValue:newSequenceValue
                                                                                           itemId:itemId];
             
             completionHandler(newMetadata, nil);
             
         } else {
             
             completionHandler(nil, error);
             
         }
     }];
}

- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem
         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    QredoQUID *itemId = [QredoQUID QUID];
    [self strictlyPutNewItem:vaultItem itemId:itemId completionHandler:completionHandler];
}

- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem
                    itemId:(QredoQUID *)itemId
         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
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
              completionHandler:completionHandler];
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

    QLFVaultSequenceId   *sequenceId    = itemDescriptor.sequenceId;
    QLFVaultSequenceValue sequenceValue = itemDescriptor.sequenceValue;

    NSError *error = nil;

    NSSet *sequenceValues = [NSSet setWithObject:@(sequenceValue)];
    
    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureForGetVaultItemWithSigner:[[QredoED25519Singer alloc] initWithSigningKey:_vaultKeys.ownershipKeyPair]
                                                     vaultItemDescriptor:itemDescriptor
                                                 vaultItemSequenceValues:sequenceValues
                                                                   error:&error];
    if (error) {
        completionHandler(nil, error);
        return;
    }

    [_vault getItemWithVaultId:_vaultKeys.vaultId
                    sequenceId:sequenceId
                 sequenceValue:sequenceValues
                        itemId:itemDescriptor.itemId
                     signature:ownershipSignature
             completionHandler:^(NSSet *result, NSError *error)
    {
         if (!error && [result count]) {
             QLFEncryptedVaultItem *encryptedVaultItem = [result anyObject];

             NSError *decryptionError = nil;
             QLFVaultItem *vaultItemLF = [_vaultCrypto decryptEncryptedVaultItem:encryptedVaultItem
                                                                           error:&decryptionError];
             if (!vaultItemLF) {
                 if (!decryptionError) {
                     decryptionError = [NSError errorWithDomain:QredoErrorDomain
                                                           code:QredoErrorCodeMalformedOrTamperedData
                                                       userInfo:nil];
                 }

                 completionHandler(nil, decryptionError);
                 return ;
             }

             NSDictionary *summaryValues = [vaultItemLF.metadata.values dictionaryFromIndexableSet];

             QredoVaultItemDescriptor *descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:encryptedVaultItem.header.ref.sequenceId
                                                                                                  sequenceValue:encryptedVaultItem.header.ref.sequenceValue
                                                                                                         itemId:encryptedVaultItem.header.ref.itemId];

             QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                                                               dataType:vaultItemLF.metadata.dataType
                                                                                            accessLevel:0
                                                                                          summaryValues:summaryValues];

             if ([metadata.dataType isEqualToString:QredoVaultItemMetadataItemTypeTombstone]) {
                 error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeVaultItemHasBeenDeleted userInfo:nil];
                 completionHandler(nil, error);
             }
             else {
                 QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:vaultItemLF.body];
                 completionHandler(vaultItem, nil);
             }

         } else {
             if (!error) {
                 error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeVaultItemNotFound userInfo:nil];
             }
             completionHandler(nil, error);
         }
    }];
}

- (void)getItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                    completionHandler:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, NSError *error))completionHandler
{
    QLFVaultSequenceId *sequenceId = itemDescriptor.sequenceId;
    QLFVaultSequenceValue sequenceValue = [_vaultSequenceCache sequenceValueForItem:itemDescriptor.itemId];

    NSError *error = nil;

    NSSet *sequenceValues = sequenceValue ? [NSSet setWithObject:@(sequenceValue)] : [NSSet set];
    
    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureForGetVaultItemWithSigner:[[QredoED25519Singer alloc] initWithSigningKey:_vaultKeys.ownershipKeyPair]
                                                     vaultItemDescriptor:itemDescriptor
                                                 vaultItemSequenceValues:sequenceValues
                                                                   error:&error];
    if (error) {
        completionHandler(nil, error);
        return;
    }


    [_vault getItemHeaderWithVaultId:_vaultKeys.vaultId
                            sequenceId:sequenceId
                         sequenceValue:sequenceValues
                                itemId:itemDescriptor.itemId
                             signature:ownershipSignature
                     completionHandler:^(NSSet *result, NSError *error)
     {
         if (!error && result.count) {

             QLFEncryptedVaultItemHeader *encryptedVaultItemHeader = [result anyObject];

             NSError *decryptionError = nil;
             QLFVaultItemMetadata *vaultItemMetadataLF
             = [_vaultCrypto decryptEncryptedVaultItemHeader:encryptedVaultItemHeader
                                                       error:&decryptionError];

             if (!vaultItemMetadataLF) {
                 if (!decryptionError) {
                     decryptionError = [NSError errorWithDomain:QredoErrorDomain
                                                           code:QredoErrorCodeMalformedOrTamperedData
                                                       userInfo:nil];
                 }

                 completionHandler(nil, decryptionError);
                 return;
             }


             NSDictionary *summaryValues = [vaultItemMetadataLF.values dictionaryFromIndexableSet];

             QredoVaultItemDescriptor *descriptor
             = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:encryptedVaultItemHeader.ref.sequenceId
                                                             sequenceValue:encryptedVaultItemHeader.ref.sequenceValue
                                                                    itemId:encryptedVaultItemHeader.ref.itemId];

             QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                                                               dataType:vaultItemMetadataLF.dataType
                                                                                            accessLevel:0
                                                                                          summaryValues:summaryValues];
             if ([metadata.dataType isEqualToString:QredoVaultItemMetadataItemTypeTombstone]) {
                 error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeVaultItemHasBeenDeleted userInfo:nil];
                 completionHandler(nil, error);
             }
             else {
                 completionHandler(metadata, nil);
             }

         } else {
             if (!error) {
                 error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeVaultItemNotFound
                                         userInfo:@{NSLocalizedDescriptionKey: @"Vault item not found"}];
             }
             completionHandler(nil, error);
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

- (void)removeVaultObaserver:(id<QredoVaultObserver>)observer
{
    QredoUpdateListener *updateListener = _updateListener;
    QredoObserverList *observers = _observers;
    [_observers removeObaserver:observer];
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
        [self enumerateVaultItemsUsingBlock:block completionHandler:completionHandler watermarkHandler:nil since:sinceWatermark consolidatingResults:YES];
    });
}

// this is private method that also returns highWatermark. Used in the polling data
- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                    completionHandler:(void(^)(NSError *error))completionHandler
                     watermarkHandler:(void(^)(QredoVaultHighWatermark*))watermarkHandler
                                since:(QredoVaultHighWatermark*)sinceWatermark
                  consolidatingResults:(BOOL)shouldConsolidateResults
{
    NSAssert(block, @"block should not be nil");
    __block NSMutableSet *sequenceStates = [[sinceWatermark vaultSequenceState] mutableCopy];

    if (!sequenceStates) {
        sequenceStates = [NSMutableSet set];
    }
    LogDebug(@"Watermark: %@", sinceWatermark.sequenceState);


    NSError *error = nil;
    
    QLFOwnershipSignature *ownershipSignature
    = [QLFOwnershipSignature ownershipSignatureForListVaultItemsWithSigner:[[QredoED25519Singer alloc] initWithSigningKey:_vaultKeys.ownershipKeyPair]
                                                            sequenceStates:sequenceStates
                                                                     error:&error];

    if (error) {
        completionHandler(error);
        return;
    }

    // Sync sequence IDs...
    [_vault queryItemHeadersWithVaultId:_vaultKeys.vaultId
                         sequenceStates:sequenceStates
                              signature:ownershipSignature
                      completionHandler:^void(QLFVaultItemQueryResults *vaultItemMetaDataResults, NSError *error)
    {
        if (error) {
            if (completionHandler) {
                completionHandler(error);
            }
            return;
        }

        NSSet *sequenceIds = [vaultItemMetaDataResults sequenceIds];

        NSMutableDictionary *newWatermarkDictionary = [sinceWatermark.sequenceState mutableCopy];
        if (!newWatermarkDictionary) {
            newWatermarkDictionary = [NSMutableDictionary dictionary];
        }
        
        
        typedef void(^EnumerateResultsWithHandler)(QredoVaultItemMetadata* vaultItemMetadata, BOOL *stop);
        NSArray *results = [vaultItemMetaDataResults results];
        void(^enumerateResultsWithHandler)(EnumerateResultsWithHandler) = ^(EnumerateResultsWithHandler handler) {
            
            BOOL stop = FALSE;
            for (QLFEncryptedVaultItemHeader *result in results) {
                @try {
                    NSError *error = nil;
                    QLFVaultItemMetadata* decryptedItem = [_vaultCrypto decryptEncryptedVaultItemHeader:result
                                                                                                  error:&error];
                    if (error) {
                        // skipping the error
                        LogError(@"Failed to decrypt an item with error: %@", error);
                        continue;
                    }
                    
                    QredoVaultItemDescriptor *descriptor
                    = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:result.ref.sequenceId
                                                                    sequenceValue:result.ref.sequenceValue
                                                                           itemId:result.ref.itemId];

                    QredoVaultItemMetadata *externalItem
                    = [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:descriptor
                                                                     dataType:decryptedItem.dataType
                                                                  accessLevel:0
                                                                summaryValues:[decryptedItem.values dictionaryFromIndexableSet]];

                    if (handler) {
                        handler(externalItem, &stop);
                    }
                    
                    [newWatermarkDictionary setObject:@(externalItem.descriptor.sequenceValue) // TODO: not working for int64
                                               forKey:externalItem.descriptor.sequenceId];
                    
                    if (stop) {
                        break;
                    }
                } @catch (NSException *exception) {
                    NSLog(@"Failed to decrypt a vault item: %@", exception);
                }
            }

        };
        
        
        if (shouldConsolidateResults) {
            
            
            // Filter out all items wich are pointed ot by back pointers.
            
            /*
             TODO: [GR] This agorithm can use high levels of memory if the vault contains many items. Hence it 
             is advisable to revise this algorithm in connection with caching, and certainly before release.
             */
            
            NSMutableDictionary *metadataRefMap = [NSMutableDictionary dictionary];
            NSMutableArray *metadataArray = [NSMutableArray array];
            enumerateResultsWithHandler(^(QredoVaultItemMetadata* vaultItemMetadata, BOOL *stop) {
                metadataRefMap[vaultItemMetadata.descriptor] = vaultItemMetadata;
                [metadataArray addObject:vaultItemMetadata];
            });
            
            QredoVaultItemDescriptor *(^backpointerOfMetadata)(QredoVaultItemMetadata *metadata)
            = ^QredoVaultItemDescriptor *(QredoVaultItemMetadata *metadata) {
                NSNumber *previousSequenceValue = metadata.summaryValues[@"_v"];
                if (!previousSequenceValue) {
                    return nil;
                }
                QredoVaultItemDescriptor *descriptor = metadata.descriptor;
                return [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:descriptor.sequenceId
                                                                     sequenceValue:[previousSequenceValue longValue]
                                                                            itemId:descriptor.itemId];
            };
            
            for (QredoVaultItemMetadata* metadata in metadataArray) {
                QredoVaultItemDescriptor *backPointer = backpointerOfMetadata(metadata);
                if (backPointer) {
                    [metadataRefMap removeObjectForKey:backPointer];
                }
            }
            
            for (QredoVaultItemMetadata* metadata in metadataArray) {
                BOOL stop = NO;
                if (metadataRefMap[metadata.descriptor] && ![metadata.dataType isEqualToString:QredoVaultItemMetadataItemTypeTombstone]) {
                    block(metadata, &stop);
                    if (stop) {
                        break;
                    }
                }
            }
            
        }
        else {
            
            // Return all items in the vault, ie. all permutaions of itmes ids, sequence ids and sequence values.
            
            enumerateResultsWithHandler(^(QredoVaultItemMetadata* vaultItemMetadata, BOOL *stop) {
                block(vaultItemMetadata, stop);
            });
            
        }
        

        BOOL discoveredNewSequence = NO;
        // We want items for all sequences...
        for (QLFVaultSequenceId *sequenceId in sequenceIds) {
            if ([newWatermarkDictionary objectForKey:sequenceId] != nil) {
                continue;
            }
            
            QLFVaultSequenceState *sequenceState =
            [QLFVaultSequenceState vaultSequenceStateWithSequenceId:sequenceId
                                                        sequenceValue:0];
            [sequenceStates addObject:sequenceState];

            [newWatermarkDictionary setObject:@0 forKey:sequenceId];
            discoveredNewSequence = YES;
        }

        QredoVaultHighWatermark *newWatermark = [QredoVaultHighWatermark watermarkWithSequenceState:newWatermarkDictionary];

        if (watermarkHandler) {
            watermarkHandler(newWatermark);
        }

        if (discoveredNewSequence) {
            dispatch_async(_queue, ^{
                [self enumerateVaultItemsUsingBlock:block
                                  completionHandler:completionHandler
                                   watermarkHandler:watermarkHandler
                                              since:newWatermark
                               consolidatingResults:shouldConsolidateResults];
            });
        } else {
            completionHandler(nil);
        }
   }];
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
         completionHandler(newItemMetadata.descriptor, error);
     }];
}


- (QredoVaultHighWatermark *)highWatermark
{
    return _highwatermark;
}

- (void)saveState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:[_sequenceId data] forKey:[QredoVaultOptionSequenceId stringByAppendingString:[_vaultKeys.vaultId QUIDString]]];

    NSString *hwmKey = [QredoVaultOptionHighWatermark stringByAppendingString:[_vaultKeys.vaultId QUIDString]];
    if (_highwatermark) {
        [defaults setObject:[_highwatermark.sequenceState quidToStringDictionary] forKey:hwmKey];
    } else {
        [defaults removeObjectForKey:hwmKey];
    }
}

- (void)loadState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSData *sequenceIdData = [defaults objectForKey:[QredoVaultOptionSequenceId stringByAppendingString:[_vaultKeys.vaultId QUIDString]]];

    if (sequenceIdData) {
        _sequenceId = [[QredoQUID alloc] initWithQUIDData:sequenceIdData];
    }

    NSString *hwmKey = [QredoVaultOptionHighWatermark stringByAppendingString:[_vaultKeys.vaultId QUIDString]];
    NSDictionary* sequenceState = [defaults objectForKey:hwmKey];
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
    [self enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
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
