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
    

    NSLog(@"Model URL: %@", modelURL);
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
    NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
}



-(void)putItem:(QredoVaultItem *)vaultItem{
    
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
        
        NSLog(@"Cache Retrieved Sequence Number is %@ count=%i",qredoIndexVaultItemMetadata.descriptor.sequenceValue, (int)[results count]);
        retrievedMetadata = [qredoIndexVaultItemMetadata buildQredoVaultItemMetadata];
    }];
    return retrievedMetadata;
}



-(void)delete:(QredoVaultItemDescriptor *)vaultItemDescriptor{
    
}


-(NSArray*)find:(NSPredicate *)predicate{
    __block NSArray* returnArray = nil;
    [self.managedObjectContext performBlockAndWait:^{
//      
//        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
//        
//        
//        NSExpression *maxSequenceValueKeyPathExpression = [NSExpression expressionForKeyPath:@"descriptor.sequenceValue"];
//        NSExpression *maxSequenceValueExpression = [NSExpression expressionForFunction:@"max:" arguments:@[maxSequenceValueKeyPathExpression]];
//        
//        NSExpressionDescription *maxSequenceExpressionDescription = [[NSExpressionDescription alloc] init];
//        maxSequenceExpressionDescription.name = @"maxSequenceNumber";
//        maxSequenceExpressionDescription.expression = maxSequenceValueExpression;
//        maxSequenceExpressionDescription.expressionResultType = NSInteger64AttributeType;
//        fetchRequest.propertiesToFetch = @[maxSequenceExpressionDescription];
//        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"descriptor.itemId==%@",descriptor.itemId.data];
//        fetchRequest.fetchLimit = 1;
//        NSError *error = nil;
//        NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
//        
//        QredoIndexVaultItemMetadata *qredoIndexVaultItemMetadata = [results lastObject];
//        
//        NSLog(@"Cache Retrieved Sequence Number is %@ count=%i",qredoIndexVaultItemMetadata.descriptor.sequenceValue, (int)[results count]);
//        return [qredoIndexVaultItemMetadata buildQredoVaultItemMetadata];
//
//        
//        
//        
//        
//        
//        
//        returnArray = [QredoIndexVaultItemMetadata find:predicate
//                                  inManageObjectContext:self.managedObjectContext];
    }];
    return returnArray;
}


-(void)enumerateAllItems{
}


-(void)sync{
}


-(void)purge{
}


-(void)addListener{
}


-(void)removeListener{
    
}



@end
