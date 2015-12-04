#import "QredoIndexVaultItem.h"
#import "Qredo.h"
#import "QredoIndexVaultItemMetadata.h"
#import "QredoIndexVaultItemDescriptor.h"

@interface QredoIndexVaultItem ()

// Private interface goes here.

@end

@implementation QredoIndexVaultItem

+(QredoIndexVaultItem *)searchForIndexWithMetata:(QredoVaultItemMetadata *)metadata  inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId==%@",metadata.descriptor.itemId];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    return [results lastObject];
}


-(void)addVersion:(QredoVaultItemMetadata *)metadata{
    QredoIndexVaultItemMetadata *indexMetadata = [QredoIndexVaultItemMetadata createWithMetadata:metadata inManageObjectContext:self.managedObjectContext];

    long long latestSequenceValue = self.latest.descriptor.sequenceValueValue;
    long long newSequenceValue    = indexMetadata.descriptor.sequenceValueValue;

    if (newSequenceValue>latestSequenceValue){
        //replace this new version as the latest
        self.latest = indexMetadata;
    }
    
    [self addAllVersionsObject:indexMetadata];
    
}


+(QredoIndexVaultItem *)create:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    QredoIndexVaultItem *newVaultItem =  [[self class] insertInManagedObjectContext:managedObjectContext];
    newVaultItem.itemId = metadata.descriptor.itemId.data;
    [newVaultItem addVersion:metadata];
    return newVaultItem;
}

@end
