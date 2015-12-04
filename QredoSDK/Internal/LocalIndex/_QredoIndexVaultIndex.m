// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultIndex.m instead.

#import "_QredoIndexVaultIndex.h"

const struct QredoIndexVaultIndexAttributes QredoIndexVaultIndexAttributes = {
	.vaultId = @"vaultId",
};

const struct QredoIndexVaultIndexRelationships QredoIndexVaultIndexRelationships = {
	.latest = @"latest",
	.previous = @"previous",
};

@implementation QredoIndexVaultIndexID
@end

@implementation _QredoIndexVaultIndex

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexVaultIndex" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexVaultIndex";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexVaultIndex" inManagedObjectContext:moc_];
}

- (QredoIndexVaultIndexID*)objectID {
	return (QredoIndexVaultIndexID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic vaultId;

@dynamic latest;

@dynamic previous;

- (NSMutableSet*)previousSet {
	[self willAccessValueForKey:@"previous"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"previous"];

	[self didAccessValueForKey:@"previous"];
	return result;
}

@end

