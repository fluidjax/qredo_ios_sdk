/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoVault.h"
#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoVaultSequenceCache.h"
#import "QredoLocalIndex.h"

#import "NSDictionary+QUIDSerialization.h"
#import "NSDictionary+IndexableSet.h"
#import "QredoVaultCrypto.h"
#import "QredoCrypto.h"
#import "QredoLoggerPrivate.h"
#import "QredoKeychain.h"

#import "QredoUpdateListener.h"
#import "QredoObserverList.h"
#import "QredoVaultServerAccess.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoNetworkTime.h"


NSString *const QredoVaultOptionSequenceId = @"com.qredo.vault.sequence.id.";
NSString *const QredoVaultOptionHighWatermark = @"com.qredo.vault.hwm";
static NSString *const QredoVaultItemMetadataItemDateCreated = @"_created";
static NSString *const QredoVaultItemMetadataItemDateModified = @"_modified";
static NSString *const QredoVaultItemMetadataItemVersion = @"_v";
static NSString *const QredoVaultItemMetadataItemTypeRendezvous = @"com.qredo.rendezvous";
static NSString *const QredoVaultItemMetadataItemTypeConversation = @"com.qredo.conversation";
static const double kQredoVaultUpdateInterval = 1.0; //seconds


@interface QredoVault () <QredoUpdateListenerDataSource,QredoUpdateListenerDelegate>{
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
    QredoUserCredentials *_userCredentials;
    QredoVaultType _vaultType;
}

-(void)saveState;
-(void)loadState;
-(void)clearState;

@end

@implementation QredoVault (Private)



-(BOOL)isSystemVault{
    return _vaultType==QredoSystemVault;
}

-(QredoUserCredentials *)userCredentials {
    return _userCredentials;
}


-(void)setUserCredentials:(QredoUserCredentials *)userCredentials {
    _userCredentials = userCredentials;
}


-(void)addMetadataIndexObserver {
    [self.localIndex enableSync];
}


-(void)addMetadataIndexObserver:(IncomingMetadataBlock)block {
    [self.localIndex enableSyncWithBlock:block];
}


-(void)removeMetadataIndexObserver {
    [self.localIndex removeIndexObserver];
}


-(QredoLocalIndex *)localIndex {
    return _localIndex;
}


-(QredoVaultKeys *)vaultKeys {
    return _vaultKeys;
}


-(QredoQUID *)sequenceId {
    return _sequenceId;
}


-(instancetype)initWithClient:(QredoClient *)client vaultKeys:(QredoVaultKeys *)vaultKeys withLocalIndex:(BOOL)localIndexing vaultType:(QredoVaultType)vaultType{
    if (!client || !vaultKeys)return nil;
    
    self = [super init];
    
    
    
    if (!self)return nil;
    
    _vaultType = vaultType;
    _vaultKeys = vaultKeys;
    _userCredentials = client.userCredentials;
    _highwatermark = QredoVaultHighWatermarkOrigin;
    
    _observers = [[QredoObserverList alloc] init];
    
    _queue = dispatch_queue_create("com.qredo.vault.updates",nil);
    
    [self loadState];
    
    if (!_sequenceId){
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
    
    _localIndex = (localIndexing) ? [[QredoLocalIndex alloc] initWithVault:self] : nil;
    
    
    return self;
}


-(QredoQUID *)itemIdWithName:(NSString *)name type:(NSString *)type {
    NSString *constructedName = [NSString stringWithFormat:@"%@.%@@%@",[self.vaultId QUIDString],name,type];
    NSData *hash = [QredoCrypto sha256:[constructedName dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [[QredoQUID alloc] initWithQUIDData:hash];
}


-(QredoQUID *)itemIdWithQUID:(QredoQUID *)quid type:(NSString *)type {
    return [self itemIdWithName:[quid QUIDString] type:type];
}


-(void)putUpdateOrDeleteItem:(QredoVaultItem *)vaultItem
                      itemId:(QredoQUID *)itemId
                    dataType:(NSString *)dataType
                     created:(NSDate *)created
               summaryValues:(NSDictionary *)summaryValues
           completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata,NSError *error))completionHandler {
    [_vaultServerAccess putUpdateOrDeleteItem:vaultItem
                                       itemId:itemId
                                     dataType:dataType
                                      created:created
                                summaryValues:summaryValues
                            completionHandler:^(QredoVaultItemMetadata *newItemMetadata,QLFEncryptedVaultItem *encryptedVaultItem,NSError *error)
     {
         QredoMutableVaultItemMetadata *newMetadata = [vaultItem.metadata mutableCopy];
         newMetadata.origin = QredoVaultItemOriginServer;
         newMetadata.dataType = newItemMetadata.dataType;
         newMetadata.descriptor = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:_sequenceId
                                                                                sequenceValue:newItemMetadata.descriptor.sequenceValue
                                                                                       itemId:itemId];
         
         if (completionHandler) completionHandler(newMetadata,error);
     }];
}


-(void)strictlyPutNewItem:(QredoVaultItem *)vaultItem
        completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata,NSError *error))completionHandler {
    QredoQUID *itemId;
    
    if (vaultItem.metadata.descriptor.itemId){
        itemId = vaultItem.metadata.descriptor.itemId;
    } else {
        itemId = [QredoQUID QUID];
    }
    
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    
    NSDate *created = [QredoNetworkTime dateTime];
    //TO DO keep the creation date in the summary values for now since it's used elsewhere
    newSummaryValues[QredoVaultItemMetadataItemDateCreated] = created;
    [self putUpdateOrDeleteItem:vaultItem
                         itemId:itemId
                       dataType:metadata.dataType
                        created:created
                  summaryValues:newSummaryValues
              completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
                  if (error){
                      //we failed to send the item to the server - dont put it in the local index
                      QredoLogError(@"Failed to send vault item to server itemID=%@",itemId);
                      
                      if (completionHandler) completionHandler(newItemMetadata,error);
                  } else {
                      QredoLogInfo(@"Put New Item VaultItem:%@ vaultID:%@",itemId,self.vaultId);
                      [self cacheInIndexVaultItem:vaultItem
                                         metadata:newItemMetadata
                                completionHandler:^(NSError *error) {
                                    if (completionHandler) completionHandler(newItemMetadata,error);
                                }];
                  }
              }];
}


-(void)strictlyUpdateItem:(QredoVaultItem *)vaultItem
        completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata,NSError *error))completionHandler {
    QredoVaultItemMetadata *metadata = vaultItem.metadata;
    QredoQUID *itemId = metadata.descriptor.itemId;
    
    QredoLogDebug(@"Update VaultItem:%@",itemId);
    
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionaryWithDictionary:metadata.summaryValues];
    NSDate *created = [QredoNetworkTime dateTime];
    
    //TO DO- keep the date in the summary values for now since it's used elsewhere
    newSummaryValues[QredoVaultItemMetadataItemDateModified] = created;
    newSummaryValues[QredoVaultItemMetadataItemVersion] = @(metadata.descriptor.sequenceValue);
    
    [self putUpdateOrDeleteItem:vaultItem
                         itemId:itemId
                       dataType:metadata.dataType
                        created:created
                  summaryValues:newSummaryValues
              completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
                  if (error){
                      //we failed to send the item to the server - dont put it in the local index
                      QredoLogError(@"Failed to send vault item to server itemID=%@",itemId);
                      
                      if (completionHandler) completionHandler(newItemMetadata,error);
                  } else {
                      [self cacheInIndexVaultItem:vaultItem
                                         metadata:newItemMetadata
                                completionHandler:^(NSError *error) {
                                    if (completionHandler) completionHandler(newItemMetadata,error);
                                }];
                  }
              }];
}


#pragma mark Cache

-(void)clearAllData {
    [self clearState];
    [_vaultSequenceCache clear];
}


-(void)cacheInIndexVaultItemMetadata:(QredoVaultItemMetadata *)metadata
                   completionHandler:(void (^)(NSError *error))completionHandler {
    //this logger message displays the source of the data (index or server)
    QredoLogDebug(@"Put metadata in index");
    [_localIndex putMetadata:metadata];
    
    if (completionHandler)completionHandler(nil);
}


-(void)cacheInIndexVaultItem:(QredoVaultItem *)vaultItem
                    metadata:(QredoVaultItemMetadata *)metadata
           completionHandler:(void (^)(NSError *error))completionHandler {
    vaultItem.metadata.descriptor = metadata.descriptor;
    
    if (vaultItem.metadata.descriptor.itemId){
        //this logger message displays the source of the data (index or server)
        QredoLogDebug(@"Put vault item in index %@",^{
            NSString *source;
            
            if (metadata.origin == QredoVaultItemOriginServer)source = @"Server";
            
            if (metadata.origin == QredoVaultItemOriginCache)source = @"Index";
            
            return [NSString stringWithFormat:@" Origin:%@  ItemId:%@",source,vaultItem.metadata.descriptor.itemId];
        } ());
        [_localIndex putVaultItem:vaultItem metadata:metadata];
    }
    
    if (completionHandler)completionHandler(nil);
}


-(void)removeBodyFromCacheWithVaultItemDescriptor:(QredoVaultItemDescriptor *)descriptor
                                completionHandler:(void (^)(NSError *error))completionHandler {
    NSError *error = nil;
    
    QredoLogDebug(@"Remove vault payload from Index %@",descriptor.itemId);
    [_localIndex deleteItem:descriptor error:&error];
    
    if (completionHandler)completionHandler(error);
}


-(void)removeAllObservers {
    QredoObserverList *observers = _observers;
    
    [observers removeAllObservers];
    
    if (_updateListener.isListening)[_updateListener stopListening];
}


@end

@implementation QredoVault



-(QredoQUID *)vaultId {
    return _vaultKeys.vaultId;
}


-(void)getLatestItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                 completionHandler:(void (^)(QredoVaultItem *vaultItem,NSError *error))completionHandler {
    //ItemID specified but ignore SequenceID=nil & SequenceValue=0
    //It will retrieve the latest value available from the cache and return
    //If item is not in the cache goes to the server and retrieves the specified sequence state
    //If the latest item is a deleted item it will return nil
    QredoVaultItem *vaultItem = [self.localIndex getLatestVaultItemFromIndexWithDescriptor:itemDescriptor];
    
    
    
    //if item in in the index
    if (vaultItem){
        //if the metadata is a tombstone return nil
        if ([vaultItem.metadata isDeleted])vaultItem = nil;
        
        QredoLogInfo(@"Retrieved VaultItem from Index");
        
        if (completionHandler)completionHandler(vaultItem,nil);
        
        return;
    }
    
    //get from the server
    [_vaultServerAccess getItemWithDescriptor:itemDescriptor
                            completionHandler:^(QredoVaultItem *vaultItem,NSError *error) {
                                __block QredoVaultItem *serverVaultItem = vaultItem;
                                
                                if (serverVaultItem){
                                    [self cacheInIndexVaultItem:serverVaultItem
                                                       metadata:serverVaultItem.metadata
                                              completionHandler:^(NSError *error) {
                                                  if ([serverVaultItem.metadata isDeleted]) serverVaultItem = nil;
                                                  
                                                  if (completionHandler) completionHandler(serverVaultItem,error);
                                              }];
                                } else {
                                    if (completionHandler) completionHandler(nil,error);
                                }
                            }];
}


-(void)getLatestItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                         completionHandler:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,NSError *error))completionHandler {
    //ItemID specified but ignore SequenceID=nil & SequenceValue=0
    //It will retrieve the latest value available from the cache and return
    //If item is not in the cache goes to the server and retrieves the specified sequence state
    //If the latest item is a deleted item it will return nil
    
    QredoVaultItemMetadata *vaultItemMetadata = [self.localIndex getLatestMetadataFromIndexWithDescriptor:itemDescriptor];
    
    
    //if in the index
    if (vaultItemMetadata){
        if ([vaultItemMetadata isDeleted])vaultItemMetadata = nil;
        
        QredoLogInfo(@"Retrieved VaultItem from Index");
        
        if (completionHandler)completionHandler(vaultItemMetadata,nil);
        
        return;
    }
    
    //get from the server
    [_vaultServerAccess getItemMetadataWithDescriptor:itemDescriptor
                                    completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata,NSError *error) {
                                        if (error){
                                            QredoLogWarning(@"VaultMetadata not found on server");
                                            
                                            if (completionHandler) completionHandler(nil,error);
                                            
                                            return;
                                        }
                                        
                                        __block QredoVaultItemMetadata *serverMetaData = vaultItemMetadata;
                                        [self  cacheInIndexVaultItemMetadata:serverMetaData
                                                           completionHandler:^(NSError *error) {
                                                               if ([serverMetaData isDeleted]) serverMetaData = nil;
                                                               
                                                               QredoLogVerbose(@"VaultMetadata added to cache");
                                                               
                                                               if (completionHandler) completionHandler(serverMetaData,error);
                                                               
                                                               return;
                                                           }];
                                    }];
}


-(void)getItemWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
           completionHandler:(void (^)(QredoVaultItem *vaultItem,NSError *error))completionHandler {
    //If Item specified is in the cache returns it.
    //If not in cache retrieve from server
    //If deleted (tombstoned item) return nil
    
    QredoVaultItem *vaultItem = [self.localIndex getVaultItemFromIndexWithDescriptor:itemDescriptor];
    
    if (vaultItem){
        if ([vaultItem.metadata isDeleted])vaultItem = nil;
        
        QredoLogInfo(@"Retrieved VaultItem from Index");
        
        if (completionHandler)completionHandler(vaultItem,nil);
        
        return;
    } else {
        QredoLogInfo(@"Retrieved VaultItem from server");
        [_vaultServerAccess getItemWithDescriptor:itemDescriptor
                                completionHandler:^(QredoVaultItem *vaultItem,NSError *error) {
                                    //we can now put it in the cache
                                    if (error.code == QredoErrorCodeVaultItemHasBeenDeleted || [vaultItem.metadata isDeleted] == YES){
                                        //special case of item deleted - cache and return nil
                                        [self cacheInIndexVaultItem:vaultItem
                                                           metadata:vaultItem.metadata
                                                  completionHandler:^(NSError *cacheError) {
                                                      QredoLogVerbose(@"deleted vaultItem added to cache");
                                                      
                                                      if (completionHandler) completionHandler(nil,error);
                                                  }];
                                        return;
                                    } else if (error){
                                        QredoLogWarning(@"VaultItem not found on server");
                                        
                                        if (completionHandler) completionHandler(vaultItem,error);
                                        
                                        return;
                                    } else {
                                        [self cacheInIndexVaultItem:vaultItem
                                                           metadata:vaultItem.metadata
                                                  completionHandler:^(NSError *error) {
                                                      QredoLogVerbose(@"vaultItem added to cache");
                                                      
                                                      if (completionHandler) completionHandler(vaultItem,error);
                                                      
                                                      return;
                                                  }];
                                    }
                                }];
    }
}


-(void)getItemMetadataWithDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                   completionHandler:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,NSError *error))completionHandler {
    QredoVaultItemMetadata *metadata = [self.localIndex getMetadataFromIndexWithDescriptor:itemDescriptor];
    
    if (metadata){
        if ([metadata isDeleted])metadata = nil;
        
        QredoLogInfo(@"Retrieved VaultMetadata from Index");
        
        if (completionHandler)completionHandler(metadata,nil);
    } else {
        QredoLogInfo(@"Retrieved VaultMetadata from server");
        [_vaultServerAccess getItemMetadataWithDescriptor:itemDescriptor
                                        completionHandler:^(QredoVaultItemMetadata *vaultItemMetadata,NSError *error) {
                                            if (error.code == QredoErrorCodeVaultItemHasBeenDeleted || [vaultItemMetadata isDeleted] == YES){
                                                //special case of item deleted - cache and return nil
                                                [self cacheInIndexVaultItemMetadata:vaultItemMetadata
                                                                  completionHandler:^(NSError *error) {
                                                                      QredoLogVerbose(@"deleted vaultItemMetadata added to cache");
                                                                      
                                                                      if (completionHandler) completionHandler(vaultItemMetadata,error);
                                                                  }];
                                            } else if (error){
                                                QredoLogWarning(@"VaultMetadata not found on server");
                                                
                                                if (completionHandler) completionHandler(vaultItemMetadata,error);
                                            } else {
                                                [self cacheInIndexVaultItemMetadata:vaultItemMetadata
                                                                  completionHandler:^(NSError *error) {
                                                                      QredoLogVerbose(@"VaultMetadata added to cache");
                                                                      
                                                                      if (completionHandler) completionHandler(vaultItemMetadata,error);
                                                                  }];
                                            }
                                        }];
    }
}


-(void)addVaultObserver:(id<QredoVaultObserver>)observer {
    QredoLogDebug(@"Add vault Observer %@",observer);
    
    [_observers addObserver:observer];
    
    if (!_updateListener.isListening){
        [_updateListener startListening];
    }
    
    //if _localIndex is active and the localIndex is not already listening to updates, add the localIndex as an observer
    if (_localIndex &&  ![_observers contains:_localIndex]){
        [_observers addObserver:_localIndex];
    }
}


-(void)removeVaultObserver:(id<QredoVaultObserver>)observer {
    QredoLogDebug(@"Remove vault Observer %@",observer);
    QredoObserverList *observers = _observers;
    
    //If we have just removed a listener and the  only listener left is the localIndex - remove it.
    if ([observers count] == 1 && [_observers contains:_localIndex])[_observers removeObserver:_localIndex];
    
    if ([observers count] < 1 && _updateListener.isListening){
        [_updateListener stopListening];
    }
}


-(void)notifyObservers:(void (^)(id<QredoVaultObserver> observer))notificationBlock {
    [_observers notifyObservers:notificationBlock];
}


-(void)resetWatermark {
    QredoLogInfo(@"Reset Watermark");
    _highwatermark = nil;
    [self saveState];
}


-(void)updateItem:(QredoVaultItemMetadata *)metadata value:(NSData *)value
    completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata,NSError *error))completionHandler {
    //this builds a new vault item metadata removes the SequenceValue (Num & Value) from the descriptor
    //QredoQUID *itemID = metadata.descriptor.itemId;
    //QredoVaultItemDescriptor *deSequencedDescriptor = [[QredoVaultItemDescriptor alloc] initWithSequenceId:nil sequenceValue:0 itemId:itemID];
    //QredoVaultItemMetadata *newMetadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:metadata.summaryValues];
    //newMetadata.descriptor = deSequencedDescriptor;
    QredoVaultItem *cleanedVaultItem = [[QredoVaultItem alloc] initWithMetadata:metadata value:value];
    
    [self strictlyUpdateItem:cleanedVaultItem completionHandler:completionHandler];
}


-(void)putItem:(QredoVaultItem *)vaultItem completionHandler:(void (^)(QredoVaultItemMetadata *newItemMetadata,NSError *error))completionHandler {
    BOOL isNewItemFromDateCreated = vaultItem.metadata.summaryValues[QredoVaultItemMetadataItemDateCreated] == nil;
    
    //BOOL isNewItemFromDescriptor = vaultItem.metadata.descriptor == nil;
    
    //NSAssert(isNewItemFromDateCreated == isNewItemFromDescriptor, @"Can not determine whether the item is newely created or not.");
    
    if (isNewItemFromDateCreated){
        [self strictlyPutNewItem:vaultItem completionHandler:completionHandler];
    } else {
        [self strictlyUpdateItem:vaultItem completionHandler:completionHandler];
    }
}


//Enumerate the vault items from the server without Consolidation - ie. All Verisions - deleted & historic

-(void)enumerateVaultItemsAllVersionsUsingBlock:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop))block
                              completionHandler:(void (^)(NSError *error))completionHandler {
    [self enumerateVaultItemsAllVersionsUsingBlock:block since:QredoVaultHighWatermarkOrigin completionHandler:completionHandler];
}


-(void)enumerateVaultItemsAllVersionsUsingBlock:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop))block
                                          since:(QredoVaultHighWatermark *)sinceWatermark
                              completionHandler:(void (^)(NSError *error))completionHandler {
    dispatch_async(_queue,^{
        [_vaultServerAccess enumerateVaultItemsUsingBlock:block completionHandler:completionHandler watermarkHandler:nil since:sinceWatermark consolidatingResults:NO];
    });
}


-(void)enumerateVaultItemsUsingBlock:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop))block
                   completionHandler:(void (^)(NSError *error))completionHandler {
    [self enumerateVaultItemsUsingBlock:block since:QredoVaultHighWatermarkOrigin completionHandler:completionHandler];
}


-(void)enumerateVaultItemsUsingBlock:(void (^)(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop))block
                               since:(QredoVaultHighWatermark *)sinceWatermark
                   completionHandler:(void (^)(NSError *error))completionHandler {
    dispatch_async(_queue,^{
        [_vaultServerAccess enumerateVaultItemsUsingBlock:block completionHandler:completionHandler watermarkHandler:nil since:sinceWatermark consolidatingResults:YES];
    });
}


-(void)deleteItem:(QredoVaultItemMetadata *)metadata completionHandler:(void (^)(QredoVaultItemDescriptor *newItemDescriptor,NSError *error))completionHandler {
    QredoQUID *itemId = metadata.descriptor.itemId;
    NSMutableDictionary *newSummaryValues = [NSMutableDictionary dictionary];
    
    newSummaryValues[QredoVaultItemMetadataItemDateCreated] = metadata.summaryValues[QredoVaultItemMetadataItemDateCreated];
    
    //TO DO modified not used any more so shouldn't be in summary values ?
    NSDate *created = [QredoNetworkTime dateTime];
    newSummaryValues[QredoVaultItemMetadataItemDateModified] = created;
    newSummaryValues[QredoVaultItemMetadataItemVersion] = @(metadata.descriptor.sequenceValue); //TODO: not working for int64
    [self putUpdateOrDeleteItem:[QredoVaultItem vaultItemWithMetadata:metadata
                                                                value:[NSData data]]
                         itemId:itemId
                       dataType:QredoVaultItemMetadataItemTypeTombstone
                        created:created
                  summaryValues:newSummaryValues
              completionHandler:^(QredoVaultItemMetadata *newItemMetadata,NSError *error) {
                  if (newItemMetadata){
                      [self cacheInIndexVaultItemMetadata:newItemMetadata
                                        completionHandler:^(NSError *error) {
                                            if (completionHandler) completionHandler(newItemMetadata.descriptor,error);
                                        }];
                      
                      //[self removeBodyFromCacheWithVaultItemDescriptor:metadata.descriptor
                      //completionHandler:^(NSError *cacheError){
                      //if (completionHandler)completionHandler(newItemMetadata.descriptor, error);
                      //}];
                  } else {
                      if (completionHandler) completionHandler(nil,error);
                  }
                  
                  QredoLogInfo(@"Delete item complete");
              }];
}


-(QredoVaultHighWatermark *)highWatermark {
    return _highwatermark;
}


-(NSString *)sequenceIdKeyForDefaults {
    return [QredoVaultOptionSequenceId stringByAppendingString:[_vaultKeys.vaultId QUIDString]];
}


-(NSString *)hwmKeyForDefaults {
    return [QredoVaultOptionHighWatermark stringByAppendingString:[_vaultKeys.vaultId QUIDString]];
}


-(void)clearState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults removeObjectForKey:self.sequenceIdKeyForDefaults];
    [defaults removeObjectForKey:self.hwmKeyForDefaults];
    [defaults synchronize];
}


-(void)saveState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[_sequenceId data] forKey:self.sequenceIdKeyForDefaults];
    
    if (_highwatermark){
        [defaults setObject:[_highwatermark.sequenceState quidToStringDictionary] forKey:self.hwmKeyForDefaults];
    } else {
        [defaults removeObjectForKey:self.hwmKeyForDefaults];
    }
    
    [defaults synchronize];
}


-(void)loadState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSData *sequenceIdData = [defaults objectForKey:self.sequenceIdKeyForDefaults];
    
    if (sequenceIdData){
        _sequenceId = [[QredoQUID alloc] initWithQUIDData:sequenceIdData];
    }
    
    NSDictionary *sequenceState = [defaults objectForKey:self.hwmKeyForDefaults];
    
    if (sequenceState){
        _highwatermark = [QredoVaultHighWatermark watermarkWithSequenceState:[sequenceState stringToQuidDictionary]];
    } else {
        _highwatermark = nil;
    }
}




#pragma mark -
#pragma QredoLocalIndex methods

-(void)enumerateIndexUsingPredicate:(NSPredicate *)predicate withBlock:(void (^)(QredoVaultItemMetadata *,BOOL *))block
                  completionHandler:(void (^)(NSError *))completionHandler {
    [self.localIndex enumerateSearch:predicate withBlock:block completionHandler:completionHandler];
}


-(int)indexSize {
    return [self.localIndex count];
}


-(long long)cacheFileSize {
    return [self.localIndex persistentStoreFileSize];
}


-(void)setMaxCacheSize:(long long)maxSize {
    [self.localIndex setMaxCacheSize:maxSize];
}


-(void)metadataCacheEnabled:(BOOL)metadataCacheEnabled {
    [self.localIndex setEnableMetadataCache:metadataCacheEnabled];
}


-(void)valueCacheEnabled:(BOOL)valueCacheEnabled {
    [self.localIndex setEnableValueCache:valueCacheEnabled];
}


-(void)purgeCache {
    [self.localIndex purgeCoreData];
}


-(NSManagedObjectContext *)indexManagedObjectContext {
    return [_localIndex.qredoLocalIndexDataStore managedObjectContext];
}


#pragma mark -
#pragma mark Qredo Update Listener - Data Source

-(BOOL)qredoUpdateListenerDoesSupportMultiResponseQuery:(QredoUpdateListener *)updateListener {
    return NO;
}


#pragma mark Qredo Update Listener - Delegate

-(void)qredoUpdateListener:(QredoUpdateListener *)updateListener pollWithCompletionHandler:(void (^)(NSError *))completionHandler {
    [_vaultServerAccess enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stop) {
        [_updateListener                     processSingleItem:vaultItemMetadata
                                                 sequenceValue:@(vaultItemMetadata.descriptor.sequenceValue)];
    }
                                    completionHandler:completionHandler
                                     watermarkHandler:^(QredoVaultHighWatermark *watermark)
     {
         self->_highwatermark = watermark;
         [self saveState];
     }
                                                since:self.highWatermark
                                 consolidatingResults:NO];
}


-(void)qredoUpdateListener:(QredoUpdateListener *)updateListener unsubscribeWithCompletionHandler:(void (^)(NSError *))completionHandler {
    //TODO: DH - No current way to stop subscribing, short of disconnecting from server. Services team may add support for this in future.
    QredoLogDebug(@"QredoVault: unsubscribeWithCompletionHandler"); //<- not called
}


-(void)qredoUpdateListener:(QredoUpdateListener *)updateListener processSingleItem:(id)item {
    QredoVaultItemMetadata *vaultItemMetadata = (QredoVaultItemMetadata *)item;
    
    [self notifyObservers:^(id < QredoVaultObserver > observer) {
        if ([observer respondsToSelector:@selector(qredoVault:didReceiveVaultItemMetadata:)]){
            [observer qredoVault:self
     didReceiveVaultItemMetadata:vaultItemMetadata];
        }
    }];
}


@end
