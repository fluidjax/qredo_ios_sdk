#import "QredoIndexVaultItem.h"
#import "Qredo.h"
#import "QredoIndexVaultItemMetadata.h"
#import "QredoIndexVaultItemDescriptor.h"
#import "QredoVaultPrivate.h"

@interface QredoIndexVaultItem ()

// Private interface goes here.

@end

@implementation QredoIndexVaultItem

+(QredoIndexVaultItem *)searchForIndexByItemIdWithMetadata:(QredoVaultItemMetadata *)metadata  inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId==%@",metadata.descriptor.itemId.data];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    return [results lastObject];
}


-(void)addNewVersion:(QredoVaultItemMetadata *)metadata{
    long long currentSequenceValue = self.latest.descriptor.sequenceValueValue;
    long long newSequenceValue    = metadata.descriptor.sequenceValue;
    QredoIndexVaultItemMetadata *currentLatest = self.latest;
    if (newSequenceValue>currentSequenceValue){
        if (self.latest)[self.managedObjectContext deleteObject:self.latest];
        self.latest = [QredoIndexVaultItemMetadata createWithMetadata:metadata inManageObjectContext:self.managedObjectContext];
    }
}


+(QredoIndexVaultItem *)create:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    QredoIndexVaultItem *newVaultItem =  [[self class] insertInManagedObjectContext:managedObjectContext];
    newVaultItem.itemId = [metadata.descriptor.itemId.data copy];
    [newVaultItem addNewVersion:metadata];
    return newVaultItem;
}

@end
