#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexSummaryValues.h"
#import "Qredo.h"

@interface QredoIndexVaultItemDescriptor ()

// Private interface goes here.

@end

@implementation QredoIndexVaultItemDescriptor


+(instancetype)createWithDescriptor:(QredoVaultItemDescriptor*)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    QredoIndexVaultItemDescriptor *qredoIndexVaultDescriptor = [[self class] insertInManagedObjectContext:managedObjectContext];
    qredoIndexVaultDescriptor.itemId        = [descriptor.itemId data];
    qredoIndexVaultDescriptor.sequenceId    = [descriptor.sequenceId data];
    return qredoIndexVaultDescriptor;
}



+(instancetype)objectForDescriptor:(QredoVaultItemDescriptor*)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId==%@ && sequenceId==%@",descriptor.itemId,descriptor.sequenceId];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    return [results lastObject];
}




@end
