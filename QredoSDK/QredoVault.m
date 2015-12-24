/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoVault.h"
#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoVaultSequenceCache.h"
#import "QredoLocalIndexPrivate.h"

#import "NSDictionary+QUIDSerialization.h"
#import "NSDictionary+IndexableSet.h"
#import "QredoVaultCrypto.h"
#import "QredoCrypto.h"
#import "QredoLogging.h"
#import "QredoKeychain.h"

#import "QredoUpdateListener.h"

#import "QredoObserverList.h"

#import "QredoVaultServerAccess.h"
#import "QredoLocalIndexDataStore.h"



NSString *const QredoVaultOptionSequenceId = @"com.qredo.vault.sequence.id.";
NSString *const QredoVaultOptionHighWatermark = @"com.qredo.vault.hwm";

static NSString *const QredoVaultItemMetadataItemDateCreated = @"_created";
static NSString *const QredoVaultItemMetadataItemDateModified = @"_modified";
static NSString *const QredoVaultItemMetadataItemVersion = @"_v";

NSString *const QredoVaultItemMetadataItemTypeTombstone = @"\u220E"; // U+220E END OF PROOF, https://github.com/Qredo/design-docs/wiki/Vault-Item-Tombstone
static NSString *const QredoVaultItemMetadataItemTypeRendezvous = @"com.qredo.rendezvous";
static NSString *const QredoVaultItemMetadataItemTypeConversation = @"com.qredo.conversation";

static const double kQredoVaultUpdateInterval = 1.0; // seconds


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
    
    QredoLocalIndex *_localIndex;
    QredoVaultHighWatermark *_savedHighWaterMark;;

}

- (void)saveState;
- (void)loadState;
- (void)clearState;

@end

@implementation QredoVault (Private)




- (QredoLocalIndex *)localIndex{
    return _localIndex;
}

- (QredoVaultKeys *)vaultKeys
{
    return _vaultKeys;
}

- (QredoQUID *)sequenceId
{
    return _sequenceId;
}

- (instancetype)initWithClient:(QredoClient *)client vaultKeys:(QredoVaultKeys *)vaultKeys withLocalIndex:(BOOL)localIndexing
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

    _localIndex = (localIndexing)?[[QredoLocalIndex alloc] initWithVault:self]:nil;
    
    
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
                      created:(NSDate*)created
                summaryValues:(NSDictionary *)summaryValues
            completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    
    [_vaultServerAccess putUpdateOrDeleteItem:vaultItem
                                       itemId:itemId
                                     dataType:dataType
                                      created:created
                                summaryValues:summaryValues
                            completionHandler:^(QredoVaultItemMetadata *newItemMetadata, QLFEncryptedVaultItem *encryptedVaultItem, NSError *error)
    {
        QredoMutableVaultItemMetadata *newMetadata = [vaultItem.metadata mutableCopy];
        newMetadata.origin = QredoVaultItemOriginServer;
        newMetadata.descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:_sequenceId
                                                                               sequenceValue:newItemMetadata.descriptor.sequenceValue
                                                                                      itemId:itemId];
        
        [self cacheInIndexVaultItem:vaultItem metadata:newMetadata completionHandler:^(NSError *error) {
            completionHandler(newMetadata, nil);
        }];
    }];
}

- (void)strictlyPutNewItem:(QredoVaultItem *)vaultItem
         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler{
    QredoQUID *itemId;
    if (vaultItem.metadata.descriptor.itemId){
     itemId = vaultItem.metadata.descriptor.itemId;
    }else{
        itemId = [QredoQUID QUID];
    }
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    
    NSDate* created = [NSDate date];
    // TO DO keep the creation date in the summary values for now since it's used elsewhere
    newSummaryValues[QredoVaultItemMetadataItemDateCreated] = created;
    [self putUpdateOrDeleteItem:vaultItem
                         itemId:itemId
                       dataType:metadata.dataType
                        created:created
                  summaryValues:newSummaryValues
                    completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
                        
                        [self cacheInIndexVaultItem:vaultItem  metadata:newItemMetadata  completionHandler:^(NSError *error) {
                                completionHandler(newItemMetadata, error);
                         }];
                        
      }];
}


- (void)strictlyUpdateItem:(QredoVaultItem *)vaultItem
         completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata, NSError *error))completionHandler
{
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    QredoQUID *itemId = metadata.descriptor.itemId;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    NSDate *created = [NSDate date];
    
    //TO DO- keep the date in the summary values for now since it's used elsewhere
    newSummaryValues[QredoVaultItemMetadataItemDateModified] = created;
    newSummaryValues[QredoVaultItemMetadataItemVersion] = @(metadata.descriptor.sequenceValue);
    [self putUpdateOrDeleteItem:vaultItem
                         itemId:itemId
                       dataType:metadata.dataType
                        created:created
                  summaryValues:newSummaryValues
              completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error) {
                  [self cacheInIndexVaultItem:vaultItem metadata:newItemMetadata completionHandler:^(NSError *error) {
                 completionHandler(newItemMetadata, error);
            }];
     }];
}


#pragma mark Cache

- (void)clearAllData
{
    [self clearState];
    [_vaultSequenceCache clear];
}



-(void)cacheInIndexVaultItem:(QredoVaultItem *)vaultItem
                    metadata:(QredoVaultItemMetadata *)metadata
           completionHandler:(void (^)(NSError *error))completionHandler{
    vaultItem.metadata.descriptor = metadata.descriptor;
    [_localIndex putVaultItem:vaultItem];
    if (completionHandler)completionHandler(nil);
}


//-(void)cacheInIndexMetadata:(QredoVaultItem *)vaultItem
//           completionHandler:(void (^)(NSError *error))completionHandler{
//    [_localIndex putVaultItem:vaultItem];
//    if (completionHandler)completionHandler(nil);
//}


- (void)removeBodyFromCacheWithVaultItemDescriptor:(QredoVaultItemDescriptor *)descriptor
                                 completionHandler:(void (^)(NSError *error))completionHandler{
    NSError *error = nil;
    [_localIndex deleteItem:descriptor error:error];
    if (completionHandler)completionHandler(error);
    
}



@end

@implementation QredoVault



- (QredoQUID *)vaultId
{
    return _vaultKeys.vaultId;
}


- (void)getItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
            completionHandler:(void(^)(QredoVaultItem *vaultItem, NSError *error))completionHandler{
    
    QredoVaultItem *vaultItem = [self.localIndex getVaultItemFromIndexWithDescriptor:itemDescriptor];
    if (vaultItem){
        completionHandler(vaultItem,nil);
    }else{
         [_vaultServerAccess getItemWithDescriptor:itemDescriptor completionHandler:completionHandler];
    }
    
}


- (void)getItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                    completionHandler:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, NSError *error))completionHandler{
    
    QredoVaultItemMetadata *metadata = [self.localIndex getMetadataFromIndexWithDescriptor:itemDescriptor];
    if (metadata){
        completionHandler(metadata,nil);
    }else{
        [_vaultServerAccess getItemMetadataWithDescriptor:itemDescriptor completionHandler:completionHandler];
    }
}




- (void)addVaultObserver:(id<QredoVaultObserver>)observer
{
    
    QredoUpdateListener *updateListener = _updateListener;
    [_observers addObserver:observer];
    
    if (!_updateListener.isListening) {
        [_updateListener startListening];
    }

    //if _localIndex is active and the localIndex is not already listening to updates, add the localIndex as an observer
    if (_localIndex &&  ![_observers contains:_localIndex]){
        [_observers addObserver:_localIndex];
    }
   
}

- (void)removeVaultObserver:(id<QredoVaultObserver>)observer{
    QredoUpdateListener *updateListener = _updateListener;
    QredoObserverList *observers = _observers;
    
    NSLog(@"removeVaultObserver: [_observers count]: %@, _updateListener.isListening: %@", @([_observers count]), _updateListener.isListening ? @"YES" : @"NO");
    NSLog(@"_observers: %@", _observers);

    //If we have just removed a listener and the  only listener left is the localIndex - remove it.
    if ([observers count]==1 && [_observers contains:_localIndex])[_observers removeObserver:_localIndex];
    
    if ([observers count] < 1 && _updateListener.isListening) {
        [_updateListener stopListening];
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
    
 //   NSAssert(isNewItemFromDateCreated == isNewItemFromDescriptor, @"Can not determine whether the item is newely created or not.");
    
    if (isNewItemFromDateCreated) {
        [self strictlyPutNewItem:vaultItem completionHandler:completionHandler];
    }
    else {
        [self strictlyUpdateItem:vaultItem completionHandler:completionHandler];
    }
}



- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                    completionHandler:(void(^)(NSError *error))completionHandler{
    [self enumerateVaultItemsUsingBlock:block since:QredoVaultHighWatermarkOrigin completionHandler:completionHandler];
}

- (void)enumerateVaultItemsUsingBlock:(void(^)(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop))block
                                since:(QredoVaultHighWatermark*)sinceWatermark
                    completionHandler:(void(^)(NSError *error))completionHandler{
    dispatch_async(_queue, ^{
        [_vaultServerAccess enumerateVaultItemsUsingBlock:block completionHandler:completionHandler watermarkHandler:nil since:sinceWatermark consolidatingResults:YES];
        
    });
}


- (void)deleteItem:(QredoVaultItemMetadata *)metadata completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor, NSError *error))completionHandler
{

    QredoQUID *itemId = metadata.descriptor.itemId;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionary];
    newSummaryValues[QredoVaultItemMetadataItemDateCreated] = metadata.summaryValues[QredoVaultItemMetadataItemDateCreated];
    
    //TO DO modified not used any more so shouldn't be in summary values ?
    NSDate* created = [NSDate date];
    newSummaryValues[QredoVaultItemMetadataItemDateModified] = created;
    newSummaryValues[QredoVaultItemMetadataItemVersion] = @(metadata.descriptor.sequenceValue); // TODO: not working for int64
    [self putUpdateOrDeleteItem:[QredoVaultItem vaultItemWithMetadata:metadata value:[NSData data]]
                         itemId:itemId
                       dataType:QredoVaultItemMetadataItemTypeTombstone
                        created:created
                  summaryValues:newSummaryValues
              completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error){
              if (newItemMetadata) {
                  [self removeBodyFromCacheWithVaultItemDescriptor:metadata.descriptor
                                                 completionHandler:^(NSError *cacheError){
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
#pragma QredoLocalIndex methods

-(void)enumerateIndexUsingPredicate:(NSPredicate *)predicate withBlock:(void (^)(QredoVaultItemMetadata *, BOOL *))block
                  completionHandler:(void (^)(NSError *))completionHandler{
    [self.localIndex enumerateSearch:predicate withBlock:block completionHandler:completionHandler];
}


-(void)addMetadataIndexObserver{
    [self.localIndex enableSync];
}

-(void)addMetadataIndexObserver:(IncomingMetadataBlock)block{
    [self.localIndex enableSyncWithBlock:block];
}


-(void)removeMetadataIndexObserver{
    [self.localIndex removeIndexObserver];
}

-(int)indexSize{
  return [self.localIndex count];
}


-(NSManagedObjectContext*)indexManagedObjectContext{
    return [[QredoLocalIndexDataStore sharedQredoLocalIndexDataStore] managedObjectContext];
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

- (void)qredoUpdateListener:(QredoUpdateListener *)updateListener unsubscribeWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    // TODO: DH - No current way to stop subscribing, short of disconnecting from server. Services team may add support for this in future.
    NSLog(@"QredoVault: unsubscribeWithCompletionHandler"); // <- not called
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
