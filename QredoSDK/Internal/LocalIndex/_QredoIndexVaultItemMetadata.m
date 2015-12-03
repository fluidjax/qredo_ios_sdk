// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QredoIndexVaultItemMetadata.m instead.

#import "_QredoIndexVaultItemMetadata.h"

const struct QredoIndexVaultItemMetadataAttributes QredoIndexVaultItemMetadataAttributes = {
	.dataType = @"dataType",
};

const struct QredoIndexVaultItemMetadataRelationships QredoIndexVaultItemMetadataRelationships = {
	.descriptor = @"descriptor",
	.summaryValues = @"summaryValues",
	.vaultItem = @"vaultItem",
};

@implementation QredoIndexVaultItemMetadataID
@end

@implementation _QredoIndexVaultItemMetadata

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QredoIndexVaultItemMetadata" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QredoIndexVaultItemMetadata";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QredoIndexVaultItemMetadata" inManagedObjectContext:moc_];
}

- (QredoIndexVaultItemMetadataID*)objectID {
	return (QredoIndexVaultItemMetadataID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic dataType;

@dynamic descriptor;

@dynamic summaryValues;

- (NSMutableSet*)summaryValuesSet {
	[self willAccessValueForKey:@"summaryValues"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"summaryValues"];

	[self didAccessValueForKey:@"summaryValues"];
	return result;
}

@dynamic vaultItem;

@end

