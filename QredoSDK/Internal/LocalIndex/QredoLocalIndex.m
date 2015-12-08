//
//  QredoLocalIndex.m
//  QredoSDK
//
//  Created by Christopher Morris on 02/12/2015.
//
//
#import "QredoLocalIndex.h"
#import "QredoErrorCodes.h"

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


+(id)sharedQredoLocalIndexWithVault:(QredoVault*)vault{
    static QredoLocalIndex *sharedLocalIndex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocalIndex = [[self alloc] initWithVault:vault];

    });
    return sharedLocalIndex;
}


- (instancetype)initWithVault:(QredoVault*)vault{
    self = [super init];
    if (self) {
        self.qredoVault = vault;
        [vault addVaultObserver:self];
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


- (void)initializeCoreData{
    if (self.managedObjectContext) return;
    
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"mom"];
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(mom, @"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSAssert(coordinator, @"Failed to initialize coordinator");
    
    self.managedObjectContext=[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    
    [self setPrivateContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
    [[self privateContext] setPersistentStoreCoordinator:coordinator];
    [self.managedObjectContext setParentContext:[self privateContext]];
    NSPersistentStoreCoordinator *psc = [[self privateContext] persistentStoreCoordinator];
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
    options[NSInferMappingModelAutomaticallyOption] = @YES;
    options[NSSQLitePragmasOption] = @{ @"journal_mode":@"DELETE" };
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"DataModel.sqlite"];
    
    NSError *error = nil;
    NSAssert([psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error], @"Error initializing PSC: %@\n%@", [error localizedDescription], [error userInfo]);
    
    
    NSLog(@"Store URL %@",storeURL);
    NSLog(@"Model URL %@",modelURL);
    
    
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
            NSLog(@"Putting into core data %@ - %lld",newMetadata.descriptor.itemId, newMetadata.descriptor.sequenceValue);
            
            QredoIndexVaultItem *indexedItem = [QredoIndexVaultItem searchForIndexByItemIdWithMetadata:newMetadata inManageObjectContext:self.managedObjectContext];
            QredoIndexVaultItemMetadata *latestIndexedMetadata = indexedItem.latest;
            
            if ([latestIndexedMetadata isSameVersion:newMetadata]){
                NSLog(@"same version");
                return;
            }
            
            if (indexedItem){
                [indexedItem addNewVersion:newMetadata];
                [latestIndexedMetadata isSameVersion:newMetadata];
                NSLog(@"new version");
            }else{
                QredoIndexVaultItem *newIndeVaultItem = [QredoIndexVaultItem create:newMetadata inManageObjectContext:self.managedObjectContext];
                newIndeVaultItem.vault = self.qredoIndexVault;
                NSLog(@"New item is %@",newIndeVaultItem.latest.descriptor.itemId);
            }
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


-(BOOL)deleteVersion:(QredoVaultItemDescriptor *)vaultItemDescriptor{
    return [self deleteVersion:vaultItemDescriptor error:nil];
}

-(BOOL)deleteVersion:(QredoVaultItemDescriptor *)vaultItemDescriptor error:(NSError*)returnError{
     //deletes item using sequenceId in passed vaultDescriptor
    __block BOOL hasDeletedObject = NO;
    __block NSError *blockError = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexVaultItemMetadata class] entityName]];
        NSPredicate *searchBySequenceId = [NSPredicate predicateWithFormat:@"descriptor.sequenceId == %@", vaultItemDescriptor.sequenceId.data];
        fetchRequest.predicate = searchBySequenceId;
        NSError *error = nil;
        NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error){
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexErrorUnknown userInfo:@{ NSLocalizedDescriptionKey : @"Failed to retrieve item to delete" }];
        }else if ([items count]!=1){
            blockError = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexItemNotFound userInfo:@{ NSLocalizedDescriptionKey : @"Item not found in cache" }];
        }else{
            [self.managedObjectContext deleteObject:[items lastObject]];
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
        NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, restrictToCurrentVault]];
        fetchRequest.predicate = compoundPredicate;
        [self enumerateQuery:fetchRequest block:block completionHandler:completionHandler];
    }];
    
}



-(void)syncIndexWithCompletion:(void(^)(int syncCount, NSError *error))completion{
    __block int count=0;
    __block NSMutableArray *itemArray = [[NSMutableArray alloc] init];
    
    
    [self.qredoVault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        count++;

        NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        temporaryContext.parentContext = self.managedObjectContext;
        
          [self putItemWithMetadata:vaultItemMetadata inManagedObjectContext:temporaryContext];
        
        NSError *error;
        if (![temporaryContext save:&error])        {
            // handle error
        }
                                                                      
                                                                      
                                                                      
                                                                      
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [self putItemWithMetadata:vaultItemMetadata];
//            [self save];
        //});
    } completionHandler:^(NSError *error) {
        completion(count, error);
        dispatch_sync(dispatch_get_main_queue(), ^{
           [self dump:@"inside the sync"];
        });
    }];

}


-(void)syncIndexSince:(QredoVaultHighWatermark*)sinceWatermark withCompletion:(void(^)(NSError *error))completion{
    [self.qredoVault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
        [self putItemWithMetadata:vaultItemMetadata];
    } since:sinceWatermark completionHandler:^(NSError *error) {
        completion(error);
    }];
}


-(void)purge{
    [self.managedObjectContext performBlockAndWait:^{
        if (self.qredoIndexVault)[self.managedObjectContext deleteObject:self.qredoIndexVault];
        //rebuild the vault references after deleting the old version
        [self.qredoVault removeVaultObserver:self];
        [self retrieveQredoIndexVault];
        [self.qredoVault resetWatermark];
        [self save];
        [self.qredoVault addVaultObserver:self];
    }];
    
    
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


- (BOOL)save{
    __block BOOL success = NO;
    if (![[self privateContext] hasChanges] && ![[self managedObjectContext] hasChanges]) return YES;
    [[self managedObjectContext] performBlockAndWait:^{
        NSError *error = nil;
        NSAssert([[self managedObjectContext] save:&error], @"Failed to save main context: %@\n%@", [error localizedDescription], [error userInfo]);
        [[self privateContext] performBlock:^{
            NSError *privateError = nil;
            NSAssert([[self privateContext] save:&privateError], @"Error saving private context: %@\n%@", [privateError localizedDescription], [privateError userInfo]);
        }];
        if (error==nil)success=YES;
    }];
    return  success;
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
