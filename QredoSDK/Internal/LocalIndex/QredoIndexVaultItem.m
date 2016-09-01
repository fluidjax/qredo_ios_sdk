/* HEADER GOES HERE */
#import "QredoIndexVaultItem.h"
#import "Qredo.h"
#import "QredoIndexVaultItemMetadata.h"
#import "QredoIndexVaultItemDescriptor.h"
#import "QredoVaultPrivate.h"
#import "QredoIndexVaultItemPayload.h"

@interface QredoIndexVaultItem ()

// Private interface goes here.

@end

@implementation QredoIndexVaultItem


-(void)setVaultValue:(NSData *)data hasVaultItemValue:(BOOL)hasVaultItemValue{
    self.hasValueValue = hasVaultItemValue;
    self.valueSizeValue = [data length];
    if (hasVaultItemValue==YES){
        
        if (self.payload==nil){
            QredoIndexVaultItemPayload *payLoad = [QredoIndexVaultItemPayload insertInManagedObjectContext:self.managedObjectContext];
            self.payload = payLoad;
        }
        
        self.payload.value = [data copy];
    }else{
        self.payload.value = nil;
    }
}


-(QredoVaultItem *)buildQredoVaultItem{
    QredoIndexVaultItemMetadata *currentLatest = self.latest;
    QredoVaultItemMetadata *metadata = [currentLatest buildQredoVaultItemMetadata];
    QredoVaultItem *vaultItem = [QredoVaultItem vaultItemWithMetadata:metadata value:self.payload.value];
    vaultItem.metadata.origin = QredoVaultItemOriginCache;
    return vaultItem;
}


+(QredoIndexVaultItem *)searchForIndexByItemIdWithDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId==%@",descriptor.itemId.data];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setFetchLimit:1];
	NSError *error = nil;
	NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	return [results lastObject];
}


-(void)addNewVersion:(QredoVaultItemMetadata *)metadata {
	QredoIndexVaultItemMetadata *currentLatest = self.latest;
    NSDate *existingCreateDate = self.latest.created;
    self.latest = nil;
    if (currentLatest) [self.managedObjectContext deleteObject:currentLatest];
	self.latest = [QredoIndexVaultItemMetadata createWithMetadata:metadata inManageObjectContext:self.managedObjectContext];
    if (existingCreateDate)self.latest.created = existingCreateDate;
}


+(QredoIndexVaultItem *)create:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext {
	QredoIndexVaultItem *newVaultItem =  [[self class] insertInManagedObjectContext:managedObjectContext];
	newVaultItem.itemId = [metadata.descriptor.itemId.data copy];
	[newVaultItem addNewVersion:metadata];
	return newVaultItem;
}


@end
