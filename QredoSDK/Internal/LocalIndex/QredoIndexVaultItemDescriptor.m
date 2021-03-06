/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexSummaryValues.h"
#import "Qredo.h"
#import "QredoVaultPrivate.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"


@interface QredoIndexVaultItemDescriptor ()
@end

@implementation QredoIndexVaultItemDescriptor


+(instancetype)createWithDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext {
    QredoIndexVaultItemDescriptor *qredoIndexVaultDescriptor = [[self class] insertInManagedObjectContext:managedObjectContext];
    
    qredoIndexVaultDescriptor.itemId            = [[descriptor.itemId data] copy];
    qredoIndexVaultDescriptor.sequenceId        = [[descriptor.sequenceId data] copy];
    
    QLFVaultSequenceValue sequenceValue = descriptor.sequenceValue;
    qredoIndexVaultDescriptor.sequenceValue = [NSNumber numberWithLongLong:sequenceValue];
    
    return qredoIndexVaultDescriptor;
}


+(instancetype)searchForDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId==%@ && sequenceId==%@",descriptor.itemId,descriptor.sequenceId];
    
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    return [results lastObject];
}


-(QredoVaultItemDescriptor *)buildQredoVaultItemDescriptor {
    QredoVaultItemDescriptor *qredoVaultItemDescriptor
    = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:[QredoQUID QUIDWithData:self.sequenceId]
                                                    sequenceValue:self.sequenceValueValue
                                                           itemId:[QredoQUID QUIDWithData:self.itemId]];
    
    return qredoVaultItemDescriptor;
}


@end
