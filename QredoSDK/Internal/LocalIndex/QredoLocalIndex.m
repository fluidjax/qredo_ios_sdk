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
#import "QredoErrorCodes.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoIndexSummaryValues.h"
#import "QredoIndexVaultItem.h"
#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexVaultItemMetadata.h"
#import "QredoIndexVault.h"
#import "QredoVaultPrivate.h"


@interface QredoLocalIndex ()
@property (strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (strong) QredoVault *qredoVault;
@property (strong) QredoIndexVault *qredoIndexVault;

@end


@implementation QredoLocalIndex

IncomingMetadataBlock incomingMetadatBlock;

#pragma mark -
#pragma mark Private Methods


- (instancetype)initWithVault:(QredoVault *)vault{
    self = [super init];
    if (self) {
        self.qredoVault = vault;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [self.qredoVault removeVaultObserver:self];
}


- (void)initializeCoreData{
    QredoLocalIndexDataStore *lids = [QredoLocalIndexDataStore sharedQredoLocalIndexDataStore];
    self.managedObjectContext = lids.managedObjectContext;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    return;
}


-(int)count{
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


-(void)dump:(NSString *)message{
    for (QredoIndexVaultItem *vaultItem in self.qredoIndexVault.vaultItems){
        NSLog(@"%@ Coredata Item:%@    Sequence:%lld",message,  vaultItem.latest.descriptor.itemId, vaultItem.latest.descriptor.sequenceValueValue);
    }
}


-(void)putItemWithMetadata:(QredoVaultItemMetadata *)newMetadata{
    [self putItemWithMetadata:newMetadata inManagedObjectContext:self.managedObjectContext];
}

-(void)putItemWithMetadata:(QredoVaultItemMetadata *)newMetadata inManagedObjectContext:(NSManagedObjectContext*)managedObjectContext{
    [self.managedObjectContext performBlockAndWait:^{
            QredoIndexVaultItem *indexedItem = [QredoIndexVaultItem searchForIndexByItemIdWithMetadata:newMetadata inManageObjectContext:self.managedObjectContext];
            QredoIndexVaultItemMetadata *latestIndexedMetadata = indexedItem.latest;
            if ([latestIndexedMetadata isSameVersion:newMetadata]){
                //the version is the same as the existing version in core data - do nothing
                return;
            }
            
            if (indexedItem){
                //this is a new version, substitue this one for the old one
                [indexedItem addNewVersion:newMetadata];
                [latestIndexedMetadata isSameVersion:newMetadata];
            }else{
                //Create a new item in the index
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
        [self save];
        hasDeletedObject = YES;
    }];
    if (returnError)returnError = blockError;
    return hasDeletedObject;
}


- (void)enumerateSearch:(NSPredicate *)predicate withBlock:(void (^)(QredoVaultItemMetadata *vaultMetaData, BOOL *stop))block completionHandler:(void(^)(NSError *error))completionHandler{
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[QredoIndexSummaryValues class] entityName]];
        
        NSPredicate *restrictToCurrentVault = [NSPredicate predicateWithFormat:@"vaultMetadata.latest.vault.vaultId = %@",self.qredoIndexVault.vaultId ];
        NSCompoundPredicate *searchPredicate= [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, restrictToCurrentVault]];
        fetchRequest.predicate = searchPredicate;
        [self enumerateQuery:fetchRequest block:block completionHandler:completionHandler];
    }];
}


-(void)enableSync{
    [self.qredoVault addVaultObserver:self];
}


-(void)enableSyncWithBlock:(IncomingMetadataBlock)block{
    incomingMetadatBlock = block;
    [self.qredoVault addVaultObserver:self];
}


-(void)purge{
    [self.managedObjectContext performBlockAndWait:^{
        QredoIndexVault *indexVaultToDelete = self.qredoIndexVault;
        self.qredoIndexVault = nil;
        if (indexVaultToDelete)[self.managedObjectContext deleteObject:indexVaultToDelete];
        //rebuild the vault references after deleting the old version
        [self retrieveQredoIndexVault];
        
        [self.qredoVault resetWatermark];
        [self saveAndWait];
    }];
}


- (void)enumerateQuery:(NSFetchRequest *)fetchRequest block:(void (^)(QredoVaultItemMetadata *, BOOL *))block completionHandler:(void (^)(NSError *))completionHandler{
    if (!fetchRequest){
        NSString * message = @"Predicate can not be NIL";
        NSError *error = [NSError errorWithDomain:QredoErrorDomain code:QredoErrorCodeIndexErrorUnknown
                                          userInfo:@{ NSLocalizedDescriptionKey : message }];
        if (completionHandler)completionHandler(error);
        return;
    }
    
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


-(void)save{
    [[QredoLocalIndexDataStore sharedQredoLocalIndexDataStore] saveContext:NO];
}


-(void)saveAndWait{
    [[QredoLocalIndexDataStore sharedQredoLocalIndexDataStore] saveContext:YES];
}


#pragma mark
#pragma QredoVaultObserver Methods

-(void)qredoVault:(QredoVault *)client didReceiveVaultItemMetadata:(QredoVaultItemMetadata *)itemMetadata{
    [self putItemWithMetadata:itemMetadata inManagedObjectContext:self.managedObjectContext];
    if (incomingMetadatBlock)incomingMetadatBlock(itemMetadata);
}


-(void)qredoVault:(QredoVault *)client didFailWithError:(NSError *)error{
    NSLog(@"Qredo Vault did fail with error %@",error);
}


#pragma mark
#pragma App Notifications

-(void)appWillResignActive:(NSNotification*)note{
    [self saveAndWait];
    
}
-(void)appWillTerminate:(NSNotification*)note{
    [self saveAndWait];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    
}


@end
