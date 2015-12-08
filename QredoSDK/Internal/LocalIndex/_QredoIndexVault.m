// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVault.m instead.

#import "_QredoIndexVault.h"

const struct QredoIndexVaultAttributes QredoIndexVaultAttributes = {
	.highWaterMark = @"highWaterMark",
	.vaultId = @"vaultId",
};

const struct QredoIndexVaultRelationships QredoIndexVaultRelationships = {
	.vaultItems = @"vaultItems",
};

@implementation QredoIndexVaultID
@end

@implementation _QredoIndexVault

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexVault" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexVault";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexVault" inManagedObjectContext:moc_];
}

- (QredoIndexVaultID*)objectID {
	return (QredoIndexVaultID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic highWaterMark;

@dynamic vaultId;

@dynamic vaultItems;

- (NSMutableSet*)vaultItemsSet {
	[self willAccessValueForKey:@"vaultItems"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"vaultItems"];

	[self didAccessValueForKey:@"vaultItems"];
	return result;
}

@end

