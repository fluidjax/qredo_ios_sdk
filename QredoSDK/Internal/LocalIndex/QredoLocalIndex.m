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

@import CoreData;


@interface QredoLocalIndex ()
//@property (readwrite) NSManagedObjectContext *managedObjectContext;
//@property NSManagedObjectContext *privateContext;
//@property NSPersistentStoreCoordinator *storeCoordinator;;

@property (strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (strong) NSManagedObjectContext *privateContext;


@end

@implementation QredoLocalIndex


+(id)sharedQredoLocalIndex {
    static QredoLocalIndex *sharedLocalIndex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocalIndex = [[self alloc] init];
        [sharedLocalIndex initializeCoreData];
    });
    return sharedLocalIndex;
}


- (void)initializeCoreData
{
    if ([self managedObjectContext]) return;
    
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"mom"];
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(mom, @"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSAssert(coordinator, @"Failed to initialize coordinator");
    
    [self setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType]];
    
    [self setPrivateContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
    [[self privateContext] setPersistentStoreCoordinator:coordinator];
    [[self managedObjectContext] setParentContext:[self privateContext]];
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
    
    return;
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


//- (void)initializeCoreData{
//    
//    if ([self managedObjectContext]) return;
//    
//    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
//    NSURL *modelURL = [bundle URLForResource:@"QredoLocalIndex" withExtension:@"mom"];
//    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
//    NSAssert(mom, @"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
//    
//    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
//    NSAssert(coordinator, @"Failed to initialize coordinator");
//    
//    [self setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType]];
//    
//    [self setPrivateContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
//    [[self privateContext] setPersistentStoreCoordinator:coordinator];
//    [[self managedObjectContext] setParentContext:[self privateContext]];
//    
//
//    NSPersistentStoreCoordinator *psc = [[self privateContext] persistentStoreCoordinator];
//    NSMutableDictionary *options = [NSMutableDictionary dictionary];
//    options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
//    options[NSInferMappingModelAutomaticallyOption] = @YES;
//    options[NSSQLitePragmasOption] = @{ @"journal_mode":@"DELETE" };
//    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//    NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"DataModel.sqlite"];
//    
//    
//    NSLog(@"Store URL %@", storeURL);
//    NSLog(@"ModelURL URL %@", modelURL);
//    
//    NSError *error = nil;
//    NSAssert([psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error], @"Error initializing PSC: %@\n%@", [error localizedDescription], [error userInfo]);
//
//    
//    self.storeCoordinator = psc;
//    
//
//}
//
//- (void)save{
//    if (![[self privateContext] hasChanges] && ![[self managedObjectContext] hasChanges]) return;
//    
//    [[self managedObjectContext] performBlockAndWait:^{
//        NSError *error = nil;
//        
//        NSAssert([[self managedObjectContext] save:&error], @"Failed to save main context: %@\n%@", [error localizedDescription], [error userInfo]);
//        
//        [[self privateContext] performBlock:^{
//            NSError *privateError = nil;
//            NSAssert([[self privateContext] save:&privateError], @"Error saving private context: %@\n%@", [privateError localizedDescription], [privateError userInfo]);
//        }];
//    }];
//}



-(NSInteger)count{
    __block NSInteger count =0;
    [self.managedObjectContext performBlockAndWait:^{
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItemMetadata entityName]];
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        count = [results count];
    }];
    return count;
    
}

-(void)putItemWithMetadata:(QredoVaultItemMetadata *)metadata{
    [self.managedObjectContext performBlockAndWait:^{
        //find any existing itemId in the Index
        QredoIndexVaultItem *indexedItem = [QredoIndexVaultItem searchForIndexWithMetata:metadata inManageObjectContext:self.managedObjectContext];
        if (indexedItem){
            [indexedItem addVersion:metadata];
        }else{
            [QredoIndexVaultItem create:metadata inManageObjectContext:self.managedObjectContext];
        }
        [self save];
    }];
}



-(QredoVaultItemMetadata *)get:(QredoVaultItemDescriptor *)vaultItemDescriptor{
    __block QredoVaultItemMetadata* retrievedMetadata = nil;
    [self.managedObjectContext performBlockAndWait:^{

        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItemMetadata entityName]];
        
        NSExpression *maxSequenceValueKeyPathExpression = [NSExpression expressionForKeyPath:@"descriptor.sequenceValue"];
        NSExpression *maxSequenceValueExpression = [NSExpression expressionForFunction:@"max:" arguments:@[maxSequenceValueKeyPathExpression]];
        
//        NSExpressionDescription *maxSequenceExpressionDescription = [[NSExpressionDescription alloc] init];
//        maxSequenceExpressionDescription.name = @"maxSequenceNumber";
//        maxSequenceExpressionDescription.expression = maxSequenceValueExpression;
//        maxSequenceExpressionDescription.expressionResultType = NSInteger64AttributeType;
//        fetchRequest.propertiesToFetch = @[maxSequenceExpressionDescription];
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
            QredoIndexVaultItem *vaultItem = itemMetadata.allVersions;
            
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
            //delete the item
            [self.managedObjectContext deleteObject:[items lastObject]];
        }
        
        if ([self save])hasDeletedObject = YES;
        
        
    }];
    
    if (returnError)returnError = blockError;
    

    return hasDeletedObject;
}


- (void)enumerateCurrentSearch:(NSPredicate *)predicate withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler{
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexSummaryValues class] entityName]];
        NSPredicate *restrictToLatest = [NSPredicate predicateWithFormat:@"vaultMetadata.latest != nil"];
        NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, restrictToLatest]];
        fetchRequest.predicate = compoundPredicate;
        [self enumerateQuery:fetchRequest block:block completionHandler:completionHandler];
    }];
    
}


- (void)enumerateSearch:(NSPredicate *)predicate withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler{
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexSummaryValues class] entityName]];
        fetchRequest.predicate = predicate;
        [self enumerateQuery:fetchRequest block:block completionHandler:completionHandler];
    }];
}



-(void)sync{
}


-(void)purge{
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexVaultItem class] entityName]];
        NSError *error = nil;
        NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error){
            NSLog(@"Coredata Error in Local Index - Failed to retrieve items");
        }else{
            for (QredoIndexVaultItem *indexVaultItem in items){
                [self.managedObjectContext deleteObject:indexVaultItem];
            }
        }
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

-(void)addListener{
}


-(void)removeListener{
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


@end
