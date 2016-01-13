//
//  QredoLocalIndexCacheInvalidation.m
//  QredoSDK
//
//  Created by Christopher Morris on 13/01/2016.
//
//

#import "QredoLocalIndexCacheInvalidation.h"
#import "QredoIndexVault.h"
#import "QredoVaultPrivate.h"
#import "QredoIndexVaultItemMetadata.h"
#import "QredoIndexVaultItem.h"
#import "QredoIndexVaultItemPayload.h"
#import "QredoLocalIndexDataStore.h"

@interface QredoLocalIndexCacheInvalidation ()
@property (strong) QredoIndexVault *qredoIndexVault;
@end


@implementation QredoLocalIndexCacheInvalidation


- (instancetype)initWithIndexVault:(QredoIndexVault *)qredoIndexVault maxCacheSize:(long long)maxCacheSize {
    self = [super init];
    if (self) {
        self.qredoIndexVault = qredoIndexVault;
        self.maxCacheSize = maxCacheSize;
    }
    return self;
}


- (void)invalidate {
    //Check if cache is too big, if so remove Vault Item values
    BOOL haveMoreItemsToDelete = YES;
    while(haveMoreItemsToDelete && [self overCacheSize]==YES ) {
        haveMoreItemsToDelete = [self deleteOldestItem];
    }
    [self checkForOverSizeCache];
}


- (void)checkForOverSizeCache {
    /* Display a warning if the cache size is too big, and cant be made smaller becasue there are no Vault Item Values left to remove
     This will occur when the index/cache is full of metadata.
     Deleting metadata will from the index will prevent metadata searches working correctly.  */
    QredoLocalIndexDataStore *persistentStore = [QredoLocalIndexDataStore sharedQredoLocalIndexDataStore];
    long fileSizeOnDisk = [persistentStore persistentStoreFileSize];
    if (fileSizeOnDisk > self.maxCacheSize) {
        NSLog(@"** Warning index/cache is beyond the maximum size, increase size or turn off metadata indexing");
    }
}


- (long long)totalCacheSize {
    //calculate how much data we are storing in the cache
    //we cant use the size of the file on the disk, as sqllite reclaims disk spcae in its own time (vacuum)
    long vaultItemCount = [self.qredoIndexVault.vaultItems count];
    long overhead = vaultItemCount * 20;
    long long totalCacheSize = self.qredoIndexVault.valueTotalSizeValue + self.qredoIndexVault.metadataTotalSizeValue + overhead;
    return totalCacheSize;
}


- (BOOL)overCacheSize {
    //determine if the
    if ([self totalCacheSize] > self.maxCacheSize) {
        return YES;
    }
    return NO;
}


- (BOOL)deleteOldestItem {
    __block BOOL haveMoreItemsToDelete = YES;
    NSManagedObjectContext * moc = self.qredoIndexVault.managedObjectContext;
    
    [moc performBlockAndWait:^{
        NSError *error = nil;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItem entityName]];
        NSPredicate *hasValuePredicate = [NSPredicate predicateWithFormat:@"hasValue==YES"];
        NSSortDescriptor *dateOrder = [NSSortDescriptor sortDescriptorWithKey:@"latest.lastAccessed" ascending:NO];
        
        fetchRequest.predicate = hasValuePredicate;
        fetchRequest.sortDescriptors = @[dateOrder];
        
        NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
        
        QredoIndexVaultItem *qredoIndexVaultItem = [results firstObject];
        if (qredoIndexVaultItem) {
            QredoIndexVaultItemPayload *payload = qredoIndexVaultItem.payload;
            qredoIndexVaultItem.payload = nil;
            qredoIndexVaultItem.hasValueValue=NO;
            [self subtractValueSizeFromTotals:qredoIndexVaultItem];
            if (payload) [moc deleteObject:payload];
        }
        if (results && [results count]<=1) haveMoreItemsToDelete=NO;
        
    }];
    
    return haveMoreItemsToDelete;
    
}


- (void)subtractValueSizeFromTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    long long originalTotalValueSize = self.qredoIndexVault.valueTotalSizeValue;
    long long vaultSizeIncrease = qredoIndexVaultItem.valueSizeValue;
    [self.qredoIndexVault setValueTotalSizeValue:originalTotalValueSize-vaultSizeIncrease];
}


- (void)subtractMetadataSizeFromTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    long long originalTotalMetadataSize = self.qredoIndexVault.metadataTotalSizeValue;
    long long metadataSizeIncrease = qredoIndexVaultItem.metadataSizeValue;
    [self.qredoIndexVault setMetadataTotalSizeValue:originalTotalMetadataSize-metadataSizeIncrease];
}


- (void)subtractSizeFromTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    [self subtractValueSizeFromTotals:qredoIndexVaultItem];
    [self subtractMetadataSizeFromTotals:qredoIndexVaultItem];
}


- (void)addSizeToTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    long long originalTotalValueSize = self.qredoIndexVault.valueTotalSizeValue;
    long long vaultSizeIncrease = qredoIndexVaultItem.valueSizeValue;
    [self.qredoIndexVault setValueTotalSizeValue:originalTotalValueSize+vaultSizeIncrease];
    
    long long originalTotalMetadataSize = self.qredoIndexVault.metadataTotalSizeValue;
    long long metadataSizeIncrease = qredoIndexVaultItem.metadataSizeValue;
    [self.qredoIndexVault setMetadataTotalSizeValue:originalTotalMetadataSize+metadataSizeIncrease];
    
    [self updateAccessDate:qredoIndexVaultItem.latest];
    [self invalidate];
}


- (void)updateAccessDate:(QredoIndexVaultItemMetadata *)indexVaultItemMetadata {
    NSDate *now = [NSDate date];
    indexVaultItemMetadata.lastAccessed = now;
}


@end
