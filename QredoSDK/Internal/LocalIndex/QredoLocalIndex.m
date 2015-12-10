//
//  QredoLocalIndex.m
//  QredoSDK
//
//  Created by Christopher Morris on 02/12/2015.
//
//
#import "QredoLocalIndexPrivate.h"
#import "QredoErrorCodes.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoIndexSummaryValues.h"
#import "QredoIndexVaultItem.h"
#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexVaultItemMetadata.h"
#import "QredoIndexVault.h"
#import "QredoVaultPrivate.h"
@import CoreData;


@interface QredoLocalIndex ()
@property (strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (strong) NSManagedObjectContext *privateContext;
@property (strong) QredoVault *qredoVault;
@property (strong) QredoIndexVault *qredoIndexVault;

@end


@implementation QredoLocalIndex


- (instancetype)initWithVault:(QredoVault*)vault{
    self = [super init];
    if (self) {
        self.qredoVault = vault;
//        [vault addVaultObserver:self];
        [self initializeCoreData];
        [self retrieveQredoIndexVault];
    }
    return self;
}



-(void)retrieveQredoIndexVault{
    //set the QredoVaultIndex
    [self.managedObjectContext performBlockAndWait:^{
        NSData *dataVaultId = self.qredoVault.vaultId.data;
        self.qredoIndexVault = [QredoIndexVault searchForVaultIndexWithId:dataVaultId inManageObjectContext:self.managedObjectContext];
        if (!self.qredoIndexVault){
            self.qredoIndexVault = [QredoIndexVault create:self.qredoVault inManageObjectContext:self.managedObjectContext];
        }
        [self save];
    }];
}


-(void)dealloc{
    [self save];
    [self.qredoVault removeVaultObserver:self];

}

- (void)initializeCoreData{
    QredoLocalIndexDataStore *lids = [QredoLocalIndexDataStore sharedQredoLocalIndexDataStore];
    self.managedObjectContext = lids.managedObjectContext;
    return;
}


-(NSInteger)count{
    __block NSInteger count =0;
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItemMetadata entityName]];
        
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"latest.vault.vaultId = %@", self.qredoIndexVault.vaultId];
        
        
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        count = [results count];
    }];
    return count;
    
}


-(void)dump:(NSString*)message{
    for (QredoIndexVaultItem *vaultItem in self.qredoIndexVault.vaultItems){
        NSLog(@"%@ Coredata Item:%@    Sequence:%lld",message,  vaultItem.latest.descriptor.itemId, vaultItem.latest.descriptor.sequenceValueValue);
    }
}


-(void)putItemWithMetadata:(QredoVaultItemMetadata *)newMetadata{
    [self putItemWithMetadata:newMetadata inManagedObjectContext:self.managedObjectContext];
}

-(void)putItemWithMetadata:(QredoVaultItemMetadata *)newMetadata inManagedObjectContext:(NSManagedObjectContext*)managedObjectContext{
    [managedObjectContext performBlockAndWait:^{
            QredoIndexVaultItem *indexedItem = [QredoIndexVaultItem searchForIndexByItemIdWithMetadata:newMetadata inManageObjectContext:self.managedObjectContext];
            QredoIndexVaultItemMetadata *latestIndexedMetadata = indexedItem.latest;
            if ([latestIndexedMetadata isSameVersion:newMetadata]){
                //the version is the same as the existing version in core data - do nothing
                return;
            }
            
            if (indexedItem){
                //an existing version exists in coredata, update with this potential new version
                [indexedItem addNewVersion:newMetadata];
                [latestIndexedMetadata isSameVersion:newMetadata];
            }else{
                QredoIndexVaultItem *newIndeVaultItem = [QredoIndexVaultItem create:newMetadata inManageObjectContext:self.managedObjectContext];
                newIndeVaultItem.vault = self.qredoIndexVault;
            }
        [self save];
    }];
}



-(QredoVaultItemMetadata *)get:(QredoVaultItemDescriptor *)vaultItemDescriptor{
    __block QredoVaultItemMetadata* retrievedMetadata = nil;
    [self.managedObjectContext performBlockAndWait:^{

        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItemMetadata entityName]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"descriptor.itemId==%@",vaultItemDescriptor.itemId.data];
        fetchRequest.fetchLimit = 1;
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        QredoIndexVaultItemMetadata *qredoIndexVaultItemMetadata = [results lastObject];
        retrievedMetadata = [qredoIndexVaultItemMetadata buildQredoVaultItemMetadata];
    }];
    return retrievedMetadata;
}



-(BOOL)deleteItem:(QredoVaultItemDescriptor *)vaultItemDescriptor{
     return [self deleteItem:vaultItemDescriptor error:nil];
}

-(BOOL)deleteItem:(QredoVaultItemDescriptor *)vaultItemDescriptor error:(NSError*)returnError{
    __block BOOL hasDeletedObject = NO;
    __block NSError *blockError = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexVaultItemMetadata class] entityName]];
        NSPredicate *searchByItemId = [NSPredicate predicateWithFormat:@"descriptor.itemId == %@", vaultItemDescriptor.itemId.data];
        fetchRequest.predicate = searchByItemId;
        NSError *error = nil;
        NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error){
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexErrorUnknown userInfo:@{ NSLocalizedDescriptionKey : @"Failed to retrieve item to delete" }];
        }else if ([items count]==0){
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexItemNotFound userInfo:@{ NSLocalizedDescriptionKey : @"Item not found in cache" }];
        }else{
            //delete the parent of the found item -
            QredoIndexVaultItemMetadata *itemMetadata = [items lastObject];
            QredoIndexVaultItem *vaultItem = itemMetadata.latest;
            
            [self.managedObjectContext deleteObject:vaultItem];
        }
        if ([self save])hasDeletedObject = YES;
    }];
    if (returnError)returnError = blockError;
    return hasDeletedObject;
}


- (void)enumerateSearch:(NSPredicate *)predicate withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler{
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexSummaryValues class] entityName]];
        
        NSPredicate *restrictToCurrentVault = [NSPredicate predicateWithFormat:@"vaultMetadata.latest.vault.vaultId = %@",self.qredoIndexVault.vaultId ];
        NSCompoundPredicate *searchPredicate;
        
        if (predicate==nil){
            searchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[restrictToCurrentVault]];
        }else{
            searchPredicate= [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, restrictToCurrentVault]];
        }
        
        fetchRequest.predicate = searchPredicate;
        [self enumerateQuery:fetchRequest block:block completionHandler:completionHandler];
    }];
    
}



//-(void)syncIndexWithCompletion:(void(^)(int syncCount, NSError *error))completion{
//    __block int count=0;
//   
//    [self.qredoVault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
//        count++;
//        [self putItemWithMetadata:vaultItemMetadata];
//    } completionHandler:^(NSError *error) {
//        completion(count, error);
//    }];
//}




-(void)syncIndexPagedWithCompletionWithHWM:(void(^)(int syncCount, NSError *error))completion{
    __block int count=0;
    __block QredoVaultHighWatermark *endOfPageHighWaterMark;
    
    [self.qredoVault enumerateVaultItemsPagedForSyncUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;
        //NSLog(@"Enumerated Seq & Seq %@ - %lld",vaultItemMetadata.descriptor.sequenceId,vaultItemMetadata.descriptor.sequenceValue );
        //NSLog(@"Enumerated HWM %@",self.qredoVault.highWatermark);
    } since:nil watermarkHandler:^(QredoVaultHighWatermark *watermark) {
        endOfPageHighWaterMark = watermark;
        NSLog(@"**** INCOMGIN HIGH WATER MARK - SAVE TO OBJECT MODEL ONLY %@",watermark);
    } completionHandler:^(NSError *error) {
        NSLog(@"Sync'd %i",count);
        completion(count, error);
    }];
}


-(void)syncIndexWith:(int)incomingGrandTotal completion:(void(^)(int syncCount, NSError *error))completion{
    __block int vaultItemCount =0;
    __block int grandTotal = incomingGrandTotal;
    
    [self syncIndexPagedWithCompletionWithHWM:^(int syncCount, NSError *error) {
        vaultItemCount = syncCount;
        grandTotal += syncCount;
        if (vaultItemCount>0){
            //maybe some more. recurse
            [self syncIndexWith:grandTotal completion:completion];
        }else{
            if (completion)completion(grandTotal, error);
        }
    }];
}
     

-(void)syncIndexWithCompletion:(void (^)(int syncCount, NSError *error))completion{
    [self syncIndexWith:0 completion:completion];
}







-(void)purge{
    [self.managedObjectContext performBlockAndWait:^{
        if (self.qredoIndexVault)[self.managedObjectContext deleteObject:self.qredoIndexVault];
        //rebuild the vault references after deleting the old version
        [self.qredoVault removeVaultObserver:self];
        [self.qredoVault resetWatermark];
        [self retrieveQredoIndexVault];
        [self.qredoVault addVaultObserver:self];
        [self save];
        
    }];
    
    
}

-(void)purgeAllVaults{
     [self.managedObjectContext performBlockAndWait:^{
         [self deleteAllObjects:@"QredoIndexVault"];
         
         [self.qredoVault removeVaultObserver:self];
         [self retrieveQredoIndexVault];
         [self.qredoVault resetWatermark];
         [self save];
         [self.qredoVault addVaultObserver:self];
     }];
    [self save];
}


- (void)deleteAllObjects: (NSString *) entityDescription  {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *managedObject in items) {
        [self.managedObjectContext deleteObject:managedObject];
    }
    [self save];
}





#pragma mark -
#pragma mark Private Methods

- (void)enumerateQuery:(NSFetchRequest *)fetchRequest block:(void (^)(QredoVaultItemMetadata *, BOOL *))block completionHandler:(void (^)(NSError *))completionHandler{
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    BOOL stop=NO;
    for (QredoIndexSummaryValues *summaryValue in results){
        QredoIndexVaultItemMetadata *qredoIndexVaultItemMetadata = summaryValue.vaultMetadata;
        QredoVaultItemMetadata *qredoVaultItemMetadata= [qredoIndexVaultItemMetadata buildQredoVaultItemMetadata];
        if (block)block(qredoVaultItemMetadata,&stop);
        if (stop)break;
    }
    if (completionHandler)completionHandler(error);
}


-(BOOL)save{
    return [[QredoLocalIndexDataStore sharedQredoLocalIndexDataStore] save];
}





#pragma mark
#pragma QredoVaultObserver Methods
-(void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata{
    NSLog(@"Incoming Data: %@ - %lld",itemMetadata.descriptor.itemId.data,itemMetadata.descriptor.sequenceValue );
    [self putItemWithMetadata:itemMetadata inManagedObjectContext:self.managedObjectContext];
}


-(void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error{
    NSLog(@"Qredo Vault did fail with error %@",error);
}




@end
