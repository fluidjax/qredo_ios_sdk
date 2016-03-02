//
//  QredoLocalIndex.m
//  QredoSDK
//
//  Created by Christopher Morris on 02/12/2015.
//  Manages the Coredata local Metadata index. There are no direct API public methods
//
@import CoreData;
@import UIKit;


#import "QredoPrivate.h"
#import "QredoLocalIndex.h"
#import "QredoVaultPrivate.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoLocalIndexCacheInvalidation.h"
#import "QredoIndexVaultItemMetadata.h"
#import "QredoIndexModel.h"
#import "QredoLoggerPrivate.h"


@interface QredoLocalIndex ()
@property (strong) NSManagedObjectContext *managedObjectContext;
@property (strong) QredoVault *qredoVault;
@property (strong) QredoLocalIndexDataStore *qredoLocalIndexDataStore;


@end


@implementation QredoLocalIndex

IncomingMetadataBlock incomingMetadatBlock;


#pragma mark -
#pragma mark Public Methods


- (instancetype)initWithVault:(QredoVault *)vault {
    self = [super init];
    if (self) {
        self.qredoVault = vault;
        [self initializeCoreData];
        [self addAppObservers];
        self.enableValueCache = YES;
        self.enableMetadataCache = YES;
        self.qredoIndexVault = [QredoIndexVault fetchOrCreateWith:vault inManageObjectContext:self.managedObjectContext];
        self.cacheInvalidator = [[QredoLocalIndexCacheInvalidation alloc] initWithIndexVault:self.qredoIndexVault maxCacheSize:QREDO_DEFAULT_INDEX_CACHE_SIZE];
    }
    return self;
}



- (void)setMaxCacheSize:(long long)cacheSize{
    [self.cacheInvalidator setMaxCacheSize:cacheSize];
    QredoLogDebug(@"Cache max size set to %lld", cacheSize);
}


- (long long)maxCacheSize{
    return self.maxCacheSize;
}



- (void)putMetadata:(QredoVaultItemMetadata *)newMetadata {
    if (self.enableMetadataCache==NO)return;
    [self putItemWithMetadata:newMetadata vaultItem:nil hasVaultItemValue:NO];
}


- (void)putVaultItem:(QredoVaultItem *)vaultItem metadata:(QredoVaultItemMetadata *)metadata{
    if (self.enableMetadataCache==NO)return; //no caching at all
    
    if (self.enableValueCache==NO){
        [self putMetadata:metadata];
    }else{
        NSLog(@"Putting vault item into index %@ %@",vaultItem, metadata);
        [self putItemWithMetadata:metadata vaultItem:vaultItem hasVaultItemValue:YES];
    }
}


- (QredoVaultItem *)getVaultItemFromIndexWithDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor {
    __block QredoVaultItem* retrievedVaultItem = nil;
    [self.managedObjectContext performBlockAndWait:^{
        
        QredoLogInfo(@"vaultItemDescriptor %@", vaultItemDescriptor);

        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItem entityName]];
        NSCompoundPredicate *searchPredicate;
        NSPredicate *itemIdPredicate = [NSPredicate predicateWithFormat:@"itemId == %@",vaultItemDescriptor.itemId.data];
        NSPredicate *vaultIdPredicate = [NSPredicate predicateWithFormat:@"vault.vaultId == %@",self.qredoIndexVault.vaultId];
        
        if (vaultItemDescriptor.sequenceValue) {
            NSPredicate *seqNumPredicate =  [NSPredicate predicateWithFormat:@"latest.descriptor.sequenceValue == %i",vaultItemDescriptor.sequenceValue];
            searchPredicate= [NSCompoundPredicate andPredicateWithSubpredicates:@[vaultIdPredicate, itemIdPredicate, seqNumPredicate]];
        }else{
            searchPredicate= [NSCompoundPredicate andPredicateWithSubpredicates:@[vaultIdPredicate, itemIdPredicate]];
        }
        
        fetchRequest.predicate = searchPredicate;
        fetchRequest.fetchLimit = 1;
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        QredoIndexVaultItem *qredoIndexVaultItem = [results lastObject];
        
        //only return a value if the IndexVaultItem is marked as hasValue=YES, because the value could be intentionally nil
        if (qredoIndexVaultItem.hasValueValue==NO) {
            retrievedVaultItem = nil;
        }else{
            retrievedVaultItem = [qredoIndexVaultItem buildQredoVaultItem];
        }
        
        QredoLogInfo(@"Retrieve item %@ from index", retrievedVaultItem.metadata.descriptor.itemId);
        
        [self.cacheInvalidator updateAccessDate:qredoIndexVaultItem.latest];
        [self save];
        
    }];
    return retrievedVaultItem;
}


- (QredoVaultItemMetadata *)getMetadataFromIndexWithDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor {
    __block QredoVaultItemMetadata* retrievedMetadata = nil;
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItemMetadata entityName]];
        NSCompoundPredicate *searchPredicate;
        NSPredicate *itemIdPredicate = [NSPredicate predicateWithFormat:@"descriptor.itemId == %@",vaultItemDescriptor.itemId.data];
        NSPredicate *vaultIdPredicate = [NSPredicate predicateWithFormat:@"vaultItem.vault.vaultId == %@",self.qredoIndexVault.vaultId];
        
        if (vaultItemDescriptor.sequenceValue) {
            NSPredicate *seqNumPredicate =  [NSPredicate predicateWithFormat:@"descriptor.sequenceValue == %i",vaultItemDescriptor.sequenceValue];
            searchPredicate= [NSCompoundPredicate andPredicateWithSubpredicates:@[vaultIdPredicate, itemIdPredicate, seqNumPredicate]];
        }else{
            searchPredicate= [NSCompoundPredicate andPredicateWithSubpredicates:@[vaultIdPredicate, itemIdPredicate]];
        }
        
        fetchRequest.predicate = searchPredicate;
        
        fetchRequest.fetchLimit = 1;
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        QredoIndexVaultItemMetadata *qredoIndexVaultItemMetadata = [results lastObject];
        retrievedMetadata = [qredoIndexVaultItemMetadata buildQredoVaultItemMetadata];
        QredoLogInfo(@"Retrieve metadata %@ from index", retrievedMetadata.descriptor.itemId);
        
        [self.cacheInvalidator updateAccessDate:qredoIndexVaultItemMetadata];
        
    }];
    return retrievedMetadata;
}


- (int)count {
    __block NSInteger count =0;
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItemMetadata entityName]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"vaultItem.vault.vaultId = %@", self.qredoIndexVault.vaultId];
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        count = [results count];
    }];
    return (int)count;
    
}


- (void)purgeCoreData {
    [self.managedObjectContext performBlockAndWait:^{
        QredoIndexVault *indexVaultToDelete = self.qredoIndexVault;
        self.qredoIndexVault = nil;
        if (indexVaultToDelete) [self.managedObjectContext deleteObject:indexVaultToDelete];
        [self saveAndWait];
    }];
}


- (void)purge {
    [self purgeCoreData];
    [self.managedObjectContext performBlockAndWait:^{
        //rebuild the vault references after deleting the old version
        QredoLogDebug(@"Purge Index for vault:%@", self.qredoVault.vaultId);
        self.qredoIndexVault = [QredoIndexVault fetchOrCreateWith:self.qredoVault inManageObjectContext:self.managedObjectContext];
        self.cacheInvalidator = [[QredoLocalIndexCacheInvalidation alloc] initWithIndexVault:self.qredoIndexVault maxCacheSize:QREDO_DEFAULT_INDEX_CACHE_SIZE];
        [self.qredoVault resetWatermark];
        [self saveAndWait];
    }];
}

- (void)purgeAll{
    [self.managedObjectContext performBlockAndWait:^{
        QredoLogDebug(@"Purge Index for All vaults");
        NSError *error = nil;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVault entityName]];
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        for (QredoIndexVault *qiv in results){
            [self.managedObjectContext deleteObject:qiv];
        }
        [self purge];
        [self saveAndWait];
    }];
}


- (void)enableSync {
    [self.qredoVault addVaultObserver:self];
}


- (void)enableSyncWithBlock:(IncomingMetadataBlock)block {
    incomingMetadatBlock = block;
    [self.qredoVault addVaultObserver:self];
}


- (void)removeIndexObserver {
    [self.qredoVault removeVaultObserver:self];
}


- (BOOL)deleteItem:(QredoVaultItemDescriptor *)vaultItemDescriptor {
    return [self deleteItem:vaultItemDescriptor error:nil];
}


- (BOOL)deleteItem:(QredoVaultItemDescriptor *)vaultItemDescriptor error:(NSError **)returnError {
    __block BOOL hasDeletedObject = NO;
    __block NSError *blockError = nil;
    QredoLogDebug(@"Delete Item from Index");
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexVaultItemMetadata class] entityName]];
        NSPredicate *searchByItemId = [NSPredicate predicateWithFormat:@"descriptor.itemId == %@ && descriptor.sequenceId == %@  && descriptor.sequenceValue == %d ",
                                       vaultItemDescriptor.itemId.data,vaultItemDescriptor.sequenceId.data,vaultItemDescriptor.sequenceValue];
        
//        NSPredicate *searchByItemId = [NSPredicate predicateWithFormat:@"descriptor.itemId == %@ && descriptor.sequenceId == %@",
//                                       vaultItemDescriptor.itemId.data,vaultItemDescriptor.sequenceId.data];

        
        
        fetchRequest.predicate = searchByItemId;
        NSError *error = nil;
        NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error) {
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexErrorUnknown userInfo:@{ NSLocalizedDescriptionKey : @"Failed to retrieve item to delete" }];
        }else if ([items count]==0) {
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexItemNotFound userInfo:@{ NSLocalizedDescriptionKey : @"Item not found in cache" }];
        }else{
            //delete the parent of the found item -
            QredoIndexVaultItemMetadata *itemMetadata = [items lastObject];
            QredoIndexVaultItem *vaultItem = itemMetadata.vaultItem;
            [self.managedObjectContext deleteObject:vaultItem];
            vaultItem.hasValueValue=NO;
            vaultItem.payload.value=nil;
        }
        [self save];
        hasDeletedObject = YES;
    }];
    if (returnError) *returnError = blockError;
    return hasDeletedObject;
}


- (BOOL)deleteItemValue:(QredoVaultItemDescriptor *)vaultItemDescriptor error:(NSError **)returnError{
    __block BOOL hasDeletedObject = NO;
    __block NSError *blockError = nil;
    QredoLogDebug(@"Delete Item from Index");
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexVaultItemMetadata class] entityName]];
        NSPredicate *searchByItemId = [NSPredicate predicateWithFormat:@"descriptor.itemId == %@ && descriptor.sequenceId == %@  && descriptor.sequenceValue == %d ",
                                       vaultItemDescriptor.itemId.data,vaultItemDescriptor.sequenceId.data,vaultItemDescriptor.sequenceValue];
        fetchRequest.predicate = searchByItemId;
        NSError *error = nil;
        NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error) {
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexErrorUnknown userInfo:@{ NSLocalizedDescriptionKey : @"Failed to retrieve item to delete" }];
        }else if ([items count]==0) {
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexItemNotFound userInfo:@{ NSLocalizedDescriptionKey : @"Item not found in cache" }];
        }else{
            //delete the parent of the found item -
            QredoIndexVaultItemMetadata *itemMetadata = [items lastObject];
            QredoIndexVaultItem *vaultItem = itemMetadata.vaultItem;
            [self.managedObjectContext deleteObject:vaultItem.payload];
            vaultItem.hasValueValue=NO;
            vaultItem.payload.value=nil;
            vaultItem.payload=nil;
        }
        [self save];
        hasDeletedObject = YES;
    }];
    if (returnError) *returnError = blockError;
    return hasDeletedObject;
}



-(BOOL)hasValue:(QredoVaultItemDescriptor *)vaultItemDescriptor{
    QredoIndexVaultItemMetadata *qredoIndexVaultItemMetadata = [self getIndexVaultItemMetadataWith:vaultItemDescriptor error:nil];
    if (qredoIndexVaultItemMetadata && qredoIndexVaultItemMetadata.vaultItem.hasValueValue==YES)return YES;
    return NO;
}




-(QredoIndexVaultItemMetadata *)getIndexVaultItemMetadataWith:(QredoVaultItemDescriptor *)vaultItemDescriptor error:(NSError **)returnError{
    __block BOOL hasDeletedObject = NO;
    __block NSError *blockError = nil;
    __block QredoIndexVaultItemMetadata *returnValue = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexVaultItemMetadata class] entityName]];
        NSPredicate *searchByItemId = [NSPredicate predicateWithFormat:@"descriptor.itemId == %@ && descriptor.sequenceId == %@  && descriptor.sequenceValue == %d ",
                                       vaultItemDescriptor.itemId.data,vaultItemDescriptor.sequenceId.data,vaultItemDescriptor.sequenceValue];
        fetchRequest.predicate = searchByItemId;
        NSError *error = nil;
        NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error) {
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexErrorUnknown userInfo:@{ NSLocalizedDescriptionKey : @"Failed to retrieve item to delete" }];
        }else if ([items count]==0) {
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexItemNotFound userInfo:@{ NSLocalizedDescriptionKey : @"Item not found in cache" }];
        }else{
            //delete the parent of the found item -
           returnValue = [items lastObject];
        }
    }];
    if (returnError) *returnError = blockError;
    return returnValue;

}

- (void)dump:(NSString *)message {
    for (QredoIndexVaultItem *vaultItem in self.qredoIndexVault.vaultItems) {
        NSLog(@"%@ Coredata Item:%@    Sequence:%lld",message,  vaultItem.latest.descriptor.itemId, vaultItem.latest.descriptor.sequenceValueValue);
    }
}


#pragma mark -
#pragma mark Private Methods


- (void)dealloc {
    [self save];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [self.qredoVault removeVaultObserver:self];
}


- (void)addAppObservers {
    //Ensure coredata is saved on app resign/termination
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}


- (void)initializeCoreData {
    QredoLogDebug(@"Initialize Coredata datastore");
    self.qredoLocalIndexDataStore = [QredoLocalIndexDataStore sharedQredoLocalIndexDataStore];
    self.managedObjectContext = self.qredoLocalIndexDataStore.managedObjectContext;
    return;
}


- (QredoIndexVaultItem *)addNewVaultItem:(QredoVaultItemMetadata *)newMetadata {
    //There is nothing in coredata so add this new item
    QredoIndexVaultItem *newIndexVaultItem = [QredoIndexVaultItem create:newMetadata inManageObjectContext:self.managedObjectContext];
    newIndexVaultItem.metadataSizeValue = [self.cacheInvalidator summaryValueByteCountSizeEstimator:newMetadata.summaryValues];
    [self.cacheInvalidator updateAccessDate:newIndexVaultItem.latest];
    newIndexVaultItem.vault = self.qredoIndexVault;
    return newIndexVaultItem;
}


-(QredoIndexVaultItem *)getIndexVaultItemFor:(QredoVaultItemMetadata *)newMetadata{
    //primarily for testing
    __block QredoIndexVaultItem *indexedItem;
    QredoLogDebug(@"Get Vault Item from Index");
    [self.managedObjectContext performBlockAndWait:^{
        indexedItem = [QredoIndexVaultItem searchForIndexByItemIdWithDescriptor:newMetadata.descriptor
                                                                       inManageObjectContext:self.managedObjectContext];
    }];
    return indexedItem;
}


- (void)putItemWithMetadata:(QredoVaultItemMetadata *)newMetadata vaultItem:(QredoVaultItem *)vaultItem hasVaultItemValue:(BOOL)hasVaultItemValue {
    [self.managedObjectContext performBlockAndWait:^{
        QredoIndexVaultItem *indexedItem = [QredoIndexVaultItem searchForIndexByItemIdWithDescriptor:newMetadata.descriptor
                                                                               inManageObjectContext:self.managedObjectContext];
        QredoIndexVaultItemMetadata *latestIndexedMetadata = indexedItem.latest;
        
        
//        NSLog(@"LOOKING 1 *** %@",  newMetadata.descriptor.itemId);
//        NSLog(@"LOOKING 2 *** %lli",newMetadata.descriptor.sequenceValue);
//        NSLog(@"LOOKING 3 *** %@",  newMetadata.descriptor.sequenceId);
//
//        NSLog(@"LOOKING 4 *** %@",  latestIndexedMetadata.descriptor.itemId);
//        NSLog(@"LOOKING 5 *** %@",  latestIndexedMetadata.descriptor.sequenceValue);
//        NSLog(@"LOOKING 6 *** %@",  latestIndexedMetadata.descriptor.sequenceId);

        
        
        //A new Vault Item
        if (!indexedItem) {
            QredoIndexVaultItem *vaultIndexItem = [self addNewVaultItem:newMetadata];
            [vaultIndexItem setVaultValue:vaultItem.value hasVaultItemValue:hasVaultItemValue];
            [self.cacheInvalidator addSizeToTotals:vaultIndexItem];
            [self save];
            QredoLogDebug(@"Add new item to index");
            QredoLogDebug(@"Index item count : %i", ^{ return [self count];}());
            return;
        }
        
        //this is an existing item set the value
        if ([latestIndexedMetadata hasSameSequenceIdAs:newMetadata]  &&
            [latestIndexedMetadata hasSameSequenceNumberAs:newMetadata]){
            QredoLogDebug(@"Existing item");
            //check if we need to update the payload
            if (indexedItem.hasValueValue==NO){
                [indexedItem setVaultValue:vaultItem.value hasVaultItemValue:YES];
                [self.cacheInvalidator addSizeToTotals:indexedItem];
                QredoLogDebug(@"Existing item without value, value set to data len %lu", (unsigned long)[vaultItem.value length]);
                [self save];
           }
            return;
        }
        
        
        //There is already a version in the index with same sequence ID and previous sequence Number
        if ([latestIndexedMetadata hasSameSequenceIdAs:newMetadata] && [latestIndexedMetadata hasSmallerSequenceNumberThan:newMetadata]) {
            [self.cacheInvalidator subtractSizeFromTotals:indexedItem];
            [indexedItem addNewVersion:newMetadata];
            [indexedItem setVaultValue:vaultItem.value hasVaultItemValue:hasVaultItemValue];
            [self.cacheInvalidator addSizeToTotals:indexedItem];
            [self save];
            QredoLogDebug(@"update an existing item in the index");
            QredoLogDebug(@"Index item count : %i", ^{ return [self count];}());
            return;
        }
        
        //The new version comes from  a different SequenceID - and therefore another device
        //The only way to guess the newest one is to compare created Date stamps (which are set by the device, so not 100% reliable)
        if (![latestIndexedMetadata hasSameSequenceIdAs:newMetadata] && [latestIndexedMetadata hasCreatedTimeStampBefore:newMetadata]) {
            [self.cacheInvalidator subtractSizeFromTotals:indexedItem];
            [indexedItem addNewVersion:newMetadata];
            [self.cacheInvalidator updateAccessDate:indexedItem.latest];
            [indexedItem setVaultValue:vaultItem.value hasVaultItemValue:hasVaultItemValue];
            [self.cacheInvalidator addSizeToTotals:indexedItem];
            [self save];
            QredoLogDebug(@"Item in index has different sequence and more recent date");
            QredoLogDebug(@"Index item count : %i", ^{ return [self count];}());
            return;
            
        }
    }];
}


- (void)enumerateSearch:(NSPredicate *)predicate withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block
                                         completionHandler:(void (^)(NSError *error))completionHandler {
    if (predicate==nil) {
        NSString *message = @"Predicate can not be nil";
        NSError *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexErrorUnknown
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        if (completionHandler) completionHandler(error);
        return;
    }
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexSummaryValues class] entityName]];
        NSPredicate *restrictToCurrentVault = [NSPredicate predicateWithFormat:@"vaultMetadata.vaultItem.vault.vaultId = %@",
                                                    self.qredoIndexVault.vaultId];
        NSCompoundPredicate *searchPredicate= [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, restrictToCurrentVault]];
        fetchRequest.predicate = searchPredicate;
        [self enumerateQuery:fetchRequest block:block completionHandler:completionHandler];
    }];
}




- (void)save {
    QredoLogDebug(@"Index save to disk");
    [[QredoLocalIndexDataStore sharedQredoLocalIndexDataStore] saveContext:NO];
}


- (void)saveAndWait {
    QredoLogDebug(@"Index save to disk and wait");
    [[QredoLocalIndexDataStore sharedQredoLocalIndexDataStore] saveContext:YES];
}


- (long)persistentStoreFileSize{
    return [self.qredoLocalIndexDataStore persistentStoreFileSize];
}


- (void)enumerateQuery:(NSFetchRequest *)fetchRequest block:(void (^)(QredoVaultItemMetadata *, BOOL *))block completionHandler:(void (^)(NSError *))completionHandler {
    if (!fetchRequest) {
        NSString * message = @"Predicate can not be Nil";
        NSError *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexErrorUnknown
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        if (completionHandler) completionHandler(error);
        return;
    }
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    BOOL stop=NO;
    for (QredoIndexSummaryValues *summaryValue in results) {
        QredoIndexVaultItemMetadata *qredoIndexVaultItemMetadata = summaryValue.vaultMetadata;
        [self.cacheInvalidator updateAccessDate:qredoIndexVaultItemMetadata];
        QredoVaultItemMetadata *qredoVaultItemMetadata= [qredoIndexVaultItemMetadata buildQredoVaultItemMetadata];
        
        if (block) block(qredoVaultItemMetadata,&stop);
        if (stop) break;
    }
    if (completionHandler) completionHandler(error);
    QredoLogInfo(@"Enumerate index complete");
}



#pragma mark -
#pragma mark QredoVaultObserver Methods

- (void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata {
    QredoLogDebug(@"Cache/Index received incoming Vault item");
    if (!itemMetadata || !client) return;
    [self putMetadata:itemMetadata];

    if (incomingMetadatBlock) incomingMetadatBlock(itemMetadata);
}


- (void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error {

    //The index doesn't really care if the vault operation failed or not
}


#pragma mark -
#pragma mark App Notifications

- (void)appWillResignActive:(NSNotification*)note {
    [self saveAndWait];
}


- (void)appWillTerminate:(NSNotification*)note {
    //ensure a more graceful termination of the App
    [self saveAndWait];
    QredoLogDebug(@"App will resign notification to index");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}


@end
