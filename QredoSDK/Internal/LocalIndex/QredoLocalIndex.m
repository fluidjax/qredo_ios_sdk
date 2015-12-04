//
//  QredoLocalIndex.m
//  QredoSDK
//
//  Created by Christopher Morris on 02/12/2015.
//
//
#import "QredoLocalIndex.h"


#import "QredoIndexSummaryValues.h"
#import "QredoIndexVaultItem.h"
#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexVaultItemMetadata.h"

@import CoreData;


@interface QredoLocalIndex ()
@property (readwrite) NSManagedObjectContext *managedObjectContext;
@property NSManagedObjectContext *privateContext;

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



- (void)initializeCoreData{
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
   
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    //NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
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
    }];
}



-(QredoVaultItemMetadata *)get:(QredoVaultItemDescriptor *)vaultItemDescriptor{
    __block QredoVaultItemMetadata* retrievedMetadata = nil;
    [self.managedObjectContext performBlockAndWait:^{

        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItemMetadata entityName]];
        NSExpression *maxSequenceValueKeyPathExpression = [NSExpression expressionForKeyPath:@"descriptor.sequenceValue"];
        NSExpression *maxSequenceValueExpression = [NSExpression expressionForFunction:@"max:" arguments:@[maxSequenceValueKeyPathExpression]];
        
        NSExpressionDescription *maxSequenceExpressionDescription = [[NSExpressionDescription alloc] init];
        maxSequenceExpressionDescription.name = @"maxSequenceNumber";
        maxSequenceExpressionDescription.expression = maxSequenceValueExpression;
        maxSequenceExpressionDescription.expressionResultType = NSInteger64AttributeType;
        fetchRequest.propertiesToFetch = @[maxSequenceExpressionDescription];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"descriptor.itemId==%@",vaultItemDescriptor.itemId.data];
        fetchRequest.fetchLimit = 1;
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        QredoIndexVaultItemMetadata *qredoIndexVaultItemMetadata = [results lastObject];
        retrievedMetadata = [qredoIndexVaultItemMetadata buildQredoVaultItemMetadata];
    }];
    return retrievedMetadata;
}



-(void)delete:(QredoVaultItemDescriptor *)vaultItemDescriptor{
    
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
