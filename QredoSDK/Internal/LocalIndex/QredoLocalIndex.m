//
//  QredoLocalIndex.m
//  QredoSDK
//
//  Created by Christopher Morris on 02/12/2015.
//  Manages the Coredata local Metadata index. There are no direct API public methods
//
@import CoreData;
@import UIKit;

#import "QredoLocalIndexPrivate.h"
#import "QredoVaultPrivate.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoIndexVault.h"
#import "QredoIndexVaultItem.h"
#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexVaultItemPayload.h"

@interface QredoLocalIndex ()
@property (strong) NSManagedObjectContext *managedObjectContext;
@property (strong) QredoVault *qredoVault;
@property (strong) QredoIndexVault *qredoIndexVault;
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
    }
    return self;
}


- (void)putMetadata:(QredoVaultItemMetadata *)newMetadata {
    if (self.enableMetadataCache==NO)return;
    [self putItemWithMetadata:newMetadata vaultItem:nil hasVaultItemValue:NO];
}


- (void)putVaultItem:(QredoVaultItem *)vaultItem {
    if (self.enableMetadataCache==NO)return; //no caching at all
    
    if (self.enableValueCache==NO){
        [self putMetadata:vaultItem.metadata];
    }else{
        [self putItemWithMetadata:vaultItem.metadata vaultItem:vaultItem hasVaultItemValue:YES];
    }
}


- (QredoVaultItem *)getVaultItemFromIndexWithDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor {
    __block QredoVaultItem* retrievedVaultItem = nil;
    [self.managedObjectContext performBlockAndWait:^{
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
    }];
    return retrievedVaultItem;
}


- (QredoVaultItemMetadata *)getMetadataFromIndexWithDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor {
    __block QredoVaultItemMetadata* retrievedMetadata = nil;
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItemMetadata entityName]];
        NSCompoundPredicate *searchPredicate;
        NSPredicate *itemIdPredicate = [NSPredicate predicateWithFormat:@"descriptor.itemId == %@",vaultItemDescriptor.itemId.data];
        NSPredicate *vaultIdPredicate = [NSPredicate predicateWithFormat:@"latest.vault.vaultId == %@",self.qredoIndexVault.vaultId];
        
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
    }];
    return retrievedMetadata;
}


- (int)count {
    __block NSInteger count =0;
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItemMetadata entityName]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"latest.vault.vaultId = %@", self.qredoIndexVault.vaultId];
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        count = [results count];
    }];
    return (int)count;
    
}


- (void)purge {
    [self.managedObjectContext performBlockAndWait:^{
        QredoIndexVault *indexVaultToDelete = self.qredoIndexVault;
        self.qredoIndexVault = nil;
        if (indexVaultToDelete) [self.managedObjectContext deleteObject:indexVaultToDelete];
        //rebuild the vault references after deleting the old version
        self.qredoIndexVault = [QredoIndexVault fetchOrCreateWith:self.qredoVault inManageObjectContext:self.managedObjectContext];
        
        [self.qredoVault resetWatermark];
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


- (BOOL)deleteItem:(QredoVaultItemDescriptor *)vaultItemDescriptor error:(NSError*)returnError {
    __block BOOL hasDeletedObject = NO;
    __block NSError *blockError = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexVaultItemMetadata class] entityName]];
        NSPredicate *searchByItemId = [NSPredicate predicateWithFormat:@"descriptor.itemId == %@", vaultItemDescriptor.itemId.data];
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
            QredoIndexVaultItem *vaultItem = itemMetadata.latest;
            [self.managedObjectContext deleteObject:vaultItem];
            vaultItem.hasValueValue=NO;
            vaultItem.payload.value=nil;
        }
        [self save];
        hasDeletedObject = YES;
    }];
    if (returnError) returnError = blockError;
    return hasDeletedObject;
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
    self.qredoLocalIndexDataStore = [QredoLocalIndexDataStore sharedQredoLocalIndexDataStore];
    self.managedObjectContext = self.qredoLocalIndexDataStore.managedObjectContext;
    return;
}


- (QredoIndexVaultItem *)addNewVaultItem:(QredoVaultItemMetadata *)newMetadata {
    //There is nothing in coredata so add this new item
    QredoIndexVaultItem *newIndeVaultItem = [QredoIndexVaultItem create:newMetadata inManageObjectContext:self.managedObjectContext];
    newIndeVaultItem.vault = self.qredoIndexVault;
    return newIndeVaultItem;
}


- (void)putItemWithMetadata:(QredoVaultItemMetadata *)newMetadata vaultItem:(QredoVaultItem *)vaultItem hasVaultItemValue:(BOOL)hasVaultItemValue {
    

    
    [self.managedObjectContext performBlockAndWait:^{
        QredoIndexVaultItem *indexedItem = [QredoIndexVaultItem searchForIndexByItemIdWithDescriptor:newMetadata.descriptor
                                                                               inManageObjectContext:self.managedObjectContext];
        QredoIndexVaultItemMetadata *latestIndexedMetadata = indexedItem.latest;
        
        //New item
        if (!indexedItem) {
            QredoIndexVaultItem *vaultIndexItem = [self addNewVaultItem:newMetadata];
            [vaultIndexItem setVaultValue:vaultItem.value hasVaultItemValue:hasVaultItemValue];
            [self save];
            return;
        }
        
        //There is already a version in the index with same sequence ID and previous sequence Number
        if ([latestIndexedMetadata hasSameSequenceIdAs:newMetadata] && [latestIndexedMetadata hasSmallerSequenceNumberThan:newMetadata]) {
            [indexedItem addNewVersion:newMetadata];
            [indexedItem setVaultValue:vaultItem.value hasVaultItemValue:hasVaultItemValue];
            [self save];
            return;
        }
        
        //The new version comes from  a different SequenceID - and therefore another device
        //The only way to guess the newest one is to compare created Date stamps (which are set by the device, so not 100% reliable)
        if (![latestIndexedMetadata hasSameSequenceIdAs:newMetadata] && [latestIndexedMetadata hasCreatedTimeStampBefore:newMetadata]) {
            [indexedItem addNewVersion:newMetadata];
            [indexedItem setVaultValue:vaultItem.value hasVaultItemValue:hasVaultItemValue];
            [self save];
            return;
        }
    }];
}


- (void)enumerateSearch:(NSPredicate *)predicate withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block completionHandler:(void (^)(NSError *error))completionHandler {
    if (predicate==nil) {
        NSString *message = @"Predicate can not be nil";
        NSError *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexErrorUnknown
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        if (completionHandler) completionHandler(error);
        return;
    }
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexSummaryValues class] entityName]];
        NSPredicate *restrictToCurrentVault = [NSPredicate predicateWithFormat:@"vaultMetadata.latest.vault.vaultId = %@",self.qredoIndexVault.vaultId ];
        NSCompoundPredicate *searchPredicate= [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, restrictToCurrentVault]];
        fetchRequest.predicate = searchPredicate;
        [self enumerateQuery:fetchRequest block:block completionHandler:completionHandler];
    }];
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
        QredoVaultItemMetadata *qredoVaultItemMetadata= [qredoIndexVaultItemMetadata buildQredoVaultItemMetadata];
        if (block) block(qredoVaultItemMetadata,&stop);
        if (stop) break;
    }
    if (completionHandler) completionHandler(error);
}


- (void)save {
    [[QredoLocalIndexDataStore sharedQredoLocalIndexDataStore] saveContext:NO];
}


- (void)saveAndWait {
    [[QredoLocalIndexDataStore sharedQredoLocalIndexDataStore] saveContext:YES];
}



- (long)persistentStoreFileSize{
    return [self.qredoLocalIndexDataStore persistentStoreFileSize];
}


#pragma mark -
#pragma mark QredoVaultObserver Methods

- (void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata {
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}


@end
