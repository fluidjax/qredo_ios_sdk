/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoVaultServerAccess.h"

#import "Qredo.h"
#import "QredoPrivate.h"

#import "QredoVaultCrypto.h"
#import "QredoVaultSequenceCache.h"

#import "NSDictionary+QUIDSerialization.h"
#import "NSDictionary+IndexableSet.h"

#import "QLFOwnershipSignature+FactoryMethods.h"
#import "QredoED25519SigningKey.h"
#import "QredoED25519VerifyKey.h"
#import "QredoSigner.h"

#import "QredoErrorCodes.h"
#import "QredoLogging.h"

@interface QredoVaultServerAccess ()
{
    QredoClient *_client;
    QLFVault *_vaultService;
    QredoVaultKeys *_vaultKeys;
    QredoVaultCrypto *_vaultCrypto;
    QredoVaultSequenceCache *_vaultSequenceCache;
    QredoQUID *_sequenceId;
    dispatch_queue_t _queue;
}
@end


@implementation QredoVaultServerAccess

- (instancetype)initWithClient:(QredoClient *)client
                   vaultCrypto:(QredoVaultCrypto *)vaultCrypto
                    sequenceId:(QredoQUID *)sequenceId
                     vaultKeys:(QredoVaultKeys *)vaultKeys
            vaultSequenceCache:(QredoVaultSequenceCache *)vaultSequenceCache
              enumerationQueue:(dispatch_queue_t)enumerationQueue
{
    self = [super init];

    if (self) {
        _client = client;
        _vaultCrypto = vaultCrypto;
        _sequenceId = sequenceId;
        _vaultKeys = vaultKeys;
        _queue = enumerationQueue;
        _vaultSequenceCache = vaultSequenceCache;

        _vaultService = [QLFVault vaultWithServiceInvoker:_client.serviceInvoker];
    }

    return self;
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

    [_vaultService getItemWithVaultId:_vaultKeys.vaultId
                    sequenceId:sequenceId
                 sequenceValue:sequenceValues
                        itemId:itemDescriptor.itemId
                     signature:ownershipSignature
             completionHandler:^(NSSet *result, NSError *error)
     {
         if (!error && [result count]) {
             QLFEncryptedVaultItem *encryptedVaultItem = [result anyObject];
             [_vaultCrypto decryptEncryptedVaultItem:encryptedVaultItem
                                              origin:QredoVaultItemOriginServer
                                   completionHandler:completionHandler];
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


    [_vaultService getItemHeaderWithVaultId:_vaultKeys.vaultId
                          sequenceId:sequenceId
                       sequenceValue:sequenceValues
                              itemId:itemDescriptor.itemId
                           signature:ownershipSignature
                   completionHandler:^(NSSet *result, NSError *error)
     {
         if (!error && result.count) {
             QLFEncryptedVaultItemHeader *encryptedVaultItemHeader = [result anyObject];

             [_vaultCrypto decryptEncryptedVaultItemHeader:encryptedVaultItemHeader
                                                    origin:QredoVaultItemOriginServer
                                         completionHandler:completionHandler];
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

- (void)putUpdateOrDeleteItem:(QredoVaultItem *)vaultItem
                       itemId:(QredoQUID*)itemId dataType:(NSString *)dataType
                      created:(NSDate*)created
                summaryValues:(NSDictionary *)summaryValues
            completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, QLFEncryptedVaultItem *encryptedVaultItem, NSError *error))completionHandler
{

    QLFVaultSequenceValue newSequenceValue = [_vaultSequenceCache nextSequenceValue];

    QredoVaultItemMetadata *metadata = vaultItem.metadata;

    QLFVaultItemRef *vaultItemDescriptor =
    [QLFVaultItemRef vaultItemRefWithVaultId:_vaultKeys.vaultId
                                  sequenceId:_sequenceId
                               sequenceValue:newSequenceValue
                                      itemId:itemId];
    
    QredoUTCDateTime* createdDate = [[QredoUTCDateTime alloc] initWithDate: created];


    QLFVaultItemMetadata *vaultItemMetaDataLF =
    [QLFVaultItemMetadata vaultItemMetadataWithDataType:dataType
                                                created: createdDate
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
        completionHandler(nil, nil, error);
        return;
    }

    [_vaultService putItemWithItem:encryptedVaultItem
                  signature:ownershipSignature
          completionHandler:^void(BOOL result, NSError *error)
     {
         if (result && !error) {
           
             @synchronized(_vaultSequenceCache) {
                 [_vaultSequenceCache setItemSequence:itemId
                                       sequenceId:_sequenceId
                                    sequenceValue:newSequenceValue];
             }
             QredoMutableVaultItemMetadata *newMetadata = [metadata mutableCopy];
             newMetadata.origin = QredoVaultItemOriginServer;
             newMetadata.descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:_sequenceId
                                                                                    sequenceValue:newSequenceValue
                                                                                           itemId:itemId];

             completionHandler(newMetadata, encryptedVaultItem, nil);
         } else {
             completionHandler(nil, nil, error);
         }
     }];
}





- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                    completionHandler:(void(^)(NSError *error))completionHandler
                     watermarkHandler:(void(^)(QredoVaultHighWatermark *watermark))watermarkHandler
                                since:(QredoVaultHighWatermark*)sinceWatermark
                 consolidatingResults:(BOOL)shouldConsolidateResults{
    
    __block int vaultItemCount =0;
    __block QredoVaultHighWatermark *highWaterMark;

    [self enumerateVaultItemsPagedUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        vaultItemCount++;
        if (block)block(vaultItemMetadata, stop);
       
    } completionHandler:^(NSError *error) {
        if (vaultItemCount>0){
            //maybe some more vault items - recurse
            [self enumerateVaultItemsUsingBlock:block
                              completionHandler:completionHandler
                               watermarkHandler:watermarkHandler
                                          since:highWaterMark consolidatingResults:shouldConsolidateResults];
        }else{
 
            if (completionHandler)completionHandler(error);
       }
 

    } watermarkHandler:^(QredoVaultHighWatermark *vaultHighWaterMark){
        highWaterMark =vaultHighWaterMark;
        if (watermarkHandler)watermarkHandler(vaultHighWaterMark);
    } since:sinceWatermark consolidatingResults:shouldConsolidateResults];
    
}




// this is private method that also returns highWatermark. Used in the polling data
- (void)enumerateVaultItemsPagedUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
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
    [_vaultService queryItemHeadersWithVaultId:_vaultKeys.vaultId
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
                                                                       created:decryptedItem.created.asDate
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
                     // Om nom nom.
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
                 [self enumerateVaultItemsPagedUsingBlock:block
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

@end