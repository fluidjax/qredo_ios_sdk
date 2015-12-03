#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexSummaryValues.h"
#import "Qredo.h"
#import "QredoVaultPrivate.h"
#import "QredoQUID.h"

@interface QredoIndexVaultItemDescriptor ()

// Private interface goes here.

@end

@implementation QredoIndexVaultItemDescriptor


+(instancetype)createWithDescriptor:(QredoVaultItemDescriptor*)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    QredoIndexVaultItemDescriptor *qredoIndexVaultDescriptor = [[self class] insertInManagedObjectContext:managedObjectContext];
    qredoIndexVaultDescriptor.itemId            = [descriptor.itemId data];
    qredoIndexVaultDescriptor.sequenceId        = [descriptor.sequenceId data];

    QLFVaultSequenceValue sequenceValue = descriptor.sequenceValue;
    qredoIndexVaultDescriptor.sequenceValue = [NSNumber numberWithLongLong:sequenceValue];
    
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


-(QredoVaultItemDescriptor *)buildQredoVaultItemDescriptor{
    
    return [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:[[QredoQUID alloc]initWithQUIDData:self.sequenceId]
                                                         sequenceValue:self.sequenceValueValue
                                                                itemId:[[QredoQUID alloc]initWithQUIDData:self.itemId]];
}



@end
