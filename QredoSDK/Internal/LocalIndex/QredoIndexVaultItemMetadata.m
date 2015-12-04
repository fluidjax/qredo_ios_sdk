#import "QredoIndexVaultItemMetadata.h"
#import "Qredo.h"
#import "QredoIndexVaultItemDescriptor.h"
#import "QredoIndexSummaryValues.h"
#import "QredoVaultPrivate.h"


@interface QredoIndexVaultItemMetadata ()

// Private interface goes here.

@end

@implementation QredoIndexVaultItemMetadata



+(instancetype)createWithMetadata:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    QredoIndexVaultItemMetadata *qredoIndexMetadata = [[self class] insertInManagedObjectContext:managedObjectContext];
    QredoIndexVaultItemDescriptor *qredoIndexDescriptor = [QredoIndexVaultItemDescriptor createWithDescriptor:metadata.descriptor
                                                                                        inManageObjectContext:(NSManagedObjectContext *)managedObjectContext];
    qredoIndexMetadata.descriptor = qredoIndexDescriptor;
    qredoIndexMetadata.created    = metadata.created;
    qredoIndexMetadata.dataType   = metadata.dataType;
    qredoIndexMetadata.accessLevel= [NSNumber numberWithInteger:metadata.accessLevel];
 
    [qredoIndexMetadata createSummaryValues:metadata.summaryValues inManageObjectContext:managedObjectContext];
    
    return qredoIndexMetadata;
    
}


-(void)createSummaryValues:(NSDictionary *)summaryValues inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    for (NSObject *key in [summaryValues allKeys]){
        QredoIndexSummaryValues *qredoIndexSummaryValues = [QredoIndexSummaryValues createWithKey:key value:[summaryValues objectForKey:key]
                                                             inManageObjectContext:managedObjectContext];

        qredoIndexSummaryValues.vaultMetadata = self;
    }
    
}


     

+(instancetype)createOrUpdateWith:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    QredoIndexVaultItemMetadata *indexedVaultItemMetadata;
    
    QredoIndexVaultItemDescriptor *indexedVaultDescriptor =  [QredoIndexVaultItemDescriptor searchForDescriptor:metadata.descriptor
                                                                                          inManageObjectContext:managedObjectContext];

    if (indexedVaultDescriptor){
        //existing record found
        indexedVaultItemMetadata = indexedVaultDescriptor.metataData;
    }else{
        //create a new record
        [QredoIndexVaultItemMetadata createWithMetadata:metadata inManageObjectContext:managedObjectContext];
    }
    return indexedVaultItemMetadata;
}



-(QredoVaultItemMetadata *)buildQredoVaultItemMetadata{
    //constructs a new QredoItemMetadata from a cached QredoIndexItemMetadata, and all its sub objects
    return   [QredoVaultItemMetadata vaultItemMetadataWithDescriptor:[self.descriptor buildQredoVaultItemDescriptor]
                                                            dataType:self.dataType
                                                         accessLevel:self.accessLevelValue
                                                             created:self.created
                                                       summaryValues:[self buildSummaryDictionary]
                                         ];
}



-(NSDictionary*)buildSummaryDictionary{
    //loop through all the SummaryValues nsmanagedobjects and create a dictionary
    NSMutableDictionary *returnDictionary = [[NSMutableDictionary alloc] init];

    for (QredoIndexSummaryValues *qredoIndexSummaryValue in self.summaryValues){
        [returnDictionary setObject:[qredoIndexSummaryValue retrieveValue] forKey:qredoIndexSummaryValue.key];
    }
    NSLog(@"%@",returnDictionary);
    return returnDictionary;
    
}








@end
