/* HEADER GOES HERE */
#import "QredoLocalIndexCacheInvalidation.h"
#import "QredoVaultPrivate.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoLocalIndex.h"
#import "QredoIndexModel.h"
#import "QredoLoggerPrivate.h"
#import "QredoNetworkTime.h"

@interface QredoLocalIndexCacheInvalidation ()
@property (strong) QredoIndexVault *qredoIndexVault;
@property (strong) QredoLocalIndex *localIndex;
@end

/* Constants used to estimate the file size of the coredata index
 (The size of sqllite file on the disk can't be used as a measure of the quanitity of data stored. The datafile is auto vacuum, which means its size is not immediately
 changed when new records are put, or deleted. Therefore the quantity of datastore is estimated based on the size of the contents + some storage overheads, which are
 calulcated based on the constants below:
 */

static const long COREDATA_OVERHEAD_PER_VAULT_ITEM = 190;              //storage overhead for each vaultitem
static const float COREDATA_SUMMARY_VALUE_INDEX_MULTIPLIER = 2.0;      //storage overhead multipler for each metadata item - space used by indexes
static const float COREDATA_OVERHEAD_PER_SUMMARY_ITEM = 135;           //storage overgead for each metadata item
static const long COREDATA_BASE_SQLLITE_OVERHEAD = 143360;             //storage overhead for the sqllite version of the model without any data


#pragma mark
#pragma mark Public Methods


@implementation QredoLocalIndexCacheInvalidation


-(instancetype)initWithLocalIndex:(QredoLocalIndex *)localIndex maxCacheSize:(long long)maxCacheSize {
    self = [super init];
    
    if (self){
        _localIndex = localIndex;
        _qredoIndexVault = localIndex.qredoIndexVault;
        _maxCacheSize = maxCacheSize;
    }
    
    return self;
}

-(void)subtractSizeFromTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    [self subtractValueSizeFromTotals:qredoIndexVaultItem];
    [self subtractMetadataSizeFromTotals:qredoIndexVaultItem];
}

-(void)addSizeToTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    [self addValueSizeToTotals:qredoIndexVaultItem];
    [self addMetadataSizeToTotals:qredoIndexVaultItem];
    [self updateAccessDate:qredoIndexVaultItem.latest];
    [self invalidate];
}

-(void)updateAccessDate:(QredoIndexVaultItemMetadata *)indexVaultItemMetadata {
    NSDate *now = [QredoNetworkTime dateTime];
    
    indexVaultItemMetadata.lastAccessed = now;
}

-(long)summaryValueByteCountSizeEstimator:(NSDictionary *)summaryValue {
    //calculate the storage needed for the summaryValue dictionary
    long totalByteCount = 0;
    
    for (NSString *key in summaryValue){
        totalByteCount += [key length]; //add the number of bytes in the key
        long valueSize = [self sizeOfSummaryValue:[summaryValue objectForKey:key]]; //calc the number of bytes in the value
        totalByteCount += (float)valueSize * COREDATA_SUMMARY_VALUE_INDEX_MULTIPLIER;
        totalByteCount += COREDATA_OVERHEAD_PER_SUMMARY_ITEM;
    }
    
    return totalByteCount;
}

-(long long)totalCacheSizeEstimate {
    //calculate how much data we are storing in the cache
    //we cant use the size of the file on the disk, as sqllite reclaims disk spcae in its own time (vacuum)
    long vaultItemCount = [self.qredoIndexVault.vaultItems count];
    long overhead = (COREDATA_OVERHEAD_PER_VAULT_ITEM * vaultItemCount) + COREDATA_BASE_SQLLITE_OVERHEAD;
    long long totalCacheSize = self.qredoIndexVault.valueTotalSizeValue + self.qredoIndexVault.metadataTotalSizeValue + overhead;
    
    return totalCacheSize;
}

#pragma mark
#pragma mark Private Methods


-(void)addValueSizeToTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    long long originalTotalValueSize = self.qredoIndexVault.valueTotalSizeValue;
    long long vaultSizeIncrease = qredoIndexVaultItem.valueSizeValue;
    
    [self.qredoIndexVault setValueTotalSizeValue:originalTotalValueSize + vaultSizeIncrease];
}

-(void)addMetadataSizeToTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    long long originalTotalMetadataSize = self.qredoIndexVault.metadataTotalSizeValue;
    long long metadataSizeIncrease = qredoIndexVaultItem.metadataSizeValue;
    
    [self.qredoIndexVault setMetadataTotalSizeValue:originalTotalMetadataSize + metadataSizeIncrease];
}

-(long)sizeOfSummaryValue:(id)value {
    if ([value isKindOfClass:[NSString class]]){
        return [(NSString *)value length];
    } else if ([value isKindOfClass:[NSNumber class]]){
        return 8;
    } else if ([value isKindOfClass:[QredoQUID class]]){
        return 32;
    } else if ([value isKindOfClass:[NSDate class]]){
        return 8;
    }
    
    @throw [NSException exceptionWithName:@"Invalid Type" reason:@"Unknown type in summaryValues value" userInfo:nil];
}

-(void)invalidate {
    //Check if cache is too big, if so remove Vault Item values (not metadata) until there are either no more items to remove
    //or the cache size is under the maximum allowed size
    BOOL haveMoreItemsToDelete = YES;
    
    while (haveMoreItemsToDelete && [self overCacheSize] == YES)
        haveMoreItemsToDelete = [self deleteOldestItem];
    [self checkForOverSizeCache];
}

-(void)checkForOverSizeCache {
    /* Display a warning if the cache size is too big, and cant be made smaller becasue there are no Vault Item Values left to remove
     This will occur when the index/cache is full of metadata.
     Deleting metadata will from the index will prevent metadata searches working correctly.  */
    QredoLocalIndexDataStore *persistentStore = self.localIndex.qredoLocalIndexDataStore;
    long fileSizeOnDisk = [persistentStore persistentStoreFileSize];
    
    if (fileSizeOnDisk > self.maxCacheSize){
        QredoLogWarning(@"Index/cache is beyond the maximum size %@",^{
            return [NSString stringWithFormat:@"\n   CacheSize(Est):%lld \n   CacheSize(Act):%ld\n   MaxSize:       %lld",[self totalCacheSizeEstimate],fileSizeOnDisk,self.maxCacheSize];
        } ());
    }
}

-(BOOL)overCacheSize {
    //Make an estimate to see if we are using more cache space than the specified maximum cache size
    if ([self totalCacheSizeEstimate] > self.maxCacheSize){
        QredoLogInfo(@"Cache over Size");
        return YES;
    }
    
    return NO;
}

-(BOOL)deleteOldestItem {
    /** Get a list of QredoIndexVaultItems which has a payload  in lastAccessed order
     Delete the first item in the list (oldest)
     */
    
    __block BOOL haveMoreItemsToDelete = YES;
    NSManagedObjectContext *moc = self.qredoIndexVault.managedObjectContext;
    
    [moc performBlockAndWait:^{
        NSError *error = nil;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[QredoIndexVaultItem entityName]];
        NSPredicate *hasValuePredicate = [NSPredicate predicateWithFormat:@"hasValue==YES"];
        NSSortDescriptor *dateOrder = [NSSortDescriptor      sortDescriptorWithKey:@"latest.lastAccessed"
                                                                         ascending:NO];
        
        fetchRequest.predicate = hasValuePredicate;
        fetchRequest.sortDescriptors = @[dateOrder];
        
        NSArray *results = [moc      executeFetchRequest:fetchRequest
                                                   error:&error];
        
        QredoIndexVaultItem *qredoIndexVaultItem = [results firstObject];
        
        if (qredoIndexVaultItem){
            QredoIndexVaultItemPayload *payload = qredoIndexVaultItem.payload;
            qredoIndexVaultItem.payload = nil;
            qredoIndexVaultItem.hasValueValue = NO;
            [self subtractValueSizeFromTotals:qredoIndexVaultItem];
            
            if (payload) [moc deleteObject:payload];
            
            QredoLogInfo(@"Deleting oldest item in Index/cache");
        } else {
            QredoLogInfo(@"No more items in Index/cache to invalidate & delete");
        }
        
        if (results && [results count] <= 1) haveMoreItemsToDelete = NO;
    }];
    
    return haveMoreItemsToDelete;
}

-(void)subtractValueSizeFromTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    long long originalTotalValueSize = self.qredoIndexVault.valueTotalSizeValue;
    long long vaultSizeIncrease = qredoIndexVaultItem.valueSizeValue;
    
    [self.qredoIndexVault setValueTotalSizeValue:originalTotalValueSize - vaultSizeIncrease];
}

-(void)subtractMetadataSizeFromTotals:(QredoIndexVaultItem *)qredoIndexVaultItem {
    long long originalTotalMetadataSize = self.qredoIndexVault.metadataTotalSizeValue;
    long long metadataSizeIncrease = qredoIndexVaultItem.metadataSizeValue;
    
    [self.qredoIndexVault setMetadataTotalSizeValue:originalTotalMetadataSize - metadataSizeIncrease];
}

@end
