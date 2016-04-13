/*
 *  Copyright (c) 2011-2015 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "QredoIndexVault.h"
#import "QredoVault.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"

@interface QredoIndexVault ()

@end

@implementation QredoIndexVault

+(QredoIndexVault *)fetchOrCreateWith:(QredoVault *)vault inManageObjectContext:(NSManagedObjectContext *)managedObjectContext {
    __block QredoIndexVault *qredoIndexVault;
    [managedObjectContext performBlockAndWait:^{
        NSData *dataVaultId = vault.vaultId.data;
        qredoIndexVault = [QredoIndexVault searchForVaultIndexWithId:dataVaultId inManageObjectContext:managedObjectContext];
        if (!qredoIndexVault) {
            qredoIndexVault = [QredoIndexVault create:vault inManageObjectContext:managedObjectContext];
        }
    }];
    return qredoIndexVault;
}


#pragma mark
#pragma private methods


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
