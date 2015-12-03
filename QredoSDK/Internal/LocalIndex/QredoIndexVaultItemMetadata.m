#import "QredoIndexVaultItemMetadata.h"
#import "Qredo.h"
#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexSummaryValues.h"



@interface QredoIndexVaultItemMetadata ()

// Private interface goes here.

@end

@implementation QredoIndexVaultItemMetadata


+(instancetype)createWithMetadata:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    QredoIndexVaultItemMetadata *qredoIndexMetadata = [[self class] insertInManagedObjectContext:managedObjectContext];
    QredoIndexVaultItemDescriptor *qredoIndexDescriptor = [QredoIndexVaultItemDescriptor createWithDescriptor:metadata.descriptor
                                                                                        inManageObjectContext:(NSManagedObjectContext *)managedObjectContext];
    qredoIndexMetadata.descriptor = qredoIndexDescriptor;
    
    
    
    [qredoIndexMetadata setSummaryValues:[QredoIndexSummaryValues
                                          createSetWith:metadata.summaryValues
                                                          inManageObjectContext:(NSManagedObjectContext *)managedObjectContext]];
    return qredoIndexMetadata;
    
}



+(instancetype)createOrUpdateWith:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    QredoIndexVaultItemMetadata *indexedVaultItemMetadata;
    
    QredoIndexVaultItemDescriptor *indexedVaultDescriptor =  [QredoIndexVaultItemDescriptor objectForDescriptor:metadata.descriptor
                                                                                          inManageObjectContext:managedObjectContext];

    if (indexedVaultDescriptor){
        indexedVaultItemMetadata = indexedVaultDescriptor.metataData;
    }else{
        [QredoIndexVaultItemMetadata createWithMetadata:metadata inManageObjectContext:managedObjectContext];
    }
    
    return indexedVaultItemMetadata;
    
}


@end
