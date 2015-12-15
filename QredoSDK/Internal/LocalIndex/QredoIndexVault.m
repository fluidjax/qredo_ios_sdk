#import "QredoIndexVault.h"
#import "QredoVault.h"
#import "QredoQUID.h"

@interface QredoIndexVault ()

// Private interface goes here.

@end

@implementation QredoIndexVault


+(QredoIndexVault *)searchForVaultIndexWithId:(NSData *)vaultId inManageObjectContext:(NSManagedObjectContext *)managedObjectContext {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"vaultId==%@",vaultId];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setFetchLimit:1];
	NSError *error = nil;
	NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	return [results lastObject];
}


+(QredoIndexVault *)create:(QredoVault *)qredoVault inManageObjectContext:(NSManagedObjectContext *)managedObjectContext {
	QredoIndexVault *newIndexVault =  [[self class] insertInManagedObjectContext:managedObjectContext];
	newIndexVault.vaultId = qredoVault.vaultId.data;
	newIndexVault.highWaterMark = nil;
	return newIndexVault;
}


@end
